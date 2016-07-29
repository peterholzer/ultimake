#!/usr/bin/make -f
# Ultimake
# Author: Peter Holzer
# License: MIT



$(info )


#-----------------------------------------------------------------------
# Configuration
ifndef VERBOSE
    AT := @
endif

# remove default suffix rules
.SUFFIXES :

# preserve intermediate files
.SECONDARY :

# name of this makefile
ULTIMAKE.NAME := $(notdir $(lastword $(MAKEFILE_LIST)))

# path of this makefile
ULTIMAKE.PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

#-----------------------------------------------------------------------
# Default Directories

# default values for generated directories
OUT_DIR ?= debug


# default target
ifndef TARGETS
    $(info No TARGETS defined, compiling all sources in './' to './a.out')
#     $(info Creating default target a.out')
    TARGETS := a
    a := a.out
    a.SOURCES := ./
endif



#-----------------------------------------------------------------------
# TODO: Default Tools
AR    ?= ar
CC    ?= gcc
CXX   ?= g++
MKDIR ?= mkdir -p
RM    ?= rm -f
MV    ?= mv -f
# ARFLAGS ?= r

#-----------------------------------------------------------------------
# Create lists of existing files
# find all files in working directory
# should we exclude all files in OUT_DIR ?
# executes "find -type f" in several directories and cuts "./" prefix away
find_source = $(patsubst ./%,%,$(foreach dir,$(1), $(shell find -L $(dir) -iname "*.S"\
                                                                       -o -iname "*.c"\
                                                                       -o -iname "*.cpp")))


make_dir = $(AT)-$(MKDIR) $$(@D)

#-----------------------------------------------------------------------
define tool_list

$1.AR  ?= $$(AR)
$1.AS  ?= $$(AS)
$1.CC  ?= $$(CC)
$1.CXX ?= $$(CXX)
$1.ARFLAGS  ?= $$(ARFLAGS)
$1.ASFLAGS  ?= $$(ASFLAGS)
$1.CPPFLAGS ?= $$(CPPFLAGS)
$1.CFLAGS   ?= $$(CFLAGS)
$1.CXXFLAGS ?= $$(CXXFLAGS)
$1.LDFLAGS  ?= $$(LDFLAGS)
$1.TARGET_ARCH  ?= $$(TARGET_ARCH)
$1.SOURCES      ?= $$(SOURCES)
$1.SOURCE_FILES := $(call find_source,$($1.SOURCES))

endef
$(eval $(foreach target,$(TARGETS),$(call tool_list,$(target))))

#-----------------------------------------------------------------------
# Create lists of generated files
define file_list1

$1.DEP := $(patsubst %,$(OUT_DIR)/%.dep,$($1.SOURCE_FILES))
$1.OBJ := $(patsubst %,$(OUT_DIR)/%.o,  $($1.SOURCE_FILES))

endef
$(eval $(foreach target,$(TARGETS),$(call file_list1,$(target))))

#-----------------------------------------------------------------------
# filter Assembler/C/C++ objects and dependencies
define file_list2

$1.DEP_AS  := $(filter %.S.dep, $($1.DEP))
$1.DEP_C   := $(filter %.c.dep, $($1.DEP))
$1.DEP_CXX := $(filter %.cpp.dep, $($1.DEP))
$1.OBJ_AS  := $(filter %.S.o, $($1.OBJ))
$1.OBJ_C   := $(filter %.c.o, $($1.OBJ))
$1.OBJ_CXX := $(filter %.cpp.o, $($1.OBJ))

endef
$(eval $(foreach target,$(TARGETS),$(call file_list2,$(target))))


#-----------------------------------------------------------------------

ULTIMAKE.PREDEPENDENCY   = @printf '$(COLOR.DEP)Creating dependencies of target$(COLOR_NONE) $@ \n'
ULTIMAKE.POSTDEPENDENCY :=
ULTIMAKE.PRECOMPILE      = @printf '$(COLOR_BUILD)$1$(COLOR_NONE)\n'
ULTIMAKE.POSTCOMPILE    :=
ULTIMAKE.PRELINK         = @printf '$(COLOR_LINK)$1$(COLOR_NONE)\n'
ULTIMAKE.POSTLINK        = && printf 'Built target $@\n'

-include $(ULTIMAKE.PATH)/ultimake-fancy.mk

#-----------------------------------------------------------------------
.PHONY : all clean

all : $(foreach target,$(TARGETS), $($(target)))

clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(foreach target, $(TARGETS), $($(target)) $($(target).OBJ) $($(target).DEP))


#-----------------------------------------------------------------------
# create static library from object files
define static_lib
$($1) : $($1.OBJ)
	$(make_dir)
	$(AT)$(RM) $$@
	$(call ULTIMAKE.PRELINK,Linking C/CXX static library $$@)
	$(AT)$$($1.AR) $$($1.ARFLAGS) $$@ $$^ $$(ULTIMAKE.POSTLINK)
endef

# create shared library from object files
define shared_lib
$($1) : $($1.OBJ)
	$(make_dir)
	$(call ULTIMAKE.PRELINK,Linking C/CXX shared library $$@)
	$(AT)$$($1.CXX) -shared $$($1.TARGET_ARCH) $$^ $$($1.LDFLAGS) -o $$@ $$(ULTIMAKE.POSTLINK)
endef

# link object files into binary
define executable
$($1) : $($1.OBJ)
	$(make_dir)
	$(call ULTIMAKE.PRELINK,Linking CXX executable $$@)
	$(AT)$$($1.CXX)  $$($1.TARGET_ARCH) $$^ $$($1.LDFLAGS) -o $$@ $$(ULTIMAKE.POSTLINK)
endef


#-----------------------------------------------------------------------
define rules_macro


.PHONY : $1
$1 : $($1)

$(if $(filter %.a, $($1)),$(call static_lib,$1)
)$(if $(filter %.so,$($1)),$(call shared_lib,$1)
)$(if $(filter-out %.a %.so,$($1)),$(call executable,$1)
)$(if $($1.DEP_AS),
$($1.DEP_AS) : $$(OUT_DIR)/%.S.dep : %.S
	$(make_dir)
	$$(ULTIMAKE.PREDEPENDENCY)
	$(AT)$$($1.CC) $$(CPPFLAGS) -MF"$$@" -MG -MM -MP -MT"$$@" $$< $$(ULTIMAKE.POSTDEPENDENCY)
)$(if $($1.DEP_C),
$($1.DEP_C) : $$(OUT_DIR)/%.c.dep : %.c
	$(make_dir)
	$$(ULTIMAKE.PREDEPENDENCY)
	$(AT)$$($1.CC) $$(CPPFLAGS) -MF"$$@" -MG -MM -MP -MT"$$@" $$< $$(ULTIMAKE.POSTDEPENDENCY)
)$(if $($1.DEP_CXX),
$($1.DEP_CXX) : $$(OUT_DIR)/%.cpp.dep : %.cpp
	$(make_dir)
	$$(ULTIMAKE.PREDEPENDENCY)
	$(AT)$$($1.CXX) $$($1.CPPFLAGS) $$($1.CXXFLAGS) -MF"$$@" -MG -MM -MP -MT"$$@" $$< $(ULTIMAKE.POSTDEPENDENCY)
)$(if $($1.OBJ_AS),
$($1.OBJ_AS) : $$(OUT_DIR)/%.S.o : %.S $$(OUT_DIR)/%.S.dep
	$(make_dir)
	$$(call ULTIMAKE.PRECOMPILE,Building ASM object $$@)
	$(AT)$$($1.AS) $$($1.ASFLAGS) $$($1.CPPFLAGS) $$($1.TARGET_ARCH) -c $$< -o $$@ $$(ULTIMAKE.POSTCOMPILE)
)$(if $($1.OBJ_C),
$($1.OBJ_C) : $$(OUT_DIR)/%.c.o : %.c $$(OUT_DIR)/%.c.dep
	$(make_dir)
	$$(call ULTIMAKE.PRECOMPILE,Building C object $$@)
	$(AT)$$($1.CC) $$($1.CFLAGS) $$($1.CPPFLAGS) $$($1.TARGET_ARCH) -c $$< -o $$@ $$(ULTIMAKE.POSTCOMPILE)
)$(if $($1.OBJ_CXX),
$($1.OBJ_CXX) : $$(OUT_DIR)/%.cpp.o : %.cpp $$(OUT_DIR)/%.cpp.dep
	$(make_dir)
	$$(call ULTIMAKE.PRECOMPILE,Building C++ object $$@)
	$(AT)$$($1.CXX) $$($1.CXXFLAGS) $$($1.CPPFLAGS) $$($1.TARGET_ARCH) -c $$< -o $$@ $$(ULTIMAKE.POSTCOMPILE)
)
$(if $(filter clean,$(MAKECMDGOALS)),,-include $($1.DEP))

endef
$(eval $(foreach t,$(TARGETS),$(call rules_macro,$t)))

#-----------------------------------------------------------------------


$(shell mkdir -p $(OUT_DIR))
$(file > $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call tool_list,$(target))$(call rules_macro,$(target))))
# $(file > $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call tool_list,$(target))))
# $(file >> $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call rules_macro,$(target))))

# create assembler files from C source files
%.s : %.c
	@echo -e '$(COLOR_GEN)Creating $@$(COLOR_NONE)'
	$(AT)$(CC) $(CPPFLAGS) $(CFLAGS) -C -S $< -o $@
