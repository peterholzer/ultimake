#!/usr/bin/make -f
# Author: Peter Holzer
# Ultimake v1.26
# 2014-05-24

# TODO:  CFLAGS := -.../x/y
# TODO:  CFLAGS := -isystem ../x/y keine Warnings für Systembibliotheken


# 	$(shell echo blablabla)


# http://stackoverflow.com/questions/2738292/how-to-deal-with-recursive-dependencies-between-static-libraries-using-the-binut
# While @nos provides a simple solution, it doesn't scale when there are multiple libraries involved and the mutual dependencies are more complex. To sort out the problems ld provides --start-group archives --end-group.
# In your particular case:
# g++ test_obj.o --start-group -lA -lB --end-group -o test














$(info )
$(info invoking ULTIMAKE in $(CURDIR))


ifdef ULTIMAKE_NAME
    $(error it seems you self-included ultimake.)
endif



# CLR_GREEN := \033[1;32m
ifdef TERM
	CLR_GREEN := $(shell tput setaf 2)$(shell tput bold)
	CLR_NONE  := $(shell tput sgr0)
endif
# CLR_NONE  := \033[0m







# Configuration ========================================================
ifndef ULTIMAKE_DEBUG
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

# Default Target  ======================================================
ifndef TARGET
    TARGET := a.out
    $(info TARGET not defined. Using default value $(TARGET))
endif


# Default Directories ==================================================
# default values for include file search directories
# (will automatically convert to "gcc -I<DIRECTORY>)
ifndef INCLUDES
    INCLUDES := .
    $(info INCLUDES not defined. Using default value $(INCLUDES))
endif
CPPFLAGS += $(foreach include,$(INCLUDES),-I$(include))

# default values for source file search directories
ifndef SOURCES
    SOURCES := .
    $(info SOURCES not defined. Using default value $(SOURCES))
endif


# default values for generated directories
# OUT_DIR ?= debug
DEP_DIR ?= debug
OBJ_DIR ?= debug

# Default Tools ========================================================
AR    ?= ar
CC    ?= gcc
CXX   ?= g++
MKDIR ?= mkdir -p -v
MV    ?= mv -f
RM    ?= rm -f

# ARFLAGS ?= r
# CC  := clang
# CXX := clang++

# Functions ============================================================
# "find" executes "find -type f" in several directories and cuts "./" prefix away
# usage;
#     $(call find,$(1))
# $(1)  search directory(s)
find = $(patsubst ./%,%,$(foreach dir,$(1), $(shell find -L $(dir) -type f)))


# Create lists of existing files =======================================
# find all files in working directory
# should we exclude all files in DEP_DIR, OBJ_DIR ?
FILES := $(call find ,$(SOURCES))


# TODO: das hier in eine Zeile quetschen, evtl nur eine XXX_SRC variable
# filter Assembler/C/C++ sources
ASM_SRC ?= $(filter %.S,$(FILES))
C_SRC   ?= $(filter %.c,$(FILES))
CXX_SRC ?= $(filter %.cpp,$(FILES))

# Create lists of generated files ======================================
# TODO: $(notdir ... unterordner und so
LIB := $(filter lib%.a,$(TARGET))
ifndef LIB
	BIN := $(TARGET)
endif


# create list of dependency and object files from sources
# and handle folder prefix and file extension
DEP := $(patsubst %,$(DEP_DIR)/%.dep,$(ASM_SRC) $(C_SRC) $(CXX_SRC))
OBJ := $(patsubst %,$(OBJ_DIR)/%.o,  $(ASM_SRC) $(C_SRC) $(CXX_SRC))

PROGRESS_MAX = $(shell echo $(OBJ) | wc -w)
PROGRESS = 0

# Targets ##############################################################
.PHONY : bin clean lib run

all : $(BIN) $(LIB)

clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(BIN)
	$(AT)-$(RM) $(LIB)
	$(AT)-$(RM) $(OBJ)
	$(AT)-$(RM) $(DEP)

clean-all :
	@echo 'Cleaning, really ...'
	$(AT)-$(shell find $(DEP_DIR) -name "*.dep" -delete)
	$(AT)-$(shell find $(OBJ_DIR) -name "*.o" -delete)

run : $(BIN)
	./$(BIN)


# Rules ################################################################

do_progress = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc)) @echo '($(PROGRESS)/$(PROGRESS_MAX)) creating $@'
# make_dir = $(AT)-$(MKDIR) $(@D)
make_dir = $(AT)-$(MKDIR) $(@D)
# print_creating = @echo 'creating $@'
print_bar = @echo -n =

# Dependency files =====================================================
# generate dependency files from assembler source files
$(DEP_DIR)/%.S.dep : %.S
	$(make_dir)
	$(print_bar)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.S=%.S.o)" $<

# generate dependency files from C source files
$(DEP_DIR)/%.c.dep : %.c
	$(make_dir)
	$(print_bar)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.c=%.c.o)" $<

# generate dependency files from C source files
$(DEP_DIR)/%.cpp.dep : %.cpp
	$(make_dir)
	$(print_bar)
	$(AT)$(CC) $(CPPFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.cpp=%.cpp.o)" $<

# Object files  ========================================================
# compile object files from assembler source files
$(OBJ_DIR)/%.S.o : %.S $(DEP_DIR)/%.S.dep
	$(make_dir)
	$(do_progress)
	$(AT)$(COMPILE.S) $< -o $@

# compile object files from C source files
$(OBJ_DIR)/%.c.o : %.c $(DEP_DIR)/%.c.dep
	$(make_dir)
	$(do_progress)
	$(AT)$(COMPILE.c) $< -o $@

# compile object files from C++ source files
$(OBJ_DIR)/%.cpp.o : %.cpp $(DEP_DIR)/%.cpp.dep
	$(make_dir)
	$(do_progress)
	$(AT)$(COMPILE.cc) $< -o $@
# COMPILE.c  = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

# Assembler files ======================================================
# create assembler files from C source files
%.s : %.c
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS) $(CFLAGS) -C -S $< -o $@

# Linking ==============================================================
# link ALL object files into binary
$(BIN) : $(OBJ)
	$(make_dir)
	@echo -e '$(CLR_GREEN)linking $@$(CLR_NONE)'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@

# Archiving ============================================================
# create static library from ALL object files
$(LIB) : $(OBJ)
	$(make_dir)
	@echo 'removing $@'
	$(AT)$(RM) $@
	@echo -e '$(CLR_GREEN)creating $@$(CLR_NONE)'
# 	@echo 'creating $@'
	$(AT)$(AR) rs $@ $^
# 	$(AT)$(AR) $(ARFLAGS) $@ $^

########################################################################
# include generated dependency files
-include $(DEP)
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




