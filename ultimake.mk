# Author: Peter Holzer
# Ultimake v1.13
# 02.10.2013


# Configuration ========================================================

ifndef
    AT := @
endif



# remove default suffix rules
.SUFFIXES :

# preserve intermediate files
.SECONDARY:

# set default target to all
all:
#=======================================================================



# name of this makefile
ULTIMAKE_NAME := $(notdir $(lastword $(MAKEFILE_LIST)))

# path of this makefile
ULTIMAKE_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))




# Default Directories ==================================================
ifndef DEP_DIR
    DEP_DIR  := .dep
endif
ifndef OBJ_DIR
    OBJ_DIR  := .obj
endif
ifndef VAPI_DIR
    VAPI_DIR  := .vala/vapi
endif
ifndef VALA_C_DIR
    VALA_C_DIR  := .vala/c
endif
# Default Tools ========================================================
ifndef MKDIR
    MKDIR := mkdir -p -v
endif
ifndef MV
   MV := mv -f
endif
ifndef RM
    RM := rm -f
endif
ifndef VALAC
    VALAC := valac
endif


# Create file lists ====================================================

# if OBJ_DIR is a single dot "."
ifeq ($(OBJ_DIR),$(filter .,$(OBJ_DIR)))
    # find all files in working directory
    FILES := $(shell find -type f)
else
    # find all files in working directory but exclude all files in DEP_DIR, OBJ_DIR and VAPI_DIR
    FILES := $(shell find -type f -not -path "$(DEP_DIR)/*"    -not -path "./$(DEP_DIR)/*"   \
                                  -not -path "$(OBJ_DIR)/*"    -not -path "./$(OBJ_DIR)/*"   \
                                  -not -path "$(VAPI_DIR)/*"   -not -path "./$(VAPI_DIR)/*"  \
                                  -not -path "$(VALA_C_DIR)/*" -not -path "./$(VALA_C_DIR)/*")
endif

# TODO: Liste für aus Vala generierte C Sourcen lieber aus FILES oder aus VALA_SRC erstellen?

# FILES -> VALA_SRC -> VALA_C_SRC -> DEP -> OBJ

# cut "./" prefix away
FILES := $(patsubst ./%,%,$(FILES))

# filter C/C++ sources
C_SRC    := $(filter %.c,$(FILES))
CXX_SRC  := $(filter %.cpp,$(FILES))

# filter vala sources and add to C sources and objects
VALA_SRC   := $(filter %.vala,$(FILES))
VALA_VAPI  := $(VALA_SRC:%.vala=%.vapi)
VALA_VAPI  := $(addprefix $(VAPI_DIR)/,$(VALA_VAPI))
VALA_C_SRC := $(VALA_SRC:%.vala=$(VALA_C_DIR)/%.c)
C_SRC += $(VALA_C_SRC)


# create lists of output files and handle $(OBJ_DIR) prefix

# create path to object and dependency file for every source file
# add output folder prefix

#list of dependency files
C_DEP    := $(addprefix $(DEP_DIR)/,$(C_SRC:%.c=%.c.d))
CXX_DEP  := $(addprefix $(DEP_DIR)/,$(CXX_SRC:%.cpp=%.cpp.d))
DEP := $(C_DEP) $(CXX_DEP)
# DEP := $(OBJ:%.o=%.d)

# list of object files
C_OBJ    := $(addprefix $(OBJ_DIR)/,$(C_SRC:%.c=%.c.o))
CXX_OBJ  := $(addprefix $(OBJ_DIR)/,$(CXX_SRC:%.cpp=%.cpp.o))
OBJ := $(C_OBJ) $(CXX_OBJ)


# Targets ================================================================
.PHONY : all clean help run tools


-include $(DEP)


all : $(BIN) $(LIB)


clean :
	@echo 'Cleaning ...'
	$(AT)-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP)


clean-all :
	@echo 'Cleaning everything...'
	$(AT)-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP) $(VALA_VAPI) $(VALA_C_SRC)


help ::
	@echo '                                                            '
	@echo 'ultimake                                                    '
	@echo 'filename: $(ULTIMAKE_NAME)'
	@echo 'location: $(ULTIMAKE_PATH)'
	@echo 'Usage: make -f $(ULTIMAKE_NAME)'
	@echo '                                                            '
	@echo '                                                            '
	@echo 'Targets:                                                    '
	@echo '    all        Create binary/static library                 '
	@echo '    clean      Clean output directory                       '
	@echo '    help       Show this text                               '
	@echo '    run        Run executable                               '
	@echo '                                                            '
	@echo '    *.d                                                     '
	@echo '    *.o                                                     '
	@echo '                                                            '
	@echo '                                                            '
	@echo 'Targets & Output                                            '
	@echo '    output folder:    OBJ_DIR:   $(OBJ_DIR)'
	@echo '    vapi folder:      VAPI_DIR:  $(VAPI_DIR)'
	@echo '    target binary     BIN:       $(BIN)'
	@echo '    target library    LIB:       $(LIB)'
	@echo '  '
	@echo '............................................................'
	@echo 'Flags:'
	@echo -e 'CPPFLAGS (preprocessor flags)\n    $(CPPFLAGS:%=%\n   )'
	@echo -e 'CFLAGS (C compiler flags)    \n    $(CFLAGS  :%=%\n   )'
	@echo -e 'CXXFLAGS (C++ compiler flags)\n    $(CXXFLAGS:%=%\n   )'
	@echo -e 'LDFLAGS (Linker flags)       \n    $(LDFLAGS :%=%\n   )'
	@echo -e 'ARFLAGS (Archiver flags)     \n    $(ARFLAGS :%=%\n   )'
	@echo ' '
	@echo '............................................................'
	@echo 'Files:'
	@echo -e 'FILES (all files, excludes OBJ_DIR and VAPI_DIR)'
	@echo -e '    $(FILES:%=%\n   )'
	@echo -e 'VALA_SRC (Vala sources)'
	@echo -e '    $(VALA_SRC:%=%\n   )'
	@echo -e 'VALA_VAPI (.vapi files generated from .vala)'
	@echo -e '    $(VALA_VAPI:%=%\n   )'
	@echo -e 'VALA_C_SRC (.c files generated from .vala and vapi)'
	@echo -e '    $(VALA_C_SRC:%=%\n   )'
	@echo -e 'C_SRC (C sources)'
	@echo -e '    $(C_SRC:%=%\n   )'
	@echo -e 'CXX_SRC (C++ sources)'
	@echo -e '    $(CXX_SRC:%=%\n   )'
	@echo -e 'OBJ (object files)'
	@echo -e '    $(OBJ:%=%\n   )'
	@echo -e 'DEP (dependencies)'
	@echo -e '    $(DEP:%=%\n   )'
	@echo -e 'MAKEFILE_LIST (include trace)'
	@echo -e '    $(MAKEFILE_LIST:%=%\n   )'
	@echo '  '
	@echo '  '


run: all
	./$(BIN)


tools ::
	@echo '............................................................'
	@echo 'Tools:'
	@echo '    archiver         AR:       $(AR)'
	@echo '    C preprocessor   CPP:      $(CPP)'
	@echo '    C compiler       CC:       $(CC)'
	@echo '    C++ compiler     CXX:      $(CXX)'
	@echo '    vala compiler    VALAC:    $(VALAC)'
	@echo '    linker           LD:       $(LD)'
	@echo '  '
	@echo '    remove           RM:       $(RM)'
	@echo '    mkdir            MKDIR:    $(MKDIR)'
	@echo '  '


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
	$(AT)$(CC) -I. -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OBJ_DIR)/$(<:%.c=%.c.o)" "$<"


# generate dependencies from C sources
$(DEP_DIR)/%.cpp.d : %.cpp
	$(AT)$(MKDIR) $(@D)
	@echo 'creating $@'
#	$(AT)$(CC) -I. -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(OBJ_DIR)/$(<:%.cpp=%.cpp.o)" "$<"
	$(AT)$(CC) -I. -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(@:%.cpp.d=%.cpp.o)" "$<"


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
# link object files into binary # $(VALA_C_SRC)
$(BIN) : $(OBJ)
	$(AT)$(MKDIR) $(@D)
	@echo 'linking  $@'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@


# Archiving ............................................................
# create static library from object files
$(LIB) : $(OBJ)
	$(AT)$(MKDIR) $(@D)
	@echo 'removing $@'
	$(AT)$(RM) $@
	@echo 'creating $@'
	$(AR) rcs $@ $^

#=======================================================================


include $(ULTIMAKE_PATH)/dot.mk
include $(ULTIMAKE_PATH)/devtools.mk



# CHANGELOG:
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
#
#
#
