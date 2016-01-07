/* Copyright (c) 2012-2014, The Linux Foundation. All rights reserved.
 * Copyright (c) 2015 Francisco Franco
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/cpu.h>
#include <linux/cpufreq.h>
#include <linux/qpnp/qpnp-adc.h>
#include <linux/msm_thermal.h>
#include <linux/platform_device.h>
#include <linux/of.h>

/* Throttle CPU when reaches a certain tempertature*/
unsigned int temp_threshold = 44;
module_param(temp_threshold, int, 0644);

/* check every 0.5 seconds for the CPU temperature */
unsigned int temp_scan_interval = 500;
module_param(temp_scan_interval, int, 0644);

static struct thermal_info {
	uint32_t cpuinfo_max_freq;
	uint32_t limited_max_freq;
	unsigned int safe_diff;
	bool throttling;
	bool pending_change;
} info = {
	.cpuinfo_max_freq = LONG_MAX,
	.limited_max_freq = LONG_MAX,
	.safe_diff = 5,
	.throttling = false,
	.pending_change = false,
};

enum thermal_freqs {
	FREQ_HELL		= 652800,
	FREQ_VERY_HOT		= 960000,
	FREQ_HOT		= 1497600,
	FREQ_WARM		= 1728000,
};

enum threshold_levels {
	LEVEL_HELL		= 1 << 4,
	LEVEL_VERY_HOT		= 1 << 3,
	LEVEL_HOT		= 1 << 2,
};

struct qpnp_vadc_chip *vadc_dev;

enum qpnp_vadc_channels adc_chan;

static struct delayed_work check_temp_work;

unsigned short get_threshold(void)
{
	return temp_threshold;
}

static int msm_thermal_cpufreq_callback(struct notifier_block *nfb,
		unsigned long event, void *data)
{
	struct cpufreq_policy *policy = data;

	if (event != CPUFREQ_ADJUST && !info.pending_change)
		return 0;

	cpufreq_verify_within_limits(policy, policy->cpuinfo.min_freq,
		info.limited_max_freq);

	return 0;
}

static struct notifier_block msm_thermal_cpufreq_notifier = {
	.notifier_call = msm_thermal_cpufreq_callback,
};

static void limit_cpu_freqs(uint32_t max_freq)
{
	unsigned int cpu;

	if (info.limited_max_freq == max_freq)
		return;

	info.limited_max_freq = max_freq;

	info.pending_change = true;

	get_online_cpus();
	for_each_online_cpu(cpu)
	{
		cpufreq_update_policy(cpu);
		pr_info("%s: Setting cpu%d max frequency to %d\n",
				KBUILD_MODNAME, cpu, info.limited_max_freq);
	}
	put_online_cpus();

	info.pending_change = false;
}

static void check_temp(struct work_struct *work)
{
	struct qpnp_vadc_result result;
	uint32_t freq = 0;
	int64_t temp;

	qpnp_vadc_read(vadc_dev, adc_chan, &result);
	temp = result.physical;

	if (info.throttling)
	{
		if (temp < (temp_threshold - info.safe_diff))
		{
			limit_cpu_freqs(info.cpuinfo_max_freq);
			info.throttling = false;
			goto reschedule;
		}
	}

	if (temp >= temp_threshold + LEVEL_HELL)
		freq = FREQ_HELL;
	else if (temp >= temp_threshold + LEVEL_VERY_HOT)
		freq = FREQ_VERY_HOT;
	else if (temp >= temp_threshold + LEVEL_HOT)
		freq = FREQ_HOT;
	else if (temp > temp_threshold)
		freq = FREQ_WARM;

	if (freq)
	{
		limit_cpu_freqs(freq);

		if (!info.throttling)
			info.throttling = true;
	}

reschedule:
	schedule_delayed_work_on(0, &check_temp_work, msecs_to_jiffies(temp_scan_interval));
}

static int msm_thermal_dev_probe(struct platform_device *pdev)
{
	struct device_node *np = pdev->dev.of_node;
	int ret;

	vadc_dev = qpnp_get_vadc(&pdev->dev, "thermal");

	ret = of_property_read_u32(np, "qcom,adc-channel", &adc_chan);
	if (ret) {
		return ret;
	}

	cpufreq_register_notifier(&msm_thermal_cpufreq_notifier,
			CPUFREQ_POLICY_NOTIFIER);

	INIT_DELAYED_WORK(&check_temp_work, check_temp);
        schedule_delayed_work_on(0, &check_temp_work, 5);

	return ret;
}

static int msm_thermal_dev_remove(struct platform_device *pdev)
{
	cpufreq_unregister_notifier(&msm_thermal_cpufreq_notifier,
                        CPUFREQ_POLICY_NOTIFIER);
	return 0;
}

static struct of_device_id msm_thermal_match_table[] = {
	{.compatible = "qcom,msm-thermal-simple"},
	{},
};

static struct platform_driver msm_thermal_device_driver = {
	.probe = msm_thermal_dev_probe,
	.remove = msm_thermal_dev_remove,
	.driver = {
		.name = "msm-thermal-simple",
		.owner = THIS_MODULE,
		.of_match_table = msm_thermal_match_table,
	},
};

int __init  msm_thermal_device_init(void)
{
	return platform_driver_register(&msm_thermal_device_driver);
}

void __exit msm_thermal_device_exit(void)
{
	platform_driver_unregister(&msm_thermal_device_driver);
}

late_initcall(msm_thermal_device_init);
module_exit(msm_thermal_device_exit);
