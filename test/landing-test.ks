CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/utils.ks").
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Landing-test".
local body_c is SHIP:BODY:POSITION.

local wp1 is  WAYPOINT("Line-start").
local wp2 is  WAYPOINT("Lane-end").
lock p1 to wp1:POSITION.
lock p2 to wp2:POSITION.
local vecd is VECDRAW(p1,p2-p1, green, "dir", 1, true).

declare function vang2{
    parameter v1.
    parameter v2.
    local res is vang(v1, v2).
    if vang(UP:VECTOR, VCRS(v1, v2)) > 90{
        set res to - res.
    }
    return res.
}
declare function compass{
//    parameter dir is FACING:VECTOR.
//    parameter origin is V(0,0,0).
//    return mod(360+vang2(NORTH:vector, VXCL(ORIGIN - BODY:POSITION, dir)),360).
    parameter dir is FACING:VECTOR.
    return mod(360+vang2(NORTH:vector, VXCL(UP:VECTOR, dir)),360).
}

declare function angle_for_dist{
    parameter d.
    local adist is abs(d).
    if adist < 1{
        return 0.
    } else if adist > 1000{
        set d to d / adist * 1000.
    }
//    0.0132 + -0.0103x + -3.47E-07x^2 + -3.68E-08x^3
    return 0.0132 -0.0103 * d -3.47E-07*d*d -3.68E-08*d*d*d.
}
set pitchPID to PIDLOOP(
        1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.3,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0.01,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -10,   // min possible throttle is zero.
                15    // max possible throttle is one.
        ).
set velPID to PIDLOOP(
        0.1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -30,   // min possible throttle is zero.
                50    // max possible throttle is one.
        ).
set spdPID to PIDLOOP(
        0.1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                0,   // min possible throttle is zero.
                1    // max possible throttle is one.
        ).
set headingDiffPID to PIDLOOP(
        0.1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -10,   // min possible throttle is zero.
                10    // max possible throttle is one.
        ).

SAS OFF.

lock my_steering to SHIP:FACING.
set my_throttling to 1.
lock my_pitch to 0.
RCS ON.
if RCS{
    lock steering to my_steering.
    LOCK THROTTLE to my_throttling.
}
ON RCS{
    IF RCS{
        SAS OFF.
        lock steering to my_steering.
        LOCK THROTTLE to my_throttling.
    } else{
        SAS ON.
        unlock steering.
        unlock THROTTLE.
    }
    PRESERVE.
}
local dst_alt is wp1:ALTITUDE-5.
set velPID:SETPOINT to dst_alt+500.
set dst_gnd_speed to 500.
print ("stage 1") at (20,1).
WHEN wp1:POSITION:MAG < 20000 THEN{
    print ("stage 2") at (20,1).
    SET dst_gnd_speed to 200.
    lock my_pitch to pitch.
}
WHEN wp1:POSITION:MAG < 10000 THEN{
    print ("stage 3") at (20,1).
    SET dst_gnd_speed to 80.
    set velPID:SETPOINT to dst_alt+50.
}
WHEN wp1:POSITION:MAG < 2000 THEN{
    print ("stage 4") at (20,1).
    set velPID:SETPOINT to dst_alt+10.
    GEAR ON.
    BRAKES ON.
    SET dst_gnd_speed to 60.
}
WHEN vxcl(UP:VECTOR, wp1:POSITION):MAG < 20 THEN{
    print ("stage 5") at (20,1).
    set velPID:SETPOINT to dst_alt+1.
    SET THROTTLE to 0.
}
local vel_target is 0.
local angle is 0.
local pitch is 0.
local logfile is "/log/flight2.log".
DELETEPATH(logfile).
log "   time,    alt, vspeed, hspeed,vtarget,  pitch, vsp_err" to logfile.
SET launchTime TO TIME:SECONDS.
LOCK missionClock TO (TIME:SECONDS - launchTime).
until 0 {
    if RCS{
        set vel_target to velPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
        set pitch to pitchPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
        set my_throttling to spdPID:UPDATE(TIME:SECONDS, SHIP:GROUNDSPEED).
        set pitchPID:SETPOINT to vel_target.
        set spdPID:SETPOINT to dst_gnd_speed.
    }
    local vline is p2-p1.
    set vecd:start to p1.
    set vecd:vec to vline.
    local n is VCRS(vline,SHIP:BODY:POSITION - p1):NORMALIZED.
    local nup is VCRS(vline,n).
    local d is -n * p1.
    local a is vang2(SHIP:FACING:VECTOR, vline).
    local comp is compass(SRFPROGRADE:vector).
    local comp_line is compass(vline).
    print ("DIST : " + (d:TOSTRING) + "                      ") at (1,3).
    print ("vel target : " + (vel_target:TOSTRING) + "         ") at (1,4).
    print ("pitch      : " + (pitch:TOSTRING) + "              ") at (1,5).

    lock my_steering to HEADING(comp_line + angle_for_dist(d), my_pitch).
    print ("angle: " + angle + "                      ") at (1,7).
    print ("COMPASS SHIP: " + ROUND(comp,2) + " " + round(compass(SRFPROGRADE:vector),2)) at (1,8).
    print ("COMPASS LINE: " + comp_line + "                      ") at (1,9).
    print ("COMPASS delta   : " + (comp - comp_line) + "                      ") at (1,10).
    print ("COMPASS correction   : " + angle_for_dist(d) + "                      ") at (1,11).
    print ("SHIP:GROUNDSPEED     : " + SHIP:GROUNDSPEED + "                      ") at (1,12).
    print ("dst_gnd_speed        : " + dst_gnd_speed + "                      ") at (1,12).
    print ("my_throttling        : " + my_throttling + "                      ") at (1,13).
    print ("dst_alt              : " + velPID:SETPOINT + "                      ") at (1,13).
    LOG round(missionClock,1):TOSTRING:PADLEFT(7)
            + "," + round(SHIP:ALTITUDE):TOSTRING:PADLEFT(7)
            +"," +round(SHIP:VERTICALSPEED,2):TOSTRING:PADLEFT(7)
            +"," +round(SHIP:GROUNDSPEED,2):TOSTRING:PADLEFT(7)
            +"," +round(vel_target,2):TOSTRING:PADLEFT(7)
            +"," +round(pitch,1):TOSTRING:PADLEFT(7)
            +"," +round(vel_target-SHIP:VERTICALSPEED,2):TOSTRING:PADLEFT(7)
            to logfile.
    wait 0.1.
}
//show_vect(n:NORMALIZED*10).
LOCK WHEELTHROTTLE TO 0.
print "Ready to end".
wait 9999999.