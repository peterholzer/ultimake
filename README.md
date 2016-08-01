

Ultimake
========

Ultimake is good
----------------
* if you just want to build something quickly
* if you have a small to medium project for one target architecture (this limitation will fall in future) that uses an external library with a crappy makefile.
* if your project is too big or your too lazy for maintaining makefiles but you still want to use GNU Make (or you just don't want to use anything else)




Usage
-----

Create a normal makefile.

Ultimake works with normal makefiles. You can mix it with make commands.
In the first part of the makefile you will describe your targets. A target may be an executable or a library and targets may depend on each other.
Every target gets its own CPPFLAGS, CFLAGS, CPPFLAGS, CXXFLAGS and LDFLAGS.



To create a new target named 'FooBar' add its name to the TARGETS variable.

    TARGETS += FooBar

Ultimake will look for macro definitions named 'FooBar' and 'FooBar.'

    FooBar =




Ultimake will automatically decide what type a target is by it's filename extension. '*.a' are static libraries, '*.so' dynamic libraries and else exectutables. By default, ultimake will link every application as C++, not as C, even when there are only C sources.


Features:
    * Create several targets at once
    * the targets define a path where ultimake recursively looks for source files
    * Ultimake outputs the automatically generated file lists and rules into a seperate Makefile for debugging or deploying software without dependency on ultimake









