# Author: Peter Holzer
# Ultimake v1.08
# 21.06.2013
MAKEFILENAME := ultimake-1.08.mk
#
# Dieses Makefile kompiliert alle *.cpp und *.c-Files in einem Ordner und seinen Unterordnern
# und linkt diese zu einer Anwendung bzw. archiviert sie zu einer statischen Bibliothek,
# je nachdem, welche Daten angegeben werden.
# Je nachdem, ob man eine Anwendung oder eine Bibliothek erstellen
# möchte, kann man die jeweils andere Variable einfach leer lassen.

# Es wird für jedes Source-File ein Makefile mit den Abhängigkeiten erstellt (*.d).
# Es ist von sämtlichen Headern und Sourcen abhängig, die included werden.


# Targets:
#     all
#     clean
#
#     debuginfo
#     doxygen       Dokumentation erstellen, benötigt $(DOXYFILE)
#     lint          Statische Quellcodeanalyse für C-Files
#     cppcheck      Statische Quellcodeanalyse für C++-Files
#     run           Programm ausführen
#
#
# ======================================================================

# HDR    := $(wildcard *.h) $(wildcard *.hpp)

# Wenn C-Quelldateien NICHT manuell angegeben wurden, danach suchen
ifndef CSRC
    CSRC   := $(wildcard *.c)
    CSRC   += $(foreach DIR, $(SUBDIRS), $(wildcard $(DIR)/*.c))
endif

# Wenn C++-Quelldateien nicht manuell angegeben wurden, danach suchen
ifndef CXXSRC
    CXXSRC := $(wildcard *.cpp)
    CXXSRC += $(foreach DIR, $(SUBDIRS), $(wildcard $(DIR)/*.cpp))
endif

ifdef BIN
    BIN := $(OUT_DIR)/$(BIN)
endif
ifdef LIB
    LIB := $(OUT_DIR)/$(LIB)
endif


DEP := $(addprefix $(OUT_DIR)/,$(CSRC:%.c=%.c.d) $(CXXSRC:%.cpp=%.cpp.d))
OBJ := $(addprefix $(OUT_DIR)/,$(CSRC:%.c=%.c.o) $(CXXSRC:%.cpp=%.cpp.o))

SUBDIRS_OUT := $(foreach DIR, $(SUBDIRS), $(OUT_DIR)/$(DIR))

$(shell mkdir -p -v $(SUBDIRS_OUT))
# include the description for each module
# include $(patsubst %,%/Makefile,$(SUBDIRS))


# Standard Tools
ifndef LINT
	LINT := splint
endif
ifndef DOXYGEN
	DOXYGEN := doxygen
endif





all : $(BIN) $(LIB)
# all: debuginfo

include $(DEP)


# Rules ================================================================

help :
	@echo ' '
	@echo 'Aufruf: make -f $(MAKEFILENAME)'
	@echo ' '
	@echo 'Targets:'
	@echo '  all        Erstellt alle Ziele'
	@echo '  clean      Löscht alle Zieldateien'
	@echo '  cppcheck   '
	@echo '  debuginfo  Zeigt Variablen des Makefiles an'
	@echo '  doxygen    Erstellt die Dokumentation'
	@echo '  help       Zeigt diesen Text an'
	@echo '  lint       '
	@echo '  run        '
	@echo ' '


debuginfo :
	@echo 'target binary    BIN:  $(BIN)'
	@echo 'target library   LIB:  $(LIB)'
	@echo ' '
	@echo 'output folder:'        $(OUT)'
	@echo 'modules (subfolders):  $(SUBDIRS)'
	@echo ' '
	@echo 'Tools:'
	@echo 'archiver         AR:       $(CC)'
	@echo 'C compiler       CC:       $(CC)'
	@echo 'C++ compiler     CXX:      $(CXX)'
	@echo 'remove           RM:       $(RM)'
	@echo '                 DOXYGEN:  $(DOXYGEN)'
	@echo '                 LINT:     $(LINT)'
	@echo ' '
	@echo 'Flags:'
	@echo 'preprocessor     CPPFLAGS: $(CPPFLAGS)'
	@echo 'C compiler       CFLAGS:   $(CFLAGS)'
	@echo 'C++ compiler     CXXFLAGS: $(CXXFLAGS)'
	@echo 'linker           LDFLAGS:  $(LDFLAGS)'
	@echo ' '
	@echo 'Files:'
	@echo -e 'C Sources:    CSRC    \n$(CSRC:%.c=%.c\n )'
	@echo -e 'C++Sources:   CXXSRC  \n$(CXXSRC:%.cpp=%.cpp\n )'
	@echo -e 'Objects:      OBJ     \n$(OBJ:%.o=%.o\n )'
	@echo -e 'Dependencies: DEP     \n$(DEP:%.d=%.d\n )'
	@echo ' '
	@echo 'Ultimake debug info'
	@echo 'SUBDIRS_OUT:               $(SUBDIRS_OUT)'
	@echo 'COMPILE.c:                 $(COMPILE.c)'
	@echo 'COMPILE.cc:                $(COMPILE.cc)'
	@echo ' '


doxygen :
	@echo "Generating documentation"
	$(DOXYGEN) $(DOXYFILE)



# C / C++ dependency generation, compilation and linking ===============


# compile object files from C sources
# %.o : %.cpp %.d
$(OUT_DIR)/%.cpp.o : %.cpp $(OUT_DIR)/%.cpp.d
	@echo -e 'compiling $< \t=> $@'
	@$(COMPILE.cc) $< -o $@


# compile object files from C++ sources
# %.o : %.c %.d
$(OUT_DIR)/%.c.o : %.c $(OUT_DIR)/%.c.d
	@echo -e 'compiling $< \t=> $@'
	@$(COMPILE.c) $< -o $@


# generate dependencies from C sources
$(OUT_DIR)/%.c.d : %.c
	@echo -e 'creating dependency from $< \t=> $@'
	@$(CC) -I. -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.c=%.c.o)" "$<"


# generate dependencies from C sources
$(OUT_DIR)/%.cpp.d : %.cpp
	@echo -e 'creating dependency from $< \t=> $@'
	@$(CXX) -I. -std=c++0x -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.cpp=%.cpp.o)" "$<"
#	@$(CXX) -I. -std=c++0x -MF"$@" -MG -MM -MP -MT"$@" -MT"$(OUT_DIR)/$(<:%.cpp=%.cpp.o)" "$<"


# link object files into binary
$(BIN) : $(OBJ)
	@echo 'linking $@'
	@$(LINK.cc) $^ -o $@


# create static library from object files
$(LIB) : $(OBJ)
	@$(RM) -f $@
	@echo 'archiving library'
	@$(AR) $(ARFLAGS) $@ $^

#=======================================================================
#
clean :
	@echo 'Cleaning ...'
	-$(RM) $(BIN) $(LIB) $(OBJ) $(DEP)

lint :
	$(LINT) $(CSRC)

cppcheck :
	cppcheck --enable=all --check-config $(CXXSRC) 2>&1 > /dev/null | sed 's/[][]//g'


run: all
	$(BIN)


.PHONY : all clean cppcheck doxygen lint








