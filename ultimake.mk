#!/usr/bin/make -f
# Author: Peter Holzer
# Ultimake v1.33
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
# SOURCE_FILES ?= $(filter %.S,$(ALL_FILES)) $(filter %.c,$(ALL_FILES)) $(filter %.cpp,$(ALL_FILES))
SOURCE_FILES ?= $(filter %.S %.c %.cpp,$(ALL_FILES))

# Create lists of generated files ======================================
# TODO: $(notdir ... unterordner und so
# LIB := $(filter lib%.a,$(notdir TARGET)) $(filter lib%.so,$(notdir TARGET))
# ifndef LIB
#     BIN := $(TARGET)
# endif

# create list of dependency and object files from sources
# and handle folder prefix and file extension
DEP := $(patsubst %,$(OUT_DIR)/%.dep,$(SOURCE_FILES))
OBJ := $(patsubst %,$(OUT_DIR)/%.o,  $(SOURCE_FILES))


# Fancy colored progress printing ======================================
ifndef ULTIMAKE_NOCOLOR
    ifdef TERM
#         COLOR_BUILD := $(shell tput setaf 2)
#         COLOR_LINK  := $(shell tput setaf 1)$(shell tput bold)
#         COLOR_DEP   := $(shell tput setaf 5)$(shell tput bold)
#         COLOR_GEN   := $(shell tput setaf 4)$(shell tput bold)
#         COLOR_WARN  := $(shell tput setaf 1)
#         COLOR_NOTE  := $(shell tput setaf 3)
#         COLOR_ERR   := $(shell tput setaf 7)$(shell tput setab 1)$(shell tput bold)
#         COLOR_NONE  := $(shell tput sgr0)

        TERM_GREEN := $(shell tput setaf 2)
        TERM_RED   := $(shell tput setaf 1)$(shell tput bold)
        TERM_BLUE  := $(shell tput setaf 4)$(shell tput bold)
        TERM_PINK  := $(shell tput setaf 5)$(shell tput bold)
        TERM_NONE  := $(shell tput sgr0)
        TERM_CURSOR_UP := $(shell tput cuu1)

        GCC_COLOR_ERR := $(shell tput setaf 7)$(shell tput setab 1)$(shell tput bold)
        GCC_COLOR_WARN := $(shell tput setaf 1)
        GCC_COLOR_NOTE := $(shell tput setaf 3)

        GCC_COLOR :=  2>&1 1>/dev/null \
         | sed -r 's/(.*error:.*)/$(GCC_COLOR_ERR)\1$(TERM_NONE)/;\
                   s/(.*warning:)/$(GCC_COLOR_WARN)\1$(TERM_NONE)/;\
                   s/(.*note:)/$(GCC_COLOR_NOTE)\1$(TERM_NONE)/' >&2
    endif
endif

ifndef ULTIMAKE_NOPROGRESS
    PROGRESS := 0
    PROGRESS_FILE := $(OUT_DIR)/.ultimake-rebuild-count
    PROGRESS_MAX = $(shell cat $(PROGRESS_FILE))
    inc_progress  = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc))
    save_progress = @echo -n $(PROGRESS) > $(PROGRESS_FILE);
#     print_dep = @printf '$(TERM_CURSOR_UP)$(TERM_PINK)Scanning dependencies of target $(TARGET)$(TERM_NONE) [$(PROGRESS)/$(words $(OBJ))]\n';
    print_dep = @printf '\r$(TERM_PINK)Scanning dependencies of target $(TARGET)$(TERM_NONE) [$(PROGRESS)/$(words $(OBJ))]';

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50 (%)
    percentage = $(shell echo $(1)00/$(2) | bc)
    print_obj = @printf '[%3d%%] $(TERM_GREEN)$1$(TERM_NONE)\n' '$(call percentage,$(PROGRESS),$(PROGRESS_MAX))'
else
    print_dep = @printf '$(TERM_PINK)Scanning dependencies of target $(TARGET)$(TERM_NONE)\n'
    print_obj = @printf '$(TERM_GREEN)$1$(TERM_NONE)\n'
endif

make_dir = $(AT)-$(MKDIR) $(@D)


# Phony Targets ########################################################

.PHONY : all clean run clean-all

all : $(TARGET)

clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(TARGET) $(OBJ) $(DEP)

clean-all :
	@echo 'Cleaning, really ...'
	$(AT)-$(shell find $(OUT_DIR) -name "*.dep" -o -name "*.o" -delete)

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
define build_dep
	$(inc_progress)
	$(print_dep)
	$(save_progress)
endef


# generate dependency files from assembler source files
$(OUT_DIR)/%.S.dep : %.S
	$(make_dir)
	$(build_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.S=%.S.o)" $<

# generate dependency files from C source files
$(OUT_DIR)/%.c.dep : %.c
	$(make_dir)
	$(build_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.c=%.c.o)" $<

# generate dependency files from C++ source files
$(OUT_DIR)/%.cpp.dep : %.cpp
	$(make_dir)
	$(build_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.cpp=%.cpp.o)" $<

# Object files  ========================================================
# compile object files from assembler source files
$(OUT_DIR)/%.S.o : %.S $(OUT_DIR)/%.S.dep
	$(make_dir)
	$(inc_progress)
	$(call print_obj,Building ASM object $@)
	$(AT)$(COMPILE.S) $< -o $@ $(GCC_COLOR)

# compile object files from C source files
$(OUT_DIR)/%.c.o : %.c $(OUT_DIR)/%.c.dep
	$(make_dir)
	$(inc_progress)
	$(call print_obj,Building C object $@)
	$(AT)$(COMPILE.c) $< -o $@ $(GCC_COLOR)

# compile object files from C++ source files
$(OUT_DIR)/%.cpp.o : %.cpp $(OUT_DIR)/%.cpp.dep
	$(make_dir)
	$(inc_progress)
	$(call print_obj,Building C++ object $@)
	$(AT)$(COMPILE.cc) $< -o $@ $(GCC_COLOR)
# COMPILE.c  = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

# Assembler files ======================================================
# create assembler files from C source files
%.s : %.c
	@echo -e '$(TERM_BLUE)Creating $@$(TERM_NONE)'
	$(AT)$(CC) $(CPPFLAGS) $(CFLAGS) -C -S $< -o $@

# Linking ==============================================================
# link ALL object files into binary
$(filter-out %.a %.so,$(TARGET)) : $(OBJ)
	$(make_dir)
	@echo -e '$(TERM_RED)Linking CXX executable $@$(TERM_NONE)'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@  $(GCC_COLOR)

# create static library from ALL object files
$(filter %.a,$(TARGET)) : $(OBJ)
	$(make_dir)
	$(AT)$(RM) $@
	@echo -e '$(TERM_RED)Linking C/CXX static library $@$(TERM_NONE)'
	$(AT)$(AR) $(ARFLAGS) $@ $^

# create shared library from ALL object files
$(filter %.so,$(TARGET)) : $(OBJ)
	$(make_dir)
	@echo -e '$(TERM_RED)Linking C/CXX shared library $@$(TERM_NONE)'
	$(AT)$(CXX) -shared $(LDFLAGS) $(TARGET_ARCH) $^ -o $@

########################################################################
# include generated dependency files
# MAKECMDGOALS = invoked target
# in a less crazy language i would write "if MAKECMDGOALS!=clean && MAKECMDGOALS!=clean-all"
ifeq (,$(filter $(MAKECMDGOALS),clean clean-all))
    -include $(DEP)
endif


# $(info  )

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




