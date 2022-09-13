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
set stage1res to SHIP:PARTSDUBBED("stage4.booster")[0]:RESOURCES[0].
set stage2res to SHIP:PARTSDUBBED("stage3.tank")[0]:RESOURCES[0].
STAGE.

WHEN stage1res:AMOUNT = 0 THEN{
    print "Stage 1 done".
    STAGE.
}

WHEN stage2res:AMOUNT = 0 THEN{
    print "Stage 2 done".
    STAGE.
}

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
PRINT "Angle attach = 45°".
set dir_east_45degree to ANGLEAXIS(-45,SHIP:UP:TOPVECTOR)*SHIP:UP.
LOCK STEERING TO dir_east_45degree.
WAIT UNTIL SHIP:ALTITUDE > 30000.
LOCK STEERING TO prograde_east.
WAIT UNTIL SHIP:ALTITUDE > 70000.

print "We've got into space!".