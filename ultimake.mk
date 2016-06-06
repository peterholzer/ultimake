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
ULTIMAKE_NAME := $(notdir $(lastword $(MAKEFILE_LIST)))

# path of this makefile
ULTIMAKE_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

#-----------------------------------------------------------------------
# Default Directories

# default values for generated directories
OUT_DIR ?= debug

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
.PHONY : all clean

all : $(foreach t,$(TARGETS), $($t))

clean :
	@echo 'Cleaning ...'
# 	$(AT)-$(RM) $(TARGETS) $(OBJ) $(DEP)
	$(AT)-$(RM) $(foreach t,$(TARGETS), $($t) $($t_OBJ) $($t_DEP))



#-----------------------------------------------------------------------
define file_lists

$1.AR  ?= $(AR)
$1.AS  ?= $(AS)
$1.CC  ?= $(CC)
$1.CXX ?= $(CXX)
$1.ARFLAGS  ?= $(ARFLAGS)
$1.CPPFLAGS ?= $(CPPFLAGS)
$1.CFLAGS   ?= $(CFLAGS)
$1.CXXFLAGS ?= $(CXXFLAGS)
$1.LDFLAGS  ?= $(LDFLAGS)
$1.TARGET_ARCH ?= $(TARGET_ARCH)
$1.SOURCES ?= $(SOURCES)
$1_SOURCE_FILES := $(call find_source,$($1.SOURCES))

endef
$(eval $(foreach target,$(TARGETS),$(call file_lists,$(target))))

#-----------------------------------------------------------------------
# Create lists of generated files
define file_lists2

$1_DEP := $(patsubst %,$(OUT_DIR)/%.dep,$($1_SOURCE_FILES))

$1_OBJ := $(patsubst %,$(OUT_DIR)/%.o,  $($1_SOURCE_FILES))

endef
$(eval $(foreach target,$(TARGETS),$(call file_lists2,$(target))))

#-----------------------------------------------------------------------
# filter Assembler/C/C++ objects and dependencies
define file_lists3

$1_DEP_AS  := $(filter %.S.dep, $($1_DEP))
$1_DEP_C   := $(filter %.c.dep, $($1_DEP))
$1_DEP_CXX := $(filter %.cpp.dep, $($1_DEP))
$1_OBJ_AS  := $(filter %.S.o, $($1_OBJ))
$1_OBJ_C   := $(filter %.c.o, $($1_OBJ))
$1_OBJ_CXX := $(filter %.cpp.o, $($1_OBJ))

endef
$(eval $(foreach target,$(TARGETS),$(call file_lists3,$(target))))


#-----------------------------------------------------------------------

print_dep = @printf '$(COLOR_DEP)Scanning dependencies of target$(COLOR_NONE) $@ \n'
print_obj = @printf '$(COLOR_BUILD)$1$(COLOR_NONE)\n'
print_build = printf 'Built target $@\n'


-include $(ULTIMAKE_PATH)/ultimake-fancy.mk





#-----------------------------------------------------------------------
# create static library from object files
define static_lib
$($1) : $($1_OBJ)
	$(make_dir)
	$(AT)$(RM) $$@
	@echo -e '$$(COLOR_LINK)Linking C/CXX static library $$@$$(COLOR_NONE)'
	$(AT)$($1.AR) $($1.ARFLAGS) $$@ $$^ && $$(print_build)
endef

# create shared library from object files
define shared_lib
$($1) : $($1_OBJ)
	$(make_dir)
	@echo -e '$$(COLOR_LINK)Linking C/CXX shared library $$@$$(COLOR_NONE)'
	$(AT)$$($1.CXX) -shared $$($1.TARGET_ARCH) $$^ $$($1.LDFLAGS) -o $$@ $$(GCC_COLOR) && $$(print_build)
endef

# link object files into binary
define executable
$($1) : $($1_OBJ)
	$(make_dir)
	@echo -e '$$(COLOR_LINK)Linking CXX executable $$@$$(COLOR_NONE)'
	$(AT)$($1.CXX)  $($1.TARGET_ARCH) $$^ $$($1.LDFLAGS) -o $$@  $$(GCC_COLOR) && $$(print_build)
endef


#-----------------------------------------------------------------------
define rules_macro

.PHONY : $1
$1 : $($1)

$(if $($1_DEP_AS),
$($1_DEP_AS) : $(OUT_DIR)/%.S.dep : %.S
	$(make_dir)
	$$(print_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$$@" -MG -MM -MP -MT"$$@" -MT"$(OUT_DIR)/$(<:%.S=%.S.o)" $$<
)
$(if $($1_DEP_C),
$($1_DEP_C) : $(OUT_DIR)/%.c.dep : %.c
	$(make_dir)
	$$(print_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$$@" -MG -MM -MP -MT"$$@" -MT"$(OUT_DIR)/$(<:%.c=%.c.o)" $$<
)
$(if $($1_DEP_CXX),
$($1_DEP_CXX) : $(OUT_DIR)/%.cpp.dep : %.cpp
	$(make_dir)
	$$(print_dep)
	$(AT)$($1.CXX) $$($1.CPPFLAGS) $$($1.CXXFLAGS) -MF"$$@" -MG -MM -MP -MT"$$@" -MT"$(OUT_DIR)/$(<:%.cpp=%.cpp.o)" $$<
)


$(if $($1_OBJ_AS),
$($1_OBJ_AS) : $(OUT_DIR)/%.S.o : %.S $(OUT_DIR)/%.S.dep
	$(make_dir)
	$$(call print_obj,Building ASM object $$@)
	$(AT)$($1.AS) $($1.ASFLAGS) $($1.CPPFLAGS) $($1.TARGET_ARCH) -c $$< -o $$@ $(GCC_COLOR)
)
$(if $($1_OBJ_C),
$($1_OBJ_C) : $(OUT_DIR)/%.c.o : %.c $(OUT_DIR)/%.c.dep
	$(make_dir)
	$$(call print_obj,Building C object $$@)
	$(AT)$($1.CC) $($1.CFLAGS) $($1.CPPFLAGS) $($1.TARGET_ARCH) -c $$< -o $$@ $(GCC_COLOR)
)
$(if $($1_OBJ_CXX),
$($1_OBJ_CXX) : $(OUT_DIR)/%.cpp.o : %.cpp $(OUT_DIR)/%.cpp.dep
	$(make_dir)
	$$(call print_obj,Building C++ object $$@)
	$(AT)$($1.CXX) $($1.CXXFLAGS) $($1.CPPFLAGS) $($1.TARGET_ARCH) -c $$< -o $$@ $(GCC_COLOR)
)
$(if $(filter %.a, $($1)),$(call static_lib,$1))
$(if $(filter %.so,$($1)),$(call shared_lib,$1))
$(if $(filter-out %.a %.so,$($1)),$(call executable,$1))

ifeq (,$(filter $(MAKECMDGOALS),clean clean-all))
    -include $($1_DEP)
endif

endef
$(eval $(foreach target,$(TARGETS),$(call rules_macro,$(target))))

#-----------------------------------------------------------------------



$(shell mkdir -p $(OUT_DIR))
$(file > $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call file_lists,$(target))))
$(file >> $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call file_lists2,$(target))))
$(file >> $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call file_lists3,$(target))))
$(file >> $(OUT_DIR)/ultimake-static.mk,$(foreach target,$(TARGETS),$(call rules_macro,$(target))))


# create assembler files from C source files
%.s : %.c
	@echo -e '$(COLOR_GEN)Creating $@$(COLOR_NONE)'
	$(AT)$(CC) $(CPPFLAGS) $(CFLAGS) -C -S $< -o $@
