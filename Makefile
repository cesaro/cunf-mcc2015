
# Copyright (C) 2010-2014  Cesar Rodriguez <cesar.rodriguez@cs.ox.ac.uk>
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

include defs.mk

.PHONY: fake all g test clean distclean prof dist inst

all: $(TARGETS) tags inst
	#./scripts/runit

$(TARGETS) : % : %.o $(OBJS)
	@echo "LD  $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) 

ssh :
	ssh -v -i ToolSubmissionKit/bk-private_key mcc@localhost -p2222

# so testing in Mac and in the real machine behaves the same!
R=~/BenchKit
C=~/x/devel/cunf
P=~/x/devel/pncat

inst : $(TARGETS) $R
	rm -Rf $R/bin/
	mkdir $R/bin/
	cp scripts/BenchKit_head.sh $R
	#cd $C; make src/cunf/cunf
	cp $C/src/cunf/cunf $R/bin
	cp $C/tools/cont2pr.pl $R/bin
	cp scripts/mcc15-helper.py $R/bin
	cp scripts/repack.sh $R/bin
	cp -R $P/src/{mcc15,pncat,ptnet} $R/bin

K=ToolSubmissionKit/bk-private_key
vm_inst : inst
	echo hello world
	ssh -i $K mcc@localhost -p2222 rm -rf BenchKit/{bin,BenchKit_head.sh}
	(cd $R; tar c BenchKit_head.sh bin) | \
		ssh -i $K mcc@localhost -p2222 "cd BenchKit; tar x -m"
	ssh -i $K mcc@localhost -p2222 "find BenchKit | grep -v INPUTS | xargs ls -ld"


tags : $(SRCS)
	ctags -R src

vars :
	@echo CC $(CC)
	@echo CXX $(CXX)
	@echo SRCS $(SRCS)
	@echo MSRCS $(MSRCS)
	@echo OBJS $(OBJS)
	@echo MOBJS $(MOBJS)
	@echo TARGETS $(TARGETS)
	@echo DEPS $(DEPS)

clean :
	@rm -f $(TARGETS) $(MOBJS) $(OBJS)
	@rm -f src/cna/spec_lexer.cc src/cna/spec_parser.cc src/cna/spec_parser.h
	@echo Cleaning done.

distclean : clean
	@rm -f $(DEPS)
	@echo Mr. Proper done.

-include $(DEPS)

