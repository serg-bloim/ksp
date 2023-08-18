switch to 0.
// CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/stages.ks").
RUNONCEPATH("0://util/maneuvers.ks").

CLEARSCREEN.

// for s in get_stages(){
//     print_lex(s).
// }

// if HASNODE
//     if exec_node(NEXTNODE)
//         print "Success".
//     else
//         print "Cannot execute the maneuver".
        
run "bin/lifter.ks".
