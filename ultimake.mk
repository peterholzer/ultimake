# Author: Peter Holzer
# Ultimake v1.11
# 19.09.2013
# MAKEFILENAME := ultimake-1.11.mk






.DEFAULT : all

.SUFFIXES :

# name of this makefile
ULTIMAKE_NAME := $(notdir $(lastword $(MAKEFILE_LIST)))
# path of this makefile
ULTIMAKE_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))



#   @echo 'Ultimake debug info'
#   @echo 'SUBDIRS_OUT:               $(SUBDIRS_OUT)'
#   @echo 'COMPILE.c:                 $(COMPILE.c)'
#   @echo 'COMPILE.cc:                $(COMPILE.cc)'

#=======================================================================


# Input related ========================================================

# Search for C/C++ source code files if not specified
# and cut "./" prefix away

ifndef C_SRC
    C_SRC = $(shell find -name '*.c')
    C_SRC := $(patsubst ./%,%,$(C_SRC))
endif

ifndef CXX_SRC
    CXX_SRC = $(shell find -name '*.cpp')
    CXX_SRC := $(patsubst ./%,%,$(CXX_SRC))
endif



# Output related =======================================================

# default value
ifndef OUT
    OUT  := .
endif


# create path to object and dependency file for every source file
# add output folder prefix
# list of dependency files
DEP := $(addprefix $(OUT)/,$(C_SRC:%.c=%.c.d) $(CXX_SRC:%.cpp=%.cpp.d))
# list of object files
OBJ := $(addprefix $(OUT)/,$(C_SRC:%.c=%.c.o) $(CXX_SRC:%.cpp=%.cpp.o))



# add output folder prefix
ifdef BIN
    BIN := $(OUT)/$(BIN)
endif
ifdef LIB
    LIB := $(OUT)/$(LIB)
endif


# Tools ================================================================

ifndef MKDIR
    MKDIR := mkdir -p -v
endif
ifndef RM
    RM := rm -f
endif


ifndef ARFLAGS
    ARFLAGS := rcsv
    # r = replace existing or insert new file(s) into the archive
    # c = do not warn if the library had to be created
    # s = create an archive index (cf. ranlib)
endif


# Targets ================================================================

all : $(BIN) $(LIB)

-include $(DEP)


clean :
	@echo 'Cleaning ...'
	-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP)


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
	@echo '    output folder:    OUT:  $(OUT)'
	@echo '    target binary     BIN:  $(BIN)'
	@echo '    target library    LIB:  $(LIB)'
	@echo '  '
	@echo '............................................................'
	@echo 'Flags:'
	@echo -e 'CPPFLAGS (preprocessor flags)\n    $(CPPFLAGS:-%=-%\n   )'
	@echo -e 'CFLAGS (C compiler flags)    \n    $(CFLAGS:-%=-%\n   )'
	@echo -e 'CXXFLAGS (C++ compiler flags)\n    $(CXXFLAGS:-%=-%\n   )'
	@echo -e 'LDFLAGS (Linker flags)       \n    $(LDFLAGS:-%=-%\n   )'
	@echo -e 'ARFLAGS (Archiver flags)     \n    $(ARFLAGS:-%=-%\n   )'
	@echo ' '
	@echo '............................................................'
	@echo 'Files:'
	@echo -e 'C_SRC (C sources)       \n    $(C_SRC:%.c=%.c\n   )'
	@echo -e 'CXX_SRC (C++ sources)   \n    $(CXX_SRC:%.cpp=%.cpp\n   )'
	@echo -e 'OBJ (object files)      \n    $(OBJ:%.o=%.o\n   )'
	@echo -e 'DEP (dependencies)      \n    $(DEP:%.d=%.d\n   )'
	@echo '  '
	@echo '  '


run: all
	./$(BIN)


.PHONY : all clean help run

.PHONY : tools


tools ::
	@echo '............................................................'
	@echo 'Tools:'
	@echo '    archiver         AR:       $(AR)'
	@echo '    C preprocessor   CPP:      $(CPP)'
	@echo '    C compiler       CC:       $(CC)'
	@echo '    C++ compiler     CXX:      $(CXX)'
#	@echo '    vala compiler    VALAC:    $(VALAC)'
	@echo '    linker           LD:       $(LD)'
	@echo '  '
	@echo '    remove           RM:       $(RM)'
	@echo '    mkdir            MKDIR:    $(MKDIR)'
	@echo '  '


# Rules ================================================================


# Object files =========================================================
# compile object files from C sources
$(OUT)/%.c.o : %.c $(OUT)/%.c.d
#	@$(MKDIR) $(@D)
	@echo '$(CC) [...] $< -o $@'
	@$(COMPILE.c) $< -o $@


# compile object files from C++ sources
$(OUT)/%.cpp.o : %.cpp $(OUT)/%.cpp.d
#	@$(MKDIR) $(@D)
	@echo '$(CXX) [...] $< -o $@'
	@$(COMPILE.cc) $< -o $@


# Dependency files =====================================================
# generate dependencies from C sources
$(OUT)/%.c.d : %.c
	@$(MKDIR) $(@D)
	@echo -e 'creating dependency from $< \t=> $@'
	@$(CC) -I. -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT)/$(<:%.c=%.c.o)" "$<"


# generate dependencies from C sources
$(OUT)/%.cpp.d : %.cpp
	@$(MKDIR) $(@D)
	@echo -e 'creating dependency from $< \t=> $@'
	@$(CXX) -I. -std=c++11 -MF"$@" -MG -MM -MT"$@" -MT"$(OUT)/$(<:%.cpp=%.cpp.o)" "$<"

# Linking ==============================================================


# link object files into binary
$(BIN) : $(OBJ)
#	@$(MKDIR) $(@D)
	@echo 'linking $@'
	@echo '$(CXX) $(LDFLAGS) [...]'
	$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ -o $@


# Archiving ============================================================

# TODO: create static library from object files
# .a : .o
$(LIB) : $(OBJ)
#	@$(MKDIR) $(@D)
#	@$(RM) -f $@
	@echo 'archiving library'
	$(AR) $(ARFLAGS) $@ $^

#=======================================================================





include $(ULTIMAKE_PATH)/dot.mk
include $(ULTIMAKE_PATH)/devtools.mk






# CHANGELOG:
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


