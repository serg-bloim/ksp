CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/utils.ks").
RUNONCEPATH("util/dbg.ks").
RUNONCEPATH("util/plane.ks").
// run "/test/strife.ks".
run "/test/wide_turn_test.ks".
// print 1/0.
CLEARSCREEN.
CLEARVECDRAWS().
print "Landing-test".
local body_c is SHIP:BODY:POSITION.

local wp1 is  WAYPOINT("Line-start").
local wp2 is  WAYPOINT("Lane-end").
local lock p1 to wp1:POSITION.
local lock p2 to wp2:POSITION.

print("Preparing for landing.").
prepare_landing(wp1, wp2).
print("Landing").

local vecd is VECDRAW(p1,p2-p1, green, "dir", 1, true).
local vecd_norm is VECDRAW(V(0,0,0),V(0,0,0), red, "norm", 1, true).

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
    parameter dir is FACING:VECTOR.
    return mod(360+vang2(NORTH:vector, VXCL(UP:VECTOR, dir)),360).
}

declare function angle_for_dist{
    parameter d.
    local adist is abs(d).
    if adist < 100{
        return 0.
    } else if adist > 1000{
        set d to d / adist * 1000.
    }
    return 7.387224919772421e-09 * d*d*d + -6.221663913591708e-14 * d*d + 0.007643792974183193 * d + 1.6131242240408006e-08.
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
                -50,   // min possible throttle is zero.
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
        1,   // adjust throttle 0.1 per 5m in error from desired altitude.
        0.1,  // adjust throttle 0.1 per second spent at 1m error in altitude.
        0.1,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
        -10,   // min possible throttle is zero.
        10    // max possible throttle is one.
        ).
set rollPID to PIDLOOP(
        0.3 ,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.001 ,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0.9 ,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -15,   // min possible throttle is zero.
                15    // max possible throttle is one.
        ).
set rollPID:SETPOINT to 0.
SAS OFF.

local lock my_steering to SHIP:FACING.
set my_throttling to 1.
lock my_pitch2 to 0.
local my_roll is 0.
set my_heading to compass(SRFPROGRADE:vector).
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
set stage_n to 1.
WHEN wp1:POSITION:MAG < 20000 THEN{
    set stage_n to 2.
    lock my_pitch2 to pitch.
}
WHEN wp1:POSITION:MAG < 10000 THEN{
    set stage_n to 3.
    set velPID:SETPOINT to dst_alt+50.
}
WHEN wp1:POSITION:MAG < 3000 THEN{
    set stage_n to 4.
    set velPID:SETPOINT to dst_alt+10.
    GEAR ON.
    BRAKES ON.
    SET dst_gnd_speed to 60.
    WHEN p1*SHIP:VELOCITY:SURFACE < 20 THEN{
        set stage_n to 5.
        set velPID:SETPOINT to dst_alt+1.
        SET THROTTLE to 0.
    }
}
local vel_target is 0.
local angle is 0.
local pitch is 0.
local logfile is "/log/flight2.log".
DELETEPATH(logfile).
log "   time,    alt, vspeed, hspeed,vtarget,  pitch, vsp_err" to logfile.
SET launchTime TO TIME:SECONDS.
LOCK missionClock TO (TIME:SECONDS - launchTime).
set prnt_n to 1.
declare function prnt{
    parameter lbl.
    parameter val is "".
    print (lbl + " : " + val + "                 ") at (1,prnt_n).
    set prnt_n to prnt_n+1.
}
local lock my_steering to HEADING(my_heading, my_pitch2, my_roll).
until 0 {
    set prnt_n to 1.
    local vline is p2-p1.
    set vecd:start to p1.
    set vecd:vec to vline.
    local n is VCRS(vline,SHIP:BODY:POSITION - p1):NORMALIZED.
    local nup is VCRS(vline,n).
    local d is n * p1.
    set vecd_norm:vec to n*d.
    local a is vang2(SHIP:FACING:VECTOR, vline).
    local comp_f is compass().
    local comp is compass(SRFPROGRADE:vector).
    local comp_line is compass(vline).
    local afd to angle_for_dist(d).
    if RCS{
        set vel_target to velPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
        set pitch to pitchPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
        set my_roll to rollPID:UPDATE(TIME:SECONDS, d).
        set my_throttling to spdPID:UPDATE(TIME:SECONDS, SHIP:GROUNDSPEED).
        set my_heading_diff to headingDiffPID:UPDATE(TIME:SECONDS, comp).
        set my_heading_diff to 0.
        set pitchPID:SETPOINT to vel_target.
        set spdPID:SETPOINT to dst_gnd_speed.
        set headingDiffPID:SETPOINT to comp_line + afd.
        set my_heading to comp_line + afd + my_heading_diff.
    }
    prnt("stage       ", stage_n).
    prnt("DIST        ", d).
    prnt("vel target  ", vel_target).
    prnt("pitch       ", pitch).
    prnt("").
    prnt("Direction").
    prnt("COMPASS LINE          ", comp_line).
    prnt("COMPASS GOAL          ", round(comp_line,2) + " + " + round(afd,2) + " = " + (comp_line+afd)).
    prnt("COMPASS SHIP FACING   ", comp_f + " / " + (comp_f - (comp_line+afd))).
    prnt("COMPASS SHIP PROGRADE ", comp +   " / " + (comp - (comp_line+afd))).
    prnt("COMPASS correction    ", afd).
    prnt("my_heading            ", my_heading).
    prnt("my_heading_diff       ", my_heading_diff).
    prnt("").
    prnt("Dest ground speed     ", dst_gnd_speed).
    prnt("Dest alt              ", velPID:SETPOINT).
    LOG round(missionClock,1):TOSTRING:PADLEFT(7)
            + "," + round(SHIP:ALTITUDE):TOSTRING:PADLEFT(7)
            +"," +round(SHIP:VERTICALSPEED,2):TOSTRING:PADLEFT(7)
            +"," +round(SHIP:GROUNDSPEED,2):TOSTRING:PADLEFT(7)
            +"," +round(vel_target,2):TOSTRING:PADLEFT(7)
            +"," +round(pitch,1):TOSTRING:PADLEFT(7)
            +"," +round(vel_target-SHIP:VERTICALSPEED,2):TOSTRING:PADLEFT(7)
            to logfile.
    wait 0.01.
}
//show_vect(n:NORMALIZED*10).
LOCK WHEELTHROTTLE TO 0.
print "Ready to end".
wait 9999999.