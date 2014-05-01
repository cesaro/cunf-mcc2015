cunf-mcc2014
============

Preparing the Cunf Tool to participate in the Model Checking Contest 2014

Subset that will be translated
------------------------------

F ::=
    impossible (deadlock)
  | invariant (B)
  | possible (B)
  | B

B ::=
    is-firable (t_1, ..., t_n)
  | B and B
  | B or B

Translation into Cunf's specification format
--------------------------------------------

tr[ impossible (deadlock) ]       = ! deadlock
tr[ invariant (B) ]               = tr[B]
tr[ possible (B) ]                = tr[B] (negation of)

tr[ is-firable (t_1, ..., t_n) ]  = t_1 v ... v t_n
tr[ B1 and B2 ]                   = ( tr[B1] ) ^ ( tr[B2] )
tr[ B1 or B2 ]                    = tr[B1] v tr[B2]

????
----
 - if there is two properties in a file, and one is a negation of the
   other, can I just return the opposite value and run no verification?

ReachabilityDeadlock.xml
---------------------
   imp (deadlock)
   possible (deadlock)

ReachabilityFireabilitySimple.xml
---------------------------------
   possible (firable (t1))

ReachabilityFireability.xml
----------------
   imp (firable (t))
   inv (firable (t))

