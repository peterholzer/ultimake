# Author: Peter Holzer
# Ultimake v1.17
# 18.10.2013


# Configuration ========================================================

# define DEBUG_ULTIMAKE to show executed commands
ifndef DEBUG_ULTIMAKE
    # AT := @
endif

# TODO: add current directory to include search list to allow relative locations
# CPPFLAGS += -I.
# TODO: SOURCES and INCLUDES default values
# SOURCES ?= .


# remove default suffix rules
.SUFFIXES :
# The prerequisites of the special target .SUFFIXES are the list of suffixes
# to be used in checking for suffix rules. See Old-Fashioned Suffix Rules.

# preserve intermediate files
.SECONDARY :
# The targets which .SECONDARY depends on are treated as intermediate files,
# except that they are never automatically deleted. See Chains of Implicit Rules.
# .SECONDARY with no prerequisites causes all targets to be treated as secondary
# (i.e., no target is removed because it is considered intermediate).

# TODO: reintroduce OUT_DIR but this time additionally to DEP_DIR and OBJ_DIR


# name of this makefile
ULTIMAKE_NAME := $(notdir $(lastword $(MAKEFILE_LIST)))

# path of this makefile
ULTIMAKE_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))


# CFLAGS += -std=c99

# Default output file, when no BIN or LIB is defined ===================
ifndef LIB
    BIN ?= a.out
endif


# Default Directories ==================================================
# TODO: for some reason, there is absolutely no leading "./" allowed,
#       otherwise the %-rules wont work
#       this makes half of the "-not" statements at the creation of the
#       FILES variable useless
DEP_DIR    ?= .dep
OBJ_DIR    ?= .obj
VAPI_DIR   ?= .vala/vapi
VALA_C_DIR ?= .vala/c


# Default Tools ========================================================

VALAC ?= valac

MKDIR ?= mkdir -p -v
MV ?= mv -f
RM ?= rm -f

# Zusammensetzung der Dateipfade:
# SOURCES ... OBJ_DIR ... `find ..`
#
#    .                        test/test.c
#    .         /  .obj   /    test/test.o
#
#  ~/sync/lib  /         /    test/test.c
#  ~/sync/lib  /  .obj   /    test/test.o


# TODO: new approach for FILE list creation. instead of giving find the location as parameter, cd to the source directory and call "find ."
# TODO: try to avoid absolute paths and
# TODO: do not forget about the leading "./" problem

# executes find on several directories and allows several exclude paths
# usage;
#     $(call find_exclude,$(SEARCH_DIR),$(EXCLUDE_DIR))
# executes something like:
#     find $1 -type f -not -path $2
# $(1)  search directory
# $(2)  exclude directory
find_exclude = $(foreach dir,$(1), $(shell find $(dir) -type f $(foreach p,$(2), -not -path "$(p)/*" -not -path "./$(p)/*")))


# Create lists of existing files =======================================

# find all files in working directory
# but exclude all files in DEP_DIR, OBJ_DIR, VAPI_DIR and VALA_C_DIR
# TODO: fix this leading "./" problem
FILES := $(call find_exclude,$(SOURCES), $(DEP_DIR) $(OBJ_DIR) $(VAPI_DIR) $(VALA_C_DIR))

# cut "./" prefix away
FILES := $(patsubst ./%,%,$(FILES))

# TODO: add description for SOURCES and INCLUDES
SOURCES := $(foreach dir,$(SOURCES),$(patsubst /%, /%, $(realpath $(dir))))

CPPFLAGS_INC := $(foreach include,$(INCLUDES),-I$(include))
CPPFLAGS += $(CPPFLAGS_INC)

# filter C/C++/Vala sources
C_SRC    ?= $(filter %.c,$(FILES))
CXX_SRC  ?= $(filter %.cpp,$(FILES))
VALA_SRC ?= $(filter %.vala,$(FILES))


# Create lists of generated files ======================================

# create list of vapi files from vala sources
VALA_VAPI  := $(VALA_SRC:%.vala=$(VAPI_DIR)/%.vapi)

# create list of vala-generated C source files from vala sources and add it to the list of C source files
VALA_C_SRC := $(VALA_SRC:%.vala=$(VALA_C_DIR)/%.c)
C_SRC += $(VALA_C_SRC)

# create list of dependency files from sources and handle $(DEP_DIR) prefix
DEP := $(C_SRC:%.c=$(DEP_DIR)/%.c.dep) $(CXX_SRC:%.cpp=$(DEP_DIR)/%.cpp.dep)

# create list of object files from sources and handle $(OBJ_DIR) prefix
OBJ := $(C_SRC:%.c=$(OBJ_DIR)/%.c.o) $(CXX_SRC:%.cpp=$(OBJ_DIR)/%.cpp.o)

# OBJ := $(foreach sources,$(SOURCES),$(filter $(sources)%,$(C_SRC:sources%.c=$(OBJ_DIR)/%.c.o)))
# OBJ := $(foreach sources,$(SOURCES),$(patsubst $(sources)/%.c, $(sources)/$(OBJ_DIR)/%.c.o, $(filter $(sources)%,$(C_SRC))))

# Targets ==============================================================

.PHONY : all clean help help-files help-tools run


all : $(BIN) $(LIB)


clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(BIN)
	$(AT)-$(RM) $(LIB)
	$(AT)-$(RM) $(OBJ)
	$(AT)-$(RM) $(DEP)
	$(AT)-$(RM) $(VALA_VAPI) $(VALA_C_SRC)


run : $(BIN)
	./$(BIN)




# Rules ================================================================


# Object files .........................................................
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

# Dependency files .....................................................
# generate dependencies from C source files
$(DEP_DIR)/%.c.dep : %.c
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.c=%.c.o)" "$<"


# generate dependencies from C source files
$(DEP_DIR)/%.cpp.dep : %.cpp
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(OBJ_DIR)/$(<:%.cpp=%.cpp.o)" "$<"


# Vala .................................................................
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


# Linking ..............................................................
# link ALL object files into binary
$(BIN) : $(OBJ)
	$(AT)$(MKDIR) $(@D)
	@echo 'linking  $@'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@


# Archiving ............................................................
# create static library from ALL object files
$(LIB) : $(OBJ)
	$(AT)$(MKDIR) $(@D)
	@echo 'removing $@'
	$(AT)$(RM) $@
	@echo 'creating $@'
	$(AR) rcs $@ $^

# $(TARGET) :


#=======================================================================

# include generated dependency files
-include $(DEP)


include $(ULTIMAKE_PATH)/ultimake-help.mk
include $(ULTIMAKE_PATH)/dot.mk
include $(ULTIMAKE_PATH)/devtools.mk
# include $(ULTIMAKE_PATH)/gcc-warnings.mk

# TODO: the dependency files have to be included after all rules,
#       because otherwise every included file will be built BEFORE the
#       target is created COMPLETELY WRONG. Included targets will always
#       built, even if several intermediate files are neded, for example
#       .vala -> .vapi,.c -> .dep
# if an included file does not exist but a rule exists, it will be created



# CHANGELOG ############################################################
#
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




