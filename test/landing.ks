RUNONCEPATH("util/rcs.ks").
RUNONCEPATH("0://util/dock.ks").
RUNONCEPATH("0://util/dbg.ks").

WAIT UNTIL HASTARGET.
rcs_stop_relative_to_target(TARGET, 3, log_only_main).
print 123.