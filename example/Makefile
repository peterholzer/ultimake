




# Nothin special here
# CPPFLAGS +=
CFLAGS   := -std=c11
CXXFLAGS := -std=c++11
# LDFLAGS  := -L. -Wl,--start-group -lbox2d -lLua -lreadline -lm -Wl,--end-group

# This option is needed for some uses of dlopen or to allow obtaining backtraces from within a program.
LDFLAGS := -rdynamic
ARFLAGS  := rs





# The target 'all' depends on modules/libs defined in TARGETS

# TARGETS += <Module>               defines a new target
# <Module> = ./bin/executable       the resulting binary/library file
# <Module>.SOURCES                  where the look for sources. Dependencies will be generated automatically.
# <Module>.CPPFLAGS, .CC...         use compiler flags like you would normally do
#

TARGETS += libFoo
libFoo   = ./lib/libfoo.a
libFoo.SOURCES   = ./lib/libfoo/
libFoo.INCLUDE   = -I./lib/libfoo/
libFoo.CPPFLAGS  = $(libFoo.INCLUDE)
#libFoo.CCFLAGS  =
#libFoo.CXXFLAGS =
#libFoo.CC       = gcc
#libFoo.CXX      = g++


TARGETS += libBar
libBar   = ./lib/libbar.a
libBar.SOURCES  = ./lib/libbar/
libBar.INCLUDE  = -I./lib/libbar/
libBar.CPPFLAGS = $(libBar.INCLUDE)


TARGETS += App1
App1     = App1.bin
App1.SOURCES  = src/
App1.CPPFLAGS = -I./lib/ $(libFoo.INCLUDE) $(libBar.INCLUDE)
App1.LDFLAGS  = -L.
#App1.CC  =
#App1.CXX =
#App1.LD  =

# print build commands
VERBOSE := 1

# ultimake has to be included at exactly this place:
# after defining targets and setting ultimake variables and before module dependency description
include ../ultimake.mk

# will link App1 to libFoo.a and libBar.a
$(App1) : $(libFoo) $(libBar)
