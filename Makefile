
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

gen :
	xsd cxx-tree \
		--generate-serialization  --generate-doxygen --generate-ostream \
		--generate-comparison  --generate-detach \
		--generate-default-ctor --generate-polymorphic \
		--polymorphic-type-all \
		--namespace-map http://mcc.lip6.fr=mcc  \
		--output-dir src/ --root-element property-set \
		--namespace-map 'http://mcc.lip6.fr/=mcc' \
		doc/mcc-properties.xsd
	mv src/mcc-properties.cxx src/mcc-properties.cc
	mv src/mcc-properties.hxx src/mcc-properties.hh

R=/tmp/BenchKit
C=~/x/devel/cunf
P=~/x/devel/pncat

inst : $(TARGETS) $R
	rm -Rf $R/bin/
	mkdir $R/bin/
	cp scripts/BenchKit_head.sh $R
	cd $C; make src/cunf/cunf
	cp $C/src/cunf/cunf $R/bin
	cp $C/tools/cont2pr.pl $R/bin
	cp scripts/pnml2pep_mcc15.py $R/bin
	cp -R $P/src/{mcc15,pncat,ptnet} $R/bin

fix_namespaces:
	rm -Rf $B/INPUTS/tmp
	mkdir $B/INPUTS/tmp
	cd $B/INPUTS/tmp; \
	set -x; \
	for i in ../*.tgz; do \
		tar xzvf $$i; \
		for j in */*xml; do ~/devel/cunf-mcc2014/mcc14fixnamespace $$j; done; \
		tar czvf $$i *; \
		rm -R $B/INPUTS/tmp/*; \
	done; \
	rm -R $B/INPUTS/tmp

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

