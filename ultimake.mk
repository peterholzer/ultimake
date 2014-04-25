#!/usr/bin/make -f
# Author: Peter Holzer
# Ultimake v1.21
# 06.01.2014

ifdef ULTIMAKES_SELF_INCLUDE_STOP
    $(error deprecated Target option BIN defined!)
endif
ULTIMAKES_SELF_INCLUDE_STOP = 1

# compatibility check
ifdef BIN
    $(error deprecated Target option BIN defined!)
endif
ifdef LIB
    $(error deprecated Target option LIB defined!)
endif

# Configuration ========================================================
# AT := @

# remove default suffix rules
.SUFFIXES :

# preserve intermediate files
.SECONDARY :

# name of this makefile
ULTIMAKE_NAME := $(notdir $(lastword $(MAKEFILE_LIST)))

# path of this makefile
ULTIMAKE_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

# Default Target  ======================================================
TARGET     ?= a.out

# Default Directories ==================================================
# default values for include file search directories
# (will automatically convert to "gcc -I<DIRECTORY>)
INCLUDES   ?= .
# default values for source file search directories
SOURCES    ?= .

# default values for generated directories
OUT_DIR    ?= debug
DEP_DIR    ?= .dep
OBJ_DIR    ?= .obj
VALA_C_DIR ?= .vala/c
VAPI_DIR   ?= .vala/vapi

# Default Tools ========================================================
AR    ?= ar
CC    ?= gcc
# CC	  := clang
CXX   ?= g++
# CXX   := clang++
VALAC ?= valac
# CP    ?= cp ...
MKDIR ?= mkdir -p -v
MV    ?= mv -f
RM    ?= rm -f

# Functions ============================================================
# "find" executes "find -type f" in several directories
# usage;
#     $(call find,$(1))
# $(1)  search directory(s)
find = $(foreach dir,$(1), $(shell find -L $(dir) -type f))

# Create lists of existing files =======================================
# find all files in working directory
# but exclude all files in DEP_DIR, OBJ_DIR, VAPI_DIR and VALA_C_DIR
FILES := $(call find ,$(SOURCES))

# cut "./" prefix away
FILES := $(patsubst ./%,%,$(FILES))

CPPFLAGS_INC := $(foreach include,$(INCLUDES),-I$(include))
CPPFLAGS     += $(CPPFLAGS_INC)

# filter C/C++/Vala sources
ASM_SRC  ?= $(filter %.S,$(FILES))
C_SRC    ?= $(filter %.c,$(FILES))
CXX_SRC  ?= $(filter %.cpp,$(FILES))
VALA_SRC ?= $(filter %.vala,$(FILES))

# Create lists of generated files ======================================
BIN := $(OUT_DIR)/$(TARGET)
LIB := $(OUT_DIR)/lib$(TARGET).a

# create list of vapi files from vala sources
VALA_VAPI  := $(VALA_SRC:%.vala=$(VAPI_DIR)/%.vapi)

# create list of vala-generated C source files from vala sources
# and add it to the list of C source files
VALA_C_SRC := $(VALA_SRC:%.vala=$(VALA_C_DIR)/%.c)
C_SRC      += $(VALA_C_SRC)

# create list of dependency and object files from sources
# and handle folder prefix and file extension
DEP := $(patsubst %,$(DEP_DIR)/%.dep,$(ASM_SRC) $(C_SRC) $(CXX_SRC))
OBJ := $(patsubst %,$(OBJ_DIR)/%.o,  $(ASM_SRC) $(C_SRC) $(CXX_SRC))

# Targets ##############################################################
.PHONY : all clean lib run

all : $(BIN)

lib : $(LIB)

clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(BIN)
	$(AT)-$(RM) $(LIB)
	$(AT)-$(RM) $(OBJ)
	$(AT)-$(RM) $(DEP)
	$(AT)-$(RM) $(VALA_VAPI) $(VALA_C_SRC)

run : $(BIN)
	./$(BIN)




# TODO #################################################################
# TEMP_DEPS := $(C_SRC:%.c=%.c.dep.tmp)

# %.c.dep.tmp: %.c
# 	$(CC) $(CPPFLAGS_INC) -no-canonical-prefixes -MF"$@" -MG -MM $<
# 	$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM $<

# graph.mk: $(TEMP_DEPS)
# 	-rm $@
# 	cat $(TEMP_DEPS) >> $@
# 	-rm  $(TEMP_DEPS)
# 	$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM -MP -MT"$@" $(C_SRC) $(CXX_SRC)
# END TODO #############################################################

# graph.dot : $(C_SRC)
# 	clang $(CPPFLAGS_INC) $^ -dependency-dot $@







# Rules ################################################################

# Dependency files =====================================================
# generate dependency files from assembler source files
$(DEP_DIR)/%.S.dep : %.S
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.S=%.S.o)" $<

# generate dependency files from C source files
$(DEP_DIR)/%.c.dep : %.c
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.c=%.c.o)" $<

# generate dependency files from C source files
$(DEP_DIR)/%.cpp.dep : %.cpp
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.cpp=%.cpp.o)" $<

# Object files  ========================================================
# compile object files from assembler source files
$(OBJ_DIR)/%.S.o : %.S $(DEP_DIR)/%.S.dep
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(COMPILE.S) $< -o $@

# compile object files from C source files
$(OBJ_DIR)/%.c.o : %.c $(DEP_DIR)/%.c.dep
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(COMPILE.c) $< -o $@

# compile object files from C++ source files
$(OBJ_DIR)/%.cpp.o : %.cpp $(DEP_DIR)/%.cpp.dep
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(COMPILE.cc) $< -o $@
# COMPILE.c  = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

# Assembler files ======================================================
# create assembler files from C source files
%.s : %.c
	$(AT)$(CC) $(CPPFLAGS) $(CFLAGS) -C -S $< -o $@
	@echo 'creating $@'

# Vala =================================================================
# generate C code from Vala
$(VALA_C_DIR)/%.c : %.vala $(VALA_VAPI)
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(VALAC) $(VALAFLAGS) --ccode $< \
		$(foreach vapi,$(filter-out $(VAPI_DIR)/$*.vapi,$(VALA_VAPI)),--use-fast-vapi=$(vapi))
#	$(AT)$(VALAC) $(VALAFLAGS) --ccode $(VALA_SRC) $(foreach vapi,$(VALA_VAPI),--use-fast-vapi=$(VAPI_DIR)/$(vapi))
	$(AT)$(MV) $*.c $@

# create vapi from Vala
$(VAPI_DIR)/%.vapi : %.vala
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(VALAC) $< --fast-vapi=$@

# Linking ==============================================================
# link ALL object files into binary
$(BIN) : $(OBJ)
	$(AT)$(MKDIR) $(@D)
	@echo 'linking  $@'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@

# Archiving ============================================================
# create static library from ALL object files
$(LIB) : $(OBJ)
	$(AT)$(MKDIR) $(@D)
	@echo 'removing $@'
	$(AT)$(RM) $@
	@echo 'creating $@'
	$(AR) $(ARFLAGS) $@ $^

########################################################################
# include generated dependency files
-include $(DEP)
include $(ULTIMAKE_PATH)/ultimake-help.mk
include $(ULTIMAKE_PATH)/dot.mk
include $(ULTIMAKE_PATH)/devtools.mk
# include $(ULTIMAKE_PATH)/gcc-warnings.mk

# TODO #################################################################
#
# TODO: for some reason, there is absolutely no leading "./" allowed,
#       otherwise the %-rules wont work
#       this makes half of the "-not" statements at the creation of the
#       FILES variable useless
# TODO: new approach for FILE list creation. instead of giving find the location as parameter, cd to the source directory and call "find ."
# TODO: try to avoid absolute paths and
# TODO: do not forget about the leading "./" problem
# TODO: reintroduce OUT_DIR but this time additionally to DEP_DIR and OBJ_DIR
# TODO: the dependency files have to be included after all rules,
#       because otherwise every included file will be built BEFORE the
#       target is created COMPLETELY WRONG. Included targets will always
#       built, even if several intermediate files are neded, for example
#       .vala -> .vapi,.c -> .dep
# if an included file does not exist but a rule exists, it will be created

# TODO: create shared library from ALL object files
# $(LIB) : $(OBJ)
# 	$(AT)$(MKDIR) $(@D)
# 	@echo 'removing $@'
# 	$(AT)$(RM) $@
# 	@echo 'creating $@'
# 	$(AT) $(CXX) -shared $(LDFLAGS) $(TARGET_ARCH) $^ -o $@

# $(TARGET) :


# CHANGELOG ############################################################
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




