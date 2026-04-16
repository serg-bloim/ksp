RUNONCEPATH("0://app/docking.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/dock.ks").
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/dbg.ks").

//for p in SHIP:PARTS {
//    dbg("PART: " + p:NAME + " | tag: " + p:TAG).
//    for mod_name in p:MODULES {
//        dbg("  MODULE: " + mod_name).
//    }
//}
print "Start".
local time_till_target_available is measure_time({
    WAIT UNTIL HASTARGET.
}).
print "Time till target available: " + time_till_target_available + "s".
create_dock_app():setters
    :dock2target(TARGET)
    :indicate_ports(TRUE)
    :app():run().


print "end".