#!/usr/bin/env python
"""
Usage:
  mcc15-helper.py pnml2pep PNML LL_NET
  mcc15-helper.py xml2cunf XML CUNF
"""

import sys
import ptnet
import mcc15

def pnml2pep () :
    fin = open (sys.argv[2], 'r')
    fout = open (sys.argv[3], 'w')

    n = ptnet.Net ()
    n.read (fin, 'pnml')

    for t in n.trans :
        t.name = t.tid
        for x in t.weight_pre.values () :
            assert x <= 1, "Transition '%s' with weight != 1" % repr (t)
        for x in t.weight_post.values () :
            assert x <= 1, "Transition '%s' with weight != 1" % repr (t)

    n.plain2cont ()
    n.write (fout, 'll_net')

def xml2cunf () :
    fout = open (sys.argv[3], 'w')

    formulas = mcc15.Formula.read (sys.argv[2], None, fmt='mcc15')
    for f in formulas :
        print f
        f.write (fout, 'cunf')
    fout.close ()

def main () :
    assert len (sys.argv) == 4, "4 arguments expected"
    if sys.argv[1] == "pnml2pep" :
        pnml2pep ()
    elif sys.argv[1] == "xml2cunf" :
        xml2cunf ()
    else :
        assert False, "Unexpected command '%s'" % sys.argv[1]
    sys.exit (0)

if __name__ == '__main__' :
    main ()
    sys.exit (0)
    try :
        main ()
        sys.exit (0)
    except Exception as e :
        print 'mcc15-helper: error: %s' % str (e)
        sys.exit (1)

# vi:ts=4:sw=4:et:
