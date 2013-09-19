# Author: Peter Holzer
# Ultimake v1.10
# 19.09.2013
# MAKEFILENAME := ultimake-1.10.mk




.SUFFIXES:

# name of THIS makefile
THIS := $(notdir $(lastword $(MAKEFILE_LIST)))
# path of THIS makefile
HERE := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))


#   @echo 'Dieses Makefile kompiliert alle *.cpp und *.c-Files in einem Ordner und '
#   @echo 'seinen Unterordnern und linkt diese zu einer Anwendung bzw. archiviert  '
#   @echo 'sie zu einer statischen Bibliothek, je nachdem, welche Daten angegeben  '
#   @echo 'werden.                                                                 '
#   @echo 'Je nachdem, ob man eine Anwendung oder eine Bibliothek erstellen möchte,'
#   @echo 'kann man die jeweils andere Variable einfach leer lassen.               '


# @echo 'Aufruf: make -f $(MAKEFILENAME)'



#   @echo 'Ultimake debug info'
#   @echo 'SUBDIRS_OUT:               $(SUBDIRS_OUT)'
#   @echo 'COMPILE.c:                 $(COMPILE.c)'
#   @echo 'COMPILE.cc:                $(COMPILE.cc)'


#=======================================================================


# Input related ========================================================

# Search for C/C++ source code files if not specified

## list of C sources
#ifndef C_SRC
#    C_SRC   := $(wildcard *.c)
#    C_SRC   += $(foreach DIR, $(SUBDIRS), $(wildcard $(DIR)/*.c))
#endif
#
## list of C++ sources
#ifndef CXX_SRC
#    CXX_SRC := $(wildcard *.cpp)
#    CXX_SRC += $(foreach DIR, $(SUBDIRS), $(wildcard $(DIR)/*.cpp))
#endif

# TODO: FIND statt WILDCARD?
# TODO: keine Module/Subdir mehr nötig

C_SRC = $(shell find -name '*.c')
CXX_SRC = $(shell find -name '*.cpp')

#    lua/luaconfig.cpp
# -> ../out/lua/luaconfig.cpp.o


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
    MKDIR := $(shell which mkdir) -p -v
endif
ifndef RM
    RM := $(shell which rm) -f
endif


# TODO: this
#ools ::
#	@$(RM)    --version >/dev/null 2>/dev/null || echo 'rm not found!'
#	@$(MKDIR) --version >/dev/null 2>/dev/null || echo 'mkdir not found!'
#	@$(CC)    --version >/dev/null 2>/dev/null || echo 'gcc not found!'
#	@$(CXX)   --version >/dev/null 2>/dev/null || echo 'g++ not found!'
#	@$(VALAC) --version >/dev/null 2>/dev/null || echo 'valac not found!'

#	@$() --version >/dev/null 2>/dev/null || echo ' not found!'








# Targets ================================================================

all : $(BIN) $(LIB)

-include $(DEP)


clean :
	@echo 'Cleaning ...'
	-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP)


help ::
	@echo '                                                            '
	@echo 'ultimake                                                    '
	@echo '    $(THIS)'
	@echo '    $(HERE)'
	@echo '                                                            '
	@echo 'Targets:                                                    '
	@echo '    all        Create binary/static library                 '
	@echo '    clean      Clean output directory                       '
	@echo '    help       Show this text                               '
	@echo '    run        Run executable                               '
	@echo '                                                            '
	@echo '    cppcheck                                                '
	@echo '    doxygen                                                 '
	@echo '    lint                                                    '
	@echo '                                                            '
	@echo '    *.d                                                     '
	@echo '    *.o                                                     '
	@echo '                                                            '
	@echo '                                                            '
	@echo 'Targets & Output                                            '
	@echo '    output folder:          $(OUT)'
	@echo '    target binary     BIN:  $(BIN)'
	@echo '    target library    LIB:  $(LIB)'
	@echo '    modules (subfolders):  $(SUBDIRS)'
	@echo '  '
	@echo '............................................................'
	@echo 'Flags:'
	@echo -e 'CPPFLAGS (preprocessor flags)\n    $(CPPFLAGS:-%=-%\n   )'
	@echo -e 'CFLAGS (C compiler flags)    \n    $(CFLAGS:-%=-%\n   )'
	@echo -e 'CXXFLAGS (C++ compiler flags)\n    $(CXXFLAGS:-%=-%\n   )'
	@echo -e 'LDFLAGS (Linker flags)       \n    $(LDFLAGS:-%=-%\n   )'
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
	$(CXX) $(LDFLAGS) $(TARGET_ARCH) $(OBJ)


# Archiving ============================================================

# create static library from object files
# .a : .o
$(LIB) : $(OBJ)
#	@$(MKDIR) $(@D)
	@$(RM) -f $@
	@echo 'archiving library'
	@$(AR) $(ARFLAGS) $@ $^

#=======================================================================





include $(HERE)/dot.mk
include $(HERE)/devtools.mk






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


