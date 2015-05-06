#!/bin/bash
#
# Copyright (C) 2015 Joe Maples (With much help from The SaberMod Project)
#
#Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Big thanks to Paul Beeler for pointing out
# that flags can be added to CC for more
# simplicity.

# First, let's define some common variables.

GRAPHTIE      := -fgraphitesgr[oB  \
		 -fgraphite-identity \
   		 -fopenmp
GRAPHITE_LOOP := -floop-interchange \
		 -floop-strip-mine \
		 -floop-block	\
		 -floop-parallelize-all \
		 -ftree-loop-linear 
ifdef CONFIG_TARGET_CPU_CORES
GRAPHITE_LOOP += -ftree-parallelize-loops=$(TARGET_CPU_CORES)
endif
ifeq ($(filter %5% %6%,$(CROSS_COMPILE)),)
GRAPHITE_LOOP += -floop-unroll-and-jam
endif
PTHREAD       := -pthread
O3_FLAGS      := -O3 \
   		 -Wno-error=array-bounds \
    		 -Wno-error=strict-overflow
FAST_MATH     := -ffast-math
LTO           := -flto
PIPE          := -pipe
DNDEBUG       := -DNDEBUG
ifdef CONFIG_TARGET_DEVICE_TUNING
TUNE_FLAGS    := -marm \
		 -mtune=$(CONFIG_TARGET_CPU) \
		 -mcpu=$(CONFIG_TARGET_CPU) \
		 -march=$(CONFIG_TARGET_ARCH) \
		 -mfloat-abi=$(CONFIG_TARGET_ABI) \
		 -mfpu=$(CONFIG_TARGET_FPU_SETTING) \
	         -mvectorize-with-neon-$(CONFIG_TARGET_NEON_CORES)
else
TUNE_FLAGS    := -marm
endif
ifdef CONFIG_L1_CACHE_SIZE
PARAMETERS    := --param l1-cache-size=$(CONFIG_L1_CACHE_SIZE) --param l1-cache-line-size=$(CONFIG_L1_CACHE_SIZE)
else
PARAMETERS    := 
endif
ifdef CONFIG_L2_CACHE_SIZE
PARAMETERS    += --param l2-cache-size=$(CONFIG_L2_CACHE_SIZE)
endif
MODULO_SCHED  := -fmodulo-sched \
		 -fmodulo-sched-allow-regmoves
EXTRA_LOOP    := -ftree-loop-distribution \
         	 -ftree-loop-if-convert \
 	         -ftree-loop-im \
        	 -ftree-loop-ivcanon \
		 -ftree-vectorize \
        	 -fprefetch-loop-arrays
STRICT_FLAGS  := -fstrict-aliasing \
           	 -Werror=strict-aliasing

# Next we'll set up some basic defconfig options.

ifdef CONFIG_GRAPHITE
  CC += $(GRAPHITE) $(GRAPHITE_LOOP)
endif
ifdef CONFIG_PIPE
  CC += $(PIPE)
endif
ifdef CONFIG_PTHREAD
  CC += $(PTHREAD)
endif
ifdef CONFIG_O3
  CC += $(O3_FLAGS)
endif
ifdef CONFIG_FAST_MATH
  CC += $(FAST_MATH)
endif
ifdef CONFIG_LTO
  LD += $(LTO)
endif
ifdef CONFIG_DNDEBUG
  CC += $(DNDEBUG)
endif
ifdef CONFIG_TUNE
  CC += $(TUNE_FLAGS)
endif
ifdef CONFIG_PARAMETERS
  CC += $(PARAMETERS)
endif 
ifdef CONFIG_MODULO_SCHED
  CC += $(MODULO_SCHED)
endif
ifdef CONFIG_EXTRA_LOOP
  CC += $(EXTRA_LOOP)
endif
ifdef CONFIG_STRICT_ALIASING
  CC += $(STRICT_FLAGS)
endif

# Now for some more complex ones...
  
ifdef CONFIG_MEMORY_OPTS
  CC += $(GRAPHITE) $(GRAPHITE_LOOP) $(PIPE) $(DNDEBUG) $(EXTRA_LOOP)
endif
ifdef CONFIG_CPU_OPTS
  CC += $(GRAPHITE) $(PIPE) $(DNDEBUG) $(PARAMETERS) $(PTHREAD) $(FAST_MATH) $(TUNE_FLAGS)
endif
ifdef CONFIG_SAFE_OPTS
  CC += $(GRAPHITE) $(GRAPHITE_LOOP) $(PIPE) $(EXTRA_LOOP) $(PARAMETERS) $(PTHREAD) $(O3_FLAGS) $(TUNE_FLAGS) $(MODULO_SCHED)
  LD += $(LTO) $(PIPE)
endif
ifdef CONFIG_BATTERY_OPTS
  CC += $(GRAPHITE) $(GRAPHITE_LOOP) $(DNDEBUG) $(EXTRA_LOOP) $(TUNE_FLAGS) $(PTHREAD)
endif
ifdef CONFIG_MAX_OPTS
  CC  += $(GRAPHITE) $(GRAPHITE_LOOP) $(PIPE) $(EXTRA_LOOP) $(PARAMETERS) $(PTHREAD) $(O3_FLAGS) $(TUNE_FLAGS) $(MODULO_SCHED) $(FAST_MATH) $(DNDEBUG) $(STRICT_FLAGS)
  CPP += $(GRAPHITE) $(GRAPHITE_LOOP) $(PIPE) $(EXTRA_LOOP) $(PARAMETERS) $(PTHREAD) $(O3_FLAGS) $(TUNE_FLAGS) $(MODULO_SCHED) $(FAST_MATH) $(DNDEBUG) $(STRICT_FLAGS)
  LD  += $(LTO) $(O3_FLAGS) $(DNDEBUG) $(TUNE_FLAGS) $(PIPE)
endif
ifdef CONFIG_ALL_AROUND_OPTS
  CC  += $(GRAPHITE) $(GRAPHITE_LOOP) $(PIPE) $(EXTRA_LOOP) $(PARAMETERS) $(PTHREAD) $(O3_FLAGS) $(TUNE_FLAGS) $(MODULO_SCHED) $(FAST_MATH) $(DNDEBUG)
  CPP += $(GRAPHITE) $(PIPE) $(PTHREAD) $(O3_FLAGS) $(TUNE_FLAGS) $(DNDEBUG)
  LD  += $(LTO) $(O3_FLAGS) $(DNDEBUG) $(TUNE_FLAGS) $(PIPE)
endif

