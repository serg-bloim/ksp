CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/maneuvers.ks").
RUNONCEPATH("util/utils.ks").
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
print "Turn on SAS to start the rocket".
SAS OFF.
WAIT UNTIL SAS.
SAS OFF.
LOCK THROTTLE TO 1.0.
LOCK STEERING TO UP.
countdown(3).
local stage_cnt to 1.
for p in SHIP:PARTSTAGGED("stage_on_empty") {
    print "Staging part detected: " + p:NAME.
    local res is p:RESOURCES[0].
    local stage_iter to stage_cnt.
    set stage_cnt to stage_cnt + 1.
    WHEN res:AMOUNT = 0 THEN{
        print "Staging " + stage_iter.
        STAGE.
    }
}
STAGE.

set dir_east_10degree to ANGLEAXIS(-10,SHIP:UP:TOPVECTOR)*SHIP:UP.
local dst_apoapsis is 80000.

WAIT UNTIL VDOT(SHIP:VELOCITY:SURFACE, SHIP:UP:VECTOR) > 100.
PRINT "SPEED > 100 m/s".
LOCK STEERING TO dir_east_10degree.
WAIT UNTIL SHIP:ALTITUDE > 10000.
PRINT "ALTITUDE > 10k".
lock prograde_east to ANGLEAXIS(-VANG(SHIP:UP:VECTOR, SHIP:SRFPROGRADE:VECTOR),SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO prograde_east.
WAIT UNTIL VANG(SHIP:UP:VECTOR, SHIP:SRFPROGRADE:VECTOR) > 44.
PRINT "Angle attack = 45°".
set dir_east_45degree to ANGLEAXIS(-45,SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO dir_east_45degree.
WAIT UNTIL SHIP:ALTITUDE > 30000.
PRINT "ALTITUDE > 30k".
lock prograde_east to ANGLEAXIS(-VANG(SHIP:UP:VECTOR, SHIP:PROGRADE:VECTOR),SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO prograde_east.
WAIT UNTIL OBT:APOAPSIS > dst_apoapsis-100.
LOCK THROTTLE TO 0.01.
WAIT UNTIL OBT:APOAPSIS > dst_apoapsis.
LOCK THROTTLE TO 0.
print "Apoapsis reached!".
WAIT UNTIL SHIP:ALTITUDE > 70000.
print "We've got into space!".
IF OBT:APOAPSIS < dst_apoapsis {
    print "Correcting APOAPSIS".
    LOCK THROTTLE TO 0.01.
    WAIT UNTIL OBT:APOAPSIS > dst_apoapsis.
    LOCK THROTTLE TO 0.
}
set ut to TIMESTAMP() + SHIP:OBT:ETA:APOAPSIS.
set velocity_at_ap to VELOCITYAT(SHIP, ut):ORBIT:MAG.
set circular_obt_velocity to SQRT(BODY:MU/(BODY:RADIUS+OBT:APOAPSIS)).
set dv to circular_obt_velocity-velocity_at_ap.
print "velocity at AP: " + velocity_at_ap.
print "required velocity at AP: " + circular_obt_velocity.
print "DV: " + dv.
SET circular_obt to NODE(ut, 0, 0, dv ).
ADD circular_obt.
exec_node(circular_obt).
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "DONE".