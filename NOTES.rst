Categories
==========

ReachabilityDeadlock
ReachabilityFireabilitySimple
ReachabilityFireability
.. ReachabilityCardinality


Notes for next year
===================

* Decide which categories you compete
* Extract files from the vm with::
  (ssh -p 2222 -i ... mcc@localhost tar c BenchKit/INPUTS) | tar xv
* Update the lists of models in doc:
  * models : all models
  * models-1 : first instance of every model
  * models-3 : first 3 instances of every model
* Adapt ``scripts/BenchKit_head.sh`` to run a dummy verification on your
  categories; read ``ToolSubmissionKit/READ_ME.pdf`` first.
* Adapt ``scripts/runit`` if necessary, and run a dummy execution on a couple
  of models
* Adapt BenchKit_head.sh to run cunf on deadlock for all models in doc/models-1
* Install on the machine with make vm_inst
* Run in the machine with scripts/vm_runit.sh
* Remove unnecessary files in the .tgz's with scripts/repack.sh, and then copy
  back the new .tgz's with ssh + tar
