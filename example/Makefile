

TARGETS += libFoo
libFoo   = ./lib/libfoo.a
libFoo.SOURCES  = ./lib/libfoo/
libFoo.INCLUDE  = -I./lib/libfoo/
libFoo.CPPFLAGS = $(libFoo.INCLUDE)

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

# print build commands
VERBOSE := 1

# ultimake has to be included at exactly this place:
# after defining targets and setting ultimake variables and before module dependency description
include ../ultimake.mk

# will link App1 to libFoo.a and libBar.a
$(App1) : $(libFoo) $(libBar)
