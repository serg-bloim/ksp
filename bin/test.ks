switch to 0.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/stages.ks").
RUNONCEPATH("0://util/maneuvers.ks").

CLEARSCREEN.

print "start".
// dbg(build_fuel_clusters()).
// local stages is get_stages().
// dbg("get_stages() = ").
// for s in stages{
//     dbg(lex2str(s)).
// }
wait until HASNODE.
print "got a node".
run "bin/nodexec.ks".
print "done".
