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
print("Launch in...").
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
lock attack_angle to (0.00001163*SHIP:ALTITUDE*SHIP:ALTITUDE + 0.3531*SHIP:ALTITUDE + 3766)/1000.
lock prograde_east to ANGLEAXIS(-attack_angle,SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO prograde_east.
WAIT UNTIL SHIP:ALTITUDE > 30000.
PRINT "ALTITUDE > 30k".
SET NAVMODE to "ORBIT".
WAIT UNTIL OBT:APOAPSIS > dst_apoapsis-100.
LOCK THROTTLE TO 0.01.
WAIT UNTIL OBT:APOAPSIS > dst_apoapsis.
LOCK THROTTLE TO 0.
print "Apoapsis reached!".
WAIT UNTIL SHIP:ALTITUDE > 70000.
LOCK STEERING TO ANGLEAXIS(-85,SHIP:UP:TOPVECTOR)*SHIP:UP.
print "We've got into space!".
IF OBT:APOAPSIS < dst_apoapsis {
    print "Correcting APOAPSIS".
    declare local function gentle_throttle{
        local ap_gap is dst_apoapsis - OBT:APOAPSIS.
        local r is SHIP:ALTITUDE+SHIP:BODY:RADIUS.
        local weight is SHIP:MASS * SHIP:BODY:MU / r / r.
        local twr is 0.0000116*ap_gap*ap_gap + 0.0038106*ap_gap+0.0033326.
        local thrust is twr * weight.
        return thrust / SHIP:MAXTHRUST.
    }
    LOCK THROTTLE TO gentle_throttle().
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
SAS ON.
print "DONE".