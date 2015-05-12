
# Copyright (C) 2010--2014  Cesar Rodriguez <cesar.rodriguez@cs.ox.ac.uk>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

# traditional variables
#CFLAGS:=-Wall -Wextra -std=c99 -O3
#CFLAGS:=-Wall -Wextra -std=c99 -pg
CFLAGS:=-Wall -Wextra -std=c99 -g
#CFLAGS:=-Wall -Wextra -std=c99
CXXFLAGS:=-Wall -Wextra -std=c++11 -g -Wno-deprecated-declarations
CPPFLAGS:=-I src/ -D_POSIX_C_SOURCE=200809L -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS
LDFLAGS:=-dead_strip -lxerces-c
#LDFLAGS:=

# source code
#SRCS:=$(wildcard src/*.c src/*.cc src/*/*.c src/*/*.cc src/*/*/*.c src/*/*/*.cc)
SRCS:=$(filter-out %/cunf-mcc14.cc, $(SRCS))

# source code containing a main() function
#MSRCS:=$(wildcard src/mcc2cunf.cc)

# compilation targets
OBJS:=$(SRCS:.cc=.o)
OBJS:=$(OBJS:.c=.o)
MOBJS:=$(MSRCS:.cc=.o)
MOBJS:=$(MOBJS:.c=.o)
TARGETS:=$(MOBJS:.o=)

# dependency files
DEPS:=$(patsubst %.o,%.d,$(OBJS) $(MOBJS))

# define the toolchain
CROSS:=

LD:=$(CROSS)ld
CC:=$(CROSS)gcc
CXX:=$(CROSS)g++
CPP:=$(CROSS)cpp
LEX:=flex
YACC:=bison

%.d : %.c
	@echo "DEP $<"
	@set -e; $(CC) -MM -MT $*.o $(CFLAGS) $(CPPFLAGS) $< | \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' > $@;

%.d : %.cc
	@echo "DEP $<"
	@set -e; $(CXX) -MM -MT $*.o $(CXXFLAGS) $(CPPFLAGS) $< | \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' > $@;

%.o : %.c
	@echo "CC  $<"
	@$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

%.o : %.cc
	@echo "CXX $<"
	@$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

