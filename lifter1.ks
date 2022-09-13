CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/utils.ks").
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
print "Turn on SAS to start the rocket".
SAS OFF.
//WAIT UNTIL SAS.
//SAS OFF.
LOCK THROTTLE TO 1.0.
LOCK STEERING TO UP.
//countdown(3).
local stage_cnt to 1.
for p in SHIP:PARTSTAGGED("stage_on_empty"){
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

ON SHIP:SRFPROGRADE {
    CLEARVECDRAWS().
    show_rot(SHIP:SRFPROGRADE).
    return true.
}
set dir_east_10degree to ANGLEAXIS(-10,SHIP:UP:TOPVECTOR)*SHIP:UP.
show_rot(SHIP:UP).
show_rot(dir_east_10degree).


WAIT UNTIL VDOT(SHIP:VELOCITY:SURFACE, SHIP:UP:VECTOR) > 100.
PRINT "SPEED > 100 m/s".
LOCK STEERING TO dir_east_10degree.
WAIT UNTIL SHIP:ALTITUDE > 10000.
PRINT "ALTITUDE > 10000".
lock prograde_east to ANGLEAXIS(-VANG(SHIP:UP:VECTOR, SHIP:SRFPROGRADE:VECTOR),SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO prograde_east.
WAIT UNTIL VANG(SHIP:UP:VECTOR, SHIP:SRFPROGRADE:VECTOR) > 44.
PRINT "Angle attack = 45°".
set dir_east_45degree to ANGLEAXIS(-45,SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO dir_east_45degree.
WAIT UNTIL SHIP:ALTITUDE > 30000.
lock prograde_east to ANGLEAXIS(-VANG(SHIP:UP:VECTOR, SHIP:PROGRADE:VECTOR),SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO prograde_east.
WAIT UNTIL SHIP:ORBIT:APOAPSIS > 80000.
LOCK THROTTLE TO 0.
print "Apoapsis reached!".
print "We've got into space!".
