parameter autostart is false.
RUNONCEPATH("util/maneuvers.ks").
// #include "../util/utils.ks"
RUNONCEPATH("util/utils.ks").
// #include "../util/dbg.ks"
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
clearVecDraws().
local prograde_dir to 3.
local prograde_dirs to list("East", "South", "West","North").
local changing_prograde_dir to true.
ON RCS{
    if changing_prograde_dir {
        set prograde_dir to mod(prograde_dir + 1,prograde_dirs:length).
        print "Ready to lift rocket to the " + prograde_dirs[prograde_dir] at (0,2).
    }
    return changing_prograde_dir.
}
print "Turn on SAS to start the rocket".
toggle RCS.
wait until prograde_dir = 0.
SAS OFF.
if not autostart{
    WAIT UNTIL SAS.
}
CLEARSCREEN.
print "prograde_dir is " + prograde_dir + "(" +prograde_dirs[prograde_dir]+ ")".
local prograde_dirs to list(0, 90+13, 180, -90-13).
set prograde_dir to prograde_dirs[prograde_dir].
print "prograde_dir is " + prograde_dir.
set changing_prograde_dir to false.
local dirvector to ANGLEAXIS(prograde_dir,SHIP:UP:forevector) * north:forevector.
// show_vect(dirvector*5).
// show_vect(SHIP:UP:TOPVECTOR*10, green).
SAS OFF.
LOCK THROTTLE TO twr2throttle(3).
LOCK STEERING TO UP.
print("Launch in...").
countdown(3).
local stage_cnt to 1.
for p in SHIP:PARTSTAGGED("stage_on_empty") {
    print "Staging part detected: " + p:NAME.
    local res is p:RESOURCES[0].
    local stage_iter to stage_cnt.
    set stage_cnt to stage_cnt + 1.
    WHEN res:AMOUNT < 0.01 THEN{
        WAIT 0.1.
        print "Staging " + stage_iter.
        STAGE.
    }
}
STAGE.

set dir_east_10degree to ANGLEAXIS(-10,dirvector)*SHIP:UP.
local dst_apoapsis is 80000.

WAIT UNTIL VDOT(SHIP:VELOCITY:SURFACE, SHIP:UP:VECTOR) > 100.
PRINT "SPEED > 100 m/s".
LOCK STEERING TO dir_east_10degree.
WAIT UNTIL SHIP:ALTITUDE > 10000.
PRINT "ALTITUDE > 10k".
LOCK THROTTLE TO twr2throttle(2.87e-05 * SHIP:ALTITUDE + 0.95).
lock attack_angle to (-7.36E-3*SHIP:ALTITUDE*SHIP:ALTITUDE/1000000 + 1.84*SHIP:ALTITUDE/1000 + -8.1).
lock prograde_east to ANGLEAXIS(-attack_angle,dirvector)*SHIP:UP.
LOCK STEERING TO prograde_east.
//ON attack_angle{
//    print (round(attack_angle,2)) at (5,3).
//    return true.
//}
WAIT UNTIL SHIP:ALTITUDE > 30000.
PRINT "ALTITUDE > 30k".
SET NAVMODE to "ORBIT".
WAIT UNTIL OBT:APOAPSIS > dst_apoapsis-100.
declare local function gentle_throttle{
    local ap_gap is dst_apoapsis - OBT:APOAPSIS.
    local twr is 2.99e-05*ap_gap*ap_gap + 8.72e-03*ap_gap+0.0545.
    return twr2throttle(twr).
}
LOCK THROTTLE TO twr2throttle(0.3).
WAIT UNTIL OBT:APOAPSIS > dst_apoapsis.
LOCK THROTTLE TO 0.
print "Apoapsis reached!".
WAIT UNTIL SHIP:ALTITUDE > 60000.
LOCK STEERING TO ANGLEAXIS(-80,dirvector)*SHIP:UP.
print "We've got into space!".
IF OBT:APOAPSIS < dst_apoapsis {
    print "Correcting APOAPSIS".

    LOCK THROTTLE TO max(0.01,gentle_throttle()).
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