#!/usr/bin/make -f
# Author: Peter Holzer
# Ultimake v2.01
# 2014-06-01

# TODO: create static libs directly in main-makefile with ultimake? see http://www.gnu.org/software/make/manual/make.html#Secondary-Expansion

# TODO:  CFLAGS := -.../x/y
# TODO:  CFLAGS := -isystem ../x/y keine Warnings für Systembibliotheken

# Recursive Make Considered Harmful, Peter Miller AUUGN 97
# http://aegis.sourceforge.net/auug97.pdf
# http://www.conifersystems.com/whitepapers/gnu-make/

# g++ test_obj.o --start-group -lA -lB --end-group -o test

$(info )
# $(info ULTIMAKE $(CURDIR))
# $(info ultimake (c) 2014 Peter Holzer)

ifdef ULTIMAKE_NAME
    $(error it seems you self-included ultimake.)
endif

# CC := sleep 0.$$RANDOM; gcc

# Configuration ========================================================
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

# default values for generated directories
OUT_DIR ?= debug


# Default Tools ========================================================
AR    ?= ar
CC    ?= gcc
CXX   ?= g++
MKDIR ?= mkdir -p -v
RM    ?= rm -f
MV    ?= mv -f
# ARFLAGS ?= r

# Default Target  ======================================================
# ifndef TARGET
#     TARGET := a.out
#     $(info TARGET not defined. Using default value $(TARGET))
# endif


# Default Directories ==================================================


# deprecated: default values for include file search directories
# (will automatically convert to "gcc -I<DIRECTORY>)
#ifdef INCLUDES
#    $(info )$(info INCLUDES is deprecated)
#    $(info alternative 1: CPPFLAGS += -I<include-path>)
#    $(info alternative 2: CPPFLAGS += $$(foreach inc,$$(INCLUDES),-I$$(inc)))
#    $(info )$(error )
#endif


# default values for source file search directories
ifndef SOURCES
    SOURCES := .
    $(info SOURCES not defined. Using default value $(SOURCES))
endif




# Create lists of existing files =======================================
# find all files in working directory
# should we exclude all files in OUT_DIR, OUT_DIR ?
# executes "find -type f" in several directories and cuts "./" prefix away
ALL_FILES := $(patsubst ./%,%,$(foreach dir,$(SOURCES), $(shell find -L $(dir) -type f)))

# filter Assembler/C/C++ sources
SOURCE_FILES ?= $(filter %.S %.c %.cpp,$(ALL_FILES))

find_source = $(patsubst ./%,%,$(foreach dir,$(1), $(shell find -L $(dir) -name "*.S" -o -name "*.c" -o -name "*.cpp")))
# vague_test_SOURCE_FILES := $(call find_source,$(vague_test_SOURCES))


# Create lists of generated files ======================================

# create list of dependency and object files from sources
# and handle folder prefix and file extension
# DEP := $(patsubst %,$(OUT_DIR)/%.dep,$(SOURCE_FILES))
# OBJ := $(patsubst %,$(OUT_DIR)/%.o,  $(SOURCE_FILES))


# Fancy colored progress printing ======================================
ifndef ULTIMAKE_NOCOLOR
    ifdef TERM
        COLOR_BUILD := $(shell tput setaf 2)
        COLOR_LINK  := $(shell tput setaf 1)$(shell tput bold)
        COLOR_DEP   := $(shell tput setaf 5)$(shell tput bold)
        COLOR_GEN   := $(shell tput setaf 4)$(shell tput bold)
        COLOR_WARN  := $(shell tput setaf 1)
        COLOR_NOTE  := $(shell tput setaf 3)
        COLOR_ERR   := $(shell tput setaf 7)$(shell tput setab 1)$(shell tput bold)
        COLOR_NONE  := $(shell tput sgr0)

        TERM_CURSOR_UP := $(shell tput cuu1)

        GCC_COLOR :=  2>&1 1>/dev/null \
         | sed -r 's/(.*error:.*)/$(COLOR_ERR)\1$(COLOR_NONE)/;\
                   s/(.*warning:)/$(COLOR_WARN)\1$(COLOR_NONE)/;\
                   s/(.*note:)/$(COLOR_NOTE)\1$(COLOR_NONE)/' >&2
    endif
endif

ifndef ULTIMAKE_NOPROGRESS
    PROGRESS := 0
    PROGRESS_FILE := $(OUT_DIR)/ultimake-rebuild-count
    PROGRESS_MAX = $(shell cat $(PROGRESS_FILE))
    inc_progress  = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc))
    save_progress = @echo -n $(PROGRESS) > $(PROGRESS_FILE);
    print_dep = @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)Scanning dependencies of target $(TARGET)$(COLOR_NONE) [$(PROGRESS)/$(words $(OBJ))]\n';
#     print_dep = @printf '\r$(COLOR_DEP)Scanning dependencies of target $(TARGET)$(COLOR_NONE) [$(PROGRESS)/$(words $(OBJ))]';

# calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50 (%)
    percentage = $(shell echo $(1)00/$(2) | bc)
#     percentage = $(shell echo $(1)00/$(2) | bc) | $(shell echo $(1)/$(2))
    print_obj = @printf '[%3s%%] $(COLOR_BUILD)$1$(COLOR_NONE)\n' '$(call percentage,$(PROGRESS),$(PROGRESS_MAX))'
else
    print_dep := @printf '$(COLOR_DEP)Scanning dependencies of target $(TARGET)$(COLOR_NONE)\n'
    print_obj = @printf '$(COLOR_BUILD)$1$(COLOR_NONE)\n'
endif

make_dir = $(AT)-$(MKDIR) $(@D)


# Phony Targets ########################################################

.PHONY : all clean run clean-all

all : $(TARGET)

clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(TARGET) $(OBJ) $(DEP)
	$(AT)-$(RM) $(foreach m,$(MODULES), $($m_TARGET) $($m_OBJ) $($m_DEP))
#
clean-all : clean
	@echo 'Cleaning, really ...'
	$(AT)-$(shell find $(OUT_DIR) -name "*.dep" -delete -o -name "*.o" -delete)

run : $(TARGET)
	./$(TARGET)

# Submake Feature ######################################################

LDFLAGS += $(foreach d,$(SUBMAKE_LIBS), -L$(dir $(d)))
LDFLAGS += $(foreach f,$(SUBMAKE_LIBS), -l$(patsubst lib%.a,%, $(notdir $(f))))

.PHONY : submake
$(TARGET) all clean : | submake
$(TARGET) : $(SUBMAKE_LIBS) | submake

submake :
	@for dir in $(SUBMAKE_DIRS); do       \
        $(MAKE) -C $$dir $(MAKECMDGOALS); \
    done

$(SUBMAKE_LIBS) : | submake

########################################################################




# Rules ################################################################

# Dependency files =====================================================
# generate dependency files from assembler source files







print_build = @printf '[%3s%%] $1\n' '$(call percentage,$(PROGRESS),$(PROGRESS_MAX))'

# 	$$(call print_obj,Building C object $$@)



#-----------------------------------------------------------------------
# create static library from ALL object files
define static_lib
$($1_TARGET) : $($1_OBJ)
	$$(make_dir)
	$(AT)$(RM) $$@
	@echo -e '$(COLOR_LINK)Linking C/CXX static library $$@$(COLOR_NONE)'
	$(AT)$($1_AR) $($1_ARFLAGS) $$@ $$^
	$$(call print_build,Built target $1)
endef


# create shared library from ALL object files
define shared_lib
$($1_TARGET) : $($1_OBJ)
	$$(make_dir)
	@echo -e '$(COLOR_LINK)Linking C/CXX shared library $$@$(COLOR_NONE)'
	$(AT)$$($1_CXX) -shared $$($1_LDFLAGS) $$($1_TARGET_ARCH) $$^ -o $$@
	$$(call print_build,Built target $1)
endef



# link ALL object files into binary
define executable
$($1_TARGET) : $($1_OBJ)
	$$(make_dir)
	@echo -e '$(COLOR_LINK)Linking CXX executable $$@$(COLOR_NONE)'
	$(AT)$($1_CXX) $($1_LDFLAGS) $($1_TARGET_ARCH) $$^ -o $$@  $(GCC_COLOR)
	$$(call print_build,Built target $1)
endef


#-----------------------------------------------------------------------
define file_lists

$1_AR  ?= $(AR)
$1_AS  ?= $(AS)
$1_CC  ?= $(CC)
$1_CXX ?= $(CXX)
$1_ARFLAGS  ?= $(ARFLAGS)
$1_CPPFLAGS ?= $(CPPFLAGS)
$1_CFLAGS   ?= $(CFLAGS)
$1_CXXFLAGS ?= $(CXXFLAGS)
$1_LDFLAGS  ?= $(LDFLAGS)
$1_TARGET_ARCH ?= $(TARGET_ARCH)
$1_SOURCE_FILES := $(call find_source,$($1_SOURCES))

endef
$(eval $(foreach module,$(MODULES),$(call file_lists,$(module))))


#-----------------------------------------------------------------------
define deps_objs
$1_DEP := $(patsubst %,$(OUT_DIR)/%.dep,$($1_SOURCE_FILES))
$1_OBJ := $(patsubst %,$(OUT_DIR)/%.o,  $($1_SOURCE_FILES))

endef
$(eval $(foreach module,$(MODULES),$(call deps_objs,$(module))))



#-----------------------------------------------------------------------
define rules_macro

$(filter %.S.o, $($1_OBJ)) : $(OUT_DIR)/%.S.o : %.S $(OUT_DIR)/%.S.dep
	$$(make_dir)
	$$(inc_progress)
	$$(call print_obj,Building ASM object $$@)
	$(AT)$($1_AS) $($1_ASFLAGS) $($1_CPPFLAGS) $($1_TARGET_ARCH) -c $$< -o $$@ $(GCC_COLOR)

$(filter %.c.o, $($1_OBJ)) : $(OUT_DIR)/%.c.o : %.c $(OUT_DIR)/%.c.dep
	$$(make_dir)
	$$(inc_progress)
	$$(call print_obj,Building C object $$@)
	$(AT)$($1_CC) $($1_CFLAGS) $($1_CPPFLAGS) $($1_TARGET_ARCH) -c $$< -o $$@ $(GCC_COLOR)

$(filter %.cpp.o, $($1_OBJ)) : $(OUT_DIR)/%.cpp.o : %.cpp $(OUT_DIR)/%.cpp.dep
	$$(make_dir)
	$$(inc_progress)
	$$(call print_obj,Building C++ object $$@)
	$(AT)$($1_CXX) $($1_CXXFLAGS) $($1_CPPFLAGS) $($1_TARGET_ARCH) -c $$< -o $$@ $(GCC_COLOR)

$(if $(filter %.a, $($1_TARGET)),$(call static_lib,$1))
$(if $(filter %.so,$($1_TARGET)),$(call shared_lib,$1))
$(if $(filter-out %.a %.so,$($1_TARGET)),$(call executable,$1))

ifeq (,$(filter $(MAKECMDGOALS),clean clean-all))
    -include $($1_DEP)
endif

endef

$(file > ultimake-static.mk,$(foreach module,$(MODULES),$(call file_lists,$(module))))
$(file >> ultimake-static.mk,$(foreach module,$(MODULES),$(call rules_macro,$(module))))

$(eval $(foreach module,$(MODULES),$(call rules_macro,$(module))))

# generate dependency files from C source files


$(OUT_DIR)/%.S.dep : %.S
	$(make_dir)
	$(inc_progress)
	$(print_dep)
	$(save_progress)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.S=%.S.o)" $<

$(OUT_DIR)/%.c.dep : %.c
	$(make_dir)
	$(inc_progress)
	$(print_dep)
	$(save_progress)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.c=%.c.o)" $<

$(OUT_DIR)/%.cpp.dep : %.cpp
	$(make_dir)
	$(inc_progress)
	$(print_dep)
	$(save_progress)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.cpp=%.cpp.o)" $<

# create assembler files from C source files
%.s : %.c
	@echo -e '$(COLOR_GEN)Creating $@$(COLOR_NONE)'
	$(AT)$(CC) $(CPPFLAGS) $(CFLAGS) -C -S $< -o $@


# include $(ULTIMAKE_PATH)/ultimake-help.mk
# include $(ULTIMAKE_PATH)/dot.mk
# include $(ULTIMAKE_PATH)/devtools.mk
# include $(ULTIMAKE_PATH)/gcc-warnings.mk

# TODO #################################################################
#
# TODO: for some reason, there is absolutely no leading "./" allowed,
#       otherwise the %-rules wont work
#       this makes half of the "-not" statements at the creation of the
#       FILES variable useless


# CHANGELOG ############################################################
#
# v2.00
#     - introduced MODULE system
# v1.31-v1.33
#     - replaced BIN and LIB completely with TARGET
#
# v1.30
#     - fixed percentage (missing comma in function call, v1.29, line 134)
#     - added sed command to colorize gcc output
#
# v1.29
#     - fixed unwanted rebuilding of dependencies when target 'clean' is called repeatedly,
#       found solition in GNU make manual 9.2 ;-)
#     - renamed DEBUG variable to VERBOSE
#
# v1.28
#     - introduced progress percentage
#     - replaced all XXX_SRC variables with SOURCE_FILES
#     - commented out submake-feature
#     - simplified "find" of source files
#
# v1.27
#
# v1.26
#     - removed vala support and put it in ultimake-vala.mk
#     - removed CPPFLAGS_INC. Additional include directories in INCLUDES are
#       now part of CPPFLAGS. Dependency generation now uses CPPFLAGS.
#     - changed self-include-check to watch out for ULTIMAKE_NAME instead
#       of ULTIMAKES_SELF_INCLUDE_STOP
#
# v1.25
#     - removed old crap (comments, ...)
#
#
# v1.24
#     - cleaned up
#     - OUT_DIR is now useless. Output path is set by DEP_DIR, OBJ_DIR, ... and TARGET
#
# v1.23
#     - ultimake now handles TARGET autmatically as static
#       library when it is named lib*.a
#   ( - removed precompiled headers )
#
# v1.22
#     - partially added precompiled headers
#
# v1.21
#     - added -L to find command to find symlinks
#
# v1.19
#     - deleted dead code
#
# v1.18
#     - reintroduced OUT_DIR
#
# v1.17
#
# v1.16
#
# v1.15
#     - refactored creation of file lists
#     - include order statement from v1.14 is wrong
#
# v1.14
#     - corrected include order. include statements are now after all
#       rules, because otherwise all included files will be built
#       BEFORE the target is executed
#     - removed target clean-all
#     - refactored help and tools target
#
# v1.13
#     - divided directories for object files and dependencies
#     - replaced OUT_DIR with DEP_DIR and OBJ_DIR
#     - new directories for vala-generated c files
#     - new default locations (hidden, start with dot)
#     - binaries and libs are no more tied to the object folder
#
# v1.12
#     - introduced FILES
#
# v1.10
#     - refactoring
#     - replaced make wildcards with shell find
#     - removed subdirs/modules
#
# v1.09
#     - added logging functionality
#




