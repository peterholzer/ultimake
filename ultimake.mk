# Author: Peter Holzer
# Ultimake v1.16
# 12.10.2013


# Configuration ========================================================

# define DEBUG_ULTIMAKE to show executed commands
ifndef DEBUG_ULTIMAKE
    # AT := @
endif

# TODO: add current directory to include search list to allow relative locations
# CPPFLAGS += -I.

# SRC_DIRS ?= .


# remove default suffix rules
.SUFFIXES :

# preserve intermediate files
.SECONDARY :


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

MKDIR ?= mkdir -p -v
MV ?= mv -f
RM ?= rm -f

VALAC ?= valac


# Create lists of existing files =======================================

# find all files in working directory
# but exclude all files in DEP_DIR, OBJ_DIR, VAPI_DIR and VALA_C_DIR
# TODO: fix this leading "./" problem
FILES := $(foreach dir,$(SRC_DIRS), \
            $(shell find $(dir) -type f -not -path "$(DEP_DIR)/*"    -not -path "./$(DEP_DIR)/*"   \
                                    -not -path "$(OBJ_DIR)/*"    -not -path "./$(OBJ_DIR)/*"   \
                                    -not -path "$(VAPI_DIR)/*"   -not -path "./$(VAPI_DIR)/*"  \
                                    -not -path "$(VALA_C_DIR)/*" -not -path "./$(VALA_C_DIR)/*"))


SRC_DIRS := $(foreach dir,$(SRC_DIRS),$(patsubst /%, /%, $(realpath $(dir))))



# CPPFLAGS += $(foreach dir,$(SRC_DIRS), -I$(realpath $(dir)))
CPPFLAGS_INC := $(foreach dir,$(SRC_DIRS), -I$(dir))
CPPFLAGS += $(CPPFLAGS_INC)


# cut "./" prefix away
FILES := $(patsubst ./%,%,$(FILES))

# filter C/C++/Vala sources
C_SRC    ?= $(filter %.c,$(FILES))
CXX_SRC  ?= $(filter %.cpp,$(FILES))
VALA_SRC ?= $(filter %.vala,$(FILES))


# Create lists of generated files ======================================

# create list of vapi files from vala sources
VALA_VAPI  := $(VALA_SRC:%.vala=$(VAPI_DIR)/%.vapi)

# create list of vala-generated c sources from vala sources and add it to the list of c sources
VALA_C_SRC := $(VALA_SRC:%.vala=$(VALA_C_DIR)/%.c)
C_SRC += $(VALA_C_SRC)

# create list of dependency files from sources and handle $(DEP_DIR) prefix
DEP := $(C_SRC:%.c=$(DEP_DIR)/%.c.d) $(CXX_SRC:%.cpp=$(DEP_DIR)/%.cpp.d)

# create list of object files from sources and handle $(OBJ_DIR) prefix
OBJ := $(C_SRC:%.c=$(OBJ_DIR)/%.c.o) $(CXX_SRC:%.cpp=$(OBJ_DIR)/%.cpp.o)


# Targets ==============================================================

.PHONY : all clean help help-files help-tools run


all : $(BIN) $(LIB)


clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP) $(VALA_VAPI) $(VALA_C_SRC)


help ::
	@echo '                                                            '
	@echo 'ultimake                                                    '
	@echo 'filename: $(ULTIMAKE_NAME)'
	@echo 'location: $(ULTIMAKE_PATH)'
	@echo 'Usage: make -f $(ULTIMAKE_NAME)'
	@echo '                                                            '
	@echo 'Targets:                                                    '
	@echo '    all        Create binary/static library                 '
	@echo '    clean      Clean only binaries and dependencies         '
	@echo '    help       Show this text                               '
	@echo '    help-files Show file lists                              '
	@echo '    help-tools Show tools configuration                     '
	@echo '    run        Run executable                               '
	@echo '                                                            '
	@echo '                                                            '
	@echo '                                                            '


help-files ::
	@echo 'Output files'
	@echo '    target binary (BIN)'
	@echo '        $(BIN)'
	@echo '    target library (LIB)'
	@echo '        $(LIB)'
	@echo ' '
	@echo 'Output folders'
	@echo '    location of dependency files (DEP_DIR)'
	@echo '        $(DEP_DIR)'
	@echo '    location of object files (OBJ_DIR)'
	@echo '        $(OBJ_DIR)'
	@echo '    location of vala-generated c-code (VALA_C_DIR)'
	@echo '        $(VALA_C_DIR)'
	@echo '    location of vapi files (VAPI_DIR)'
	@echo '        $(VAPI_DIR)'
	@echo '  '
	@echo '............................................................'
	@echo 'Files:'
	@echo -e 'all files (FILES)'
	@echo -e 'excludes DEP_DIR, OBJ_DIR, VALA_C_DIR and VAPI_DIR'
	@echo -e '    $(FILES:%=%\n   )'
	@echo -e 'vala sources (VALA_SRC)'
	@echo -e '    $(VALA_SRC:%=%\n   )'
	@echo -e 'vapi files generated from .vala (VALA_VAPI)'
	@echo -e '    $(VALA_VAPI:%=%\n   )'
	@echo -e 'c files generated from .vala and vapi (VALA_C_SRC)'
	@echo -e '    $(VALA_C_SRC:%=%\n   )'
	@echo -e 'C sources (C_SRC)'
	@echo -e '    $(C_SRC:%=%\n   )'
	@echo -e 'C++ sources (CXX_SRC)'
	@echo -e '    $(CXX_SRC:%=%\n   )'
	@echo -e 'object files (OBJ)'
	@echo -e '    $(OBJ:%=%\n   )'
	@echo -e 'dependencies (DEP)'
	@echo -e '    $(DEP:%=%\n   )'
	@echo -e 'include trace (MAKEFILE_LIST)'
	@echo -e '    $(MAKEFILE_LIST:%=%\n   )'
	@echo '  '


help-tools ::
	@echo '............................................................'
	@echo 'Tools:'
	@echo '    archiver             AR:       $(AR)'
	@echo '    C preprocessor       CPP:      $(CPP)'
	@echo '    C compiler           CC:       $(CC)'
	@echo '    C++ compiler         CXX:      $(CXX)'
	@echo '    vala compiler        VALAC:    $(VALAC)'
	@echo '    linker               LD:       $(LD)'
	@echo '  '
	@echo '    move                 MV:       $(MV)'
	@echo '    remove               RM:       $(RM)'
	@echo '    mkdir                MKDIR:    $(MKDIR)'
	@echo '  '
	@echo '............................................................'
	@echo 'Flags:'
	@echo -e 'CPPFLAGS (preprocessor flags)\n    $(CPPFLAGS:%=%\n   )'
	@echo -e 'CFLAGS (C compiler flags)    \n    $(CFLAGS  :%=%\n   )'
	@echo -e 'CXXFLAGS (C++ compiler flags)\n    $(CXXFLAGS:%=%\n   )'
	@echo -e 'LDFLAGS (Linker flags)       \n    $(LDFLAGS :%=%\n   )'
	@echo -e 'ARFLAGS (Archiver flags)     \n    $(ARFLAGS :%=%\n   )'


run : $(BIN)
	./$(BIN)




# Rules ================================================================


# Object files .........................................................
# compile object files from C sources
$(OBJ_DIR)/%.c.o : %.c $(DEP_DIR)/%.c.d
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(COMPILE.c) $< -o $@


# compile object files from C++ sources
$(OBJ_DIR)/%.cpp.o : %.cpp $(DEP_DIR)/%.cpp.d
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(COMPILE.cc) $< -o $@


# Dependency files .....................................................
# generate dependencies from C sources
$(DEP_DIR)/%.c.d : %.c
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.c=%.c.o)" "$<"


# generate dependencies from C sources
$(DEP_DIR)/%.cpp.d : %.cpp
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
	$(AT)$(CC) $(CPPFLAGS_INC) -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(OBJ_DIR)/$(<:%.cpp=%.cpp.o)" "$<"
#	$(AT)$(CC) -I. -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(@:%.cpp.d=%.cpp.o)" "$<"


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

#=======================================================================

-include $(DEP)
include $(ULTIMAKE_PATH)/dot.mk
include $(ULTIMAKE_PATH)/devtools.mk
# include $(ULTIMAKE_PATH)/gcc-warnings.mk

# TODO: the dependency files have to be included after all rules,
#       because otherwise every included file will be built BEFORE the
#       target is created COMPLETELY WRONG. Included targets will always
#       built, even if several intermediate files are neded, for example
#       .vala -> .vapi,.c -> .d
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




