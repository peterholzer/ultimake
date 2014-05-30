#!/usr/bin/make -f
# Author: Peter Holzer
# Ultimake v1.30
# 2014-05-30

# TODO: create static libs directly in main-makefile with ultimake? see http://www.gnu.org/software/make/manual/make.html#Secondary-Expansion

# TODO:  CFLAGS := -.../x/y
# TODO:  CFLAGS := -isystem ../x/y keine Warnings für Systembibliotheken

# Recursive Make Considered Harmful, Peter Miller AUUGN 97
# http://aegis.sourceforge.net/auug97.pdf
# http://www.conifersystems.com/whitepapers/gnu-make/


# http://stackoverflow.com/questions/2738292/how-to-deal-with-recursive-dependencies-between-static-libraries-using-the-binut
# While @nos provides a simple solution, it doesn't scale when there are multiple libraries involved and the mutual dependencies
# are more complex. To sort out the problems ld provides --start-group archives --end-group.
# In your particular case:
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
ifndef TARGET
    TARGET := a.out
    $(info TARGET not defined. Using default value $(TARGET))
endif


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
SOURCE_FILES ?= $(filter %.S,$(ALL_FILES)) $(filter %.c,$(ALL_FILES)) $(filter %.cpp,$(ALL_FILES))

# Create lists of generated files ======================================
# TODO: $(notdir ... unterordner und so
LIB := $(filter lib%.a,$(TARGET))
ifndef LIB
	BIN := $(TARGET)
endif

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

#         SHELL := bash
#         GCC_COLOR := 2> >(sed -r 's///' >&2)
    endif
endif

ifndef ULTIMAKE_NOPROGRESS
    NUM_DEP_FILE=$(OUT_DIR)/.ultimake-rebuild-count
    NUM_DEP = 0
    NUM_OBJ = 0
    NUM_OBJ_ALL = $(shell cat $(NUM_DEP_FILE))
    count_dep = $(eval NUM_DEP := $(shell echo $(NUM_DEP)+1 | bc)) \
        @echo -n $(NUM_DEP) > $(NUM_DEP_FILE); \
        printf '$(TERM_CURSOR_UP)$(TERM_PINK)Scanning dependencies of target $(TARGET)$(TERM_NONE) [$(NUM_DEP)/$(words $(OBJ))]\n';
    #     @echo -n $(NUM_DEP) > $(NUM_DEP_FILE); printf '\r[$(NUM_DEP)/$(words $(OBJ))] $(TERM_PINK)Scanning dependencies$(TERM_NONE)';

    count_obj = $(eval NUM_OBJ := $(shell echo $(NUM_OBJ)+1 | bc))

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50 (%)
    percentage = $(shell echo $(1)00/$(2) | bc)
    print_obj = @printf '[%3d%%] $(TERM_GREEN)$1$(TERM_NONE)\n' '$(call percentage,$(NUM_OBJ),$(NUM_OBJ_ALL))'
else
    print_obj = @printf '$(TERM_GREEN)$1$(TERM_NONE)\n'
endif

make_dir = $(AT)-$(MKDIR) $(@D)


# Phony Targets ########################################################

.PHONY : clean run clean-all

all : $(BIN) $(LIB)

clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP)

clean-all :
	@echo 'Cleaning, really ...'
	$(AT)-$(shell find $(OUT_DIR) -name "*.dep" -o -name "*.o" -delete)

run : $(BIN)
	./$(BIN)

# 	@for dir in $(SUB_MAKES); do    \
# 		$(MAKE) -C $$dir $(MAKECMDGOALS);     \
# 	done

# $(BIN) $(LIB) : | submake
# .PHONY :  submake

# submake :
# 	@echo 'submake: Making $@'
# 	@for dir in $(SUB_MAKES); do    \
# 		$(MAKE) -C $$dir;       \
# 	done


# Submake ##############################################################

LDFLAGS += -L$(dir $(LIB_FILES))
LDFLAGS += -l$(patsubst lib%.a,%, $(notdir $(LIB_FILES)))

.PHONY : submake

$(BIN) $(LIB) all clean : | submake

submake :
	@for dir in $(SUB_MAKES); do          \
		$(MAKE) -C $$dir $(MAKECMDGOALS); \
	done

$(TARGET) : $(LIB_FILES) | submake

$(LIB_FILES) : submake






# Rules ################################################################


# Dependency files =====================================================
# generate dependency files from assembler source files
$(OUT_DIR)/%.S.dep : %.S
	$(make_dir)
	$(count_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.S=%.S.o)" $<

# generate dependency files from C source files
$(OUT_DIR)/%.c.dep : %.c
	$(make_dir)
	$(count_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.c=%.c.o)" $<

# generate dependency files from C++ source files
$(OUT_DIR)/%.cpp.dep : %.cpp
	$(make_dir)
	$(count_dep)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.cpp=%.cpp.o)" $<


# Object files  ========================================================
# compile object files from assembler source files
$(OUT_DIR)/%.S.o : %.S $(OUT_DIR)/%.S.dep
	$(make_dir)
	$(count_obj)
	$(call print_obj,Building ASM object $@)
	$(AT)$(COMPILE.S) $< -o $@ $(GCC_COLOR)

# compile object files from C source files
$(OUT_DIR)/%.c.o : %.c $(OUT_DIR)/%.c.dep
	$(make_dir)
	$(count_obj)
	$(call print_obj,Building C object $@)
	$(AT)$(COMPILE.c) $< -o $@ $(GCC_COLOR)

# compile object files from C++ source files
$(OUT_DIR)/%.cpp.o : %.cpp $(OUT_DIR)/%.cpp.dep
	$(make_dir)
	$(count_obj)
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
$(BIN) : $(OBJ)
	$(make_dir)
	@echo -e '$(TERM_RED)Linking CXX executable $@$(TERM_NONE)'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@  $(GCC_COLOR)

# Archiving ============================================================
# create static library from ALL object files
$(LIB) : $(OBJ)
	$(make_dir)
	$(AT)$(RM) $@
	@echo -e '$(TERM_RED)Linking C/CXX static library $@$(TERM_NONE)'
	$(AT)$(AR) rs $@ $^  $(GCC_COLOR)
# 	$(AT)$(AR) $(ARFLAGS) $@ $^

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

# TODO: create shared library from ALL object files
# $(LIB) : $(OBJ)
# 	$(AT)$(MKDIR) $(@D)
# 	@echo 'removing $@'
# 	$(AT)$(RM) $@
# 	@echo 'creating $@'
# 	$(AT) $(CXX) -shared $(LDFLAGS) $(TARGET_ARCH) $^ -o $@


# CHANGELOG ############################################################
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




