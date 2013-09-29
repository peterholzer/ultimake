# Author: Peter Holzer
# Ultimake v1.12
# 29.09.2013
# MAKEFILENAME := ultimake-1.12.mk


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



# Input related ========================================================

# find all files in working directory
FILES := $(shell find -type f)

# cut "./" prefix away
FILES := $(patsubst ./%,%,$(FILES))

# filter C/C++ sources
C_SRC    := $(filter %.c,$(FILES))
CXX_SRC  := $(filter %.cpp,$(FILES))

# filter vala sources and add to C sources and objects
VALA_SRC   := $(filter %.vala,$(FILES))
VALA_VAPI  := $(VALA_SRC:%.vala=%.vapi)
VALA_VAPI  := $(addprefix $(VAPI_DIR)/,$(VALA_VAPI))
VALA_C_SRC := $(VALA_SRC:%.vala=%.c)
C_SRC += $(VALA_C_SRC)

# Output related =======================================================
# create lists of output files and handle $(OUT) prefix


# default value
ifndef OUT
    OUT  := .
endif
ifndef VAPI_DIR
    VAPI_DIR  := .
endif


# create path to object and dependency file for every source file
# add output folder prefix

# list of object files
C_OBJ    := $(addprefix $(OUT)/,$(C_SRC:%.c=%.c.o))
CXX_OBJ  := $(addprefix $(OUT)/,$(CXX_SRC:%.cpp=%.cpp.o))
OBJ := $(C_OBJ) $(CXX_OBJ)
#OBJ := $(addprefix $(OUT)/,$(C_SRC:%.c=%.c.o) $(CXX_SRC:%.cpp=%.cpp.o))
# list of dependency files
#DEP := $(addprefix $(OUT)/,$(C_SRC:%.c=%.c.d) $(CXX_SRC:%.cpp=%.cpp.d))
DEP := $(OBJ:%.o=%.d)



# add output folder prefix
ifdef BIN
    BIN := $(OUT)/$(BIN)
endif
ifdef LIB
    LIB := $(OUT)/$(LIB)
endif


# Default Tools ========================================================

ifndef MKDIR
    MKDIR := mkdir -p -v
endif
#ifndef MV
#    MV := mv
#endif
ifndef RM
    RM := rm -f
endif
ifndef VALAC
    VALAC := valac
endif

ifndef ARFLAGS
    ARFLAGS := rcsv
#   r = replace existing or insert new file(s) into the archive
#   c = do not warn if the library had to be created
#   s = create an archive index (cf. ranlib)
#   v = be verbose
endif


ifndef CC
    # CC := echo
endif

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
	@echo '    $(ULTIMAKE_NAME)'
	@echo '    $(ULTIMAKE_PATH)'
	@echo 'include trace:$(MAKEFILE_LIST)'
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
	@echo '    output folder:    OUT:       $(OUT)'
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
	@echo -e 'FILES                   \n    $(FILES:%=%\n   )'
	@echo -e 'VALA_SRC (Vala sources) \n    $(VALA_SRC:%=%\n   )'
	@echo -e 'VALA_VAPI               \n    $(VALA_VAPI:%=%\n   )'
	@echo -e 'VALA_C_SRC              \n    $(VALA_C_SRC:%=%\n   )'
	@echo -e 'C_SRC (C sources)       \n    $(C_SRC:%=%\n   )'
	@echo -e 'CXX_SRC (C++ sources)   \n    $(CXX_SRC:%=%\n   )'
	@echo -e 'OBJ (object files)      \n    $(OBJ:%=%\n   )'
	@echo -e 'DEP (dependencies)      \n    $(DEP:%=%\n   )'
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
$(OUT)/%.c.o : %.c $(OUT)/%.c.d
#	$(AT)$(MKDIR) $(@D)
#	@echo 'compiling $<'
	@echo 'creating  $@'
	$(AT)$(COMPILE.c) $< -o $@


# compile object files from C++ sources
$(OUT)/%.cpp.o : %.cpp $(OUT)/%.cpp.d
#	$(AT)$(MKDIR) $(@D)
#	@echo 'compiling $<'
	@echo 'creating  $@'
	$(AT)$(COMPILE.cc) $< -o $@


# Dependency files .....................................................
# generate dependencies from C sources
$(OUT)/%.c.d : %.c
	$(AT)$(MKDIR) $(@D)
#	@echo -e 'creating dependency from $<'
	@echo 'creating  $@'
	$(AT)$(CC) -I. -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT)/$(<:%.c=%.c.o)" "$<"


# generate dependencies from C sources
$(OUT)/%.cpp.d : %.cpp
	$(AT)$(MKDIR) $(@D)
#	@echo -e 'creating dependency from $<'
	@echo 'creating  $@'
	$(AT)$(CC) -I. -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(OUT)/$(<:%.cpp=%.cpp.o)" "$<"


# Vala .................................................................
# create all vala-c sources from all vala sources
#$(VALA_C_SRC) : $(VALA_SRC) $(VALA_VAPI)
#	@echo 'compiling $(VALA_SRC)'
#	$(AT)$(VALAC) $(VALAFLAGS) --ccode $(VALA_SRC)

# .INTERMEDIATE : %.vapi $(VALA_VAPI)



# $(VALA_C_SRC) : $(VALA_SRC) $(VALA_VAPI)
# $(VALA_SRC) : $(VALA_VAPI)


%.c : %.vala $(VALA_VAPI)
#	@echo '$(VALAC) $<'
	@echo 'creating  $@'
	$(AT)$(VALAC) $(VALAFLAGS) --ccode $< \
		$(foreach vapi,$(filter-out $(VAPI_DIR)/$*.vapi,$(VALA_VAPI)),--use-fast-vapi=$(vapi))
#	$(AT)$(VALAC) $(VALAFLAGS) --ccode $(VALA_SRC) $(foreach vapi,$(VALA_VAPI),--use-fast-vapi=$(VAPI_DIR)/$(vapi))


$(VAPI_DIR)/%.vapi : %.vala
	$(AT)$(MKDIR) $(@D)
# %.vapi : %.vala
#	@echo 'creating vapi from $<'
	@echo 'creating  $@'
	$(AT)$(VALAC) $< --fast-vapi=$@



# Linking ..............................................................
# link object files into binary # $(VALA_C_SRC)
$(BIN) : $(OBJ)
#	$(AT)$(MKDIR) $(@D)
	@echo 'linking  $@'
	$(AT)$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@


# Archiving ............................................................
# create static library from object files
$(LIB) : $(OBJ)
#	$(AT)$(MKDIR) $(@D)
#	$(AT)$(RM) -f $@
	@echo 'archiving $@'
#	@echo 'archiving library'
	$(AR) $(ARFLAGS) $@ $^

#=======================================================================





include $(ULTIMAKE_PATH)/dot.mk
include $(ULTIMAKE_PATH)/devtools.mk






# CHANGELOG:
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
