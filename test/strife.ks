CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/utils.ks").
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Strife-test 2".
local body_c is SHIP:BODY:POSITION.

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
local wp1 is  WAYPOINT("Line-start").
local wp2 is  WAYPOINT("Lane-end").
lock p1 to wp1:POSITION.
lock p2 to wp2:POSITION.
local vecd is VECDRAW(p1,p2-p1, green, "dir", 1, true).
local vecd_norm is VECDRAW(V(0,0,0),V(0,0,0), red, "norm", 1, true).
//local my_facing_compass is compass(p2-p1).

LOCK vline TO p2-p1.
LOCK vline TO p1-p2.
local my_facing_compass is compass(vline).
local my_pitch is 0.
local my_roll is 0.
LOCAL vel_target IS 0.
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
local scale is 1.
set rollPID to PIDLOOP(
        0.3 * scale,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.001 * scale,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0.9 * scale,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -15,   // min possible throttle is zero.
                15    // max possible throttle is one.
        ).
set rollPID:SETPOINT to 0.
set velPID:SETPOINT to 1500.
SAS OFF.

local LOCK my_steering TO HEADING(my_facing_compass, my_pitch, my_roll).
local LOCK my_throttling TO 1.
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
local comp_line is compass(p2-p1).
until 0 {
    set prnt_n to 1.
    local vline is p2-p1.
    set vecd:start to p1.
    set vecd:vec to vline.
    local n is VCRS(vline,SHIP:BODY:POSITION - p1):NORMALIZED.
    local nup is VCRS(vline,n).
    local d is n * p1.
    set vecd_norm:vec to n*d.
    set my_roll to rollPID:UPDATE(TIME:SECONDS, d).
    set vel_target to velPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
    set pitchPID:SETPOINT to vel_target.
    set my_pitch to pitchPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
    prnt("DIST               ", d).
    prnt("my_facing_compass  ", my_facing_compass).
    prnt("my_pitch           ", my_pitch).
    prnt("my_roll            ", my_roll).
    prnt("vel_target         ", vel_target).
    prnt("").
//    prnt("Direction").
//    prnt("COMPASS LINE          ", comp_line).
//    prnt("COMPASS GOAL          ", round(comp_line,2) + " + " + round(afd,2) + " = " + (comp_line+afd)).
//    prnt("COMPASS SHIP FACING   ", comp_f + " / " + (comp_f - (comp_line+afd))).
//    prnt("COMPASS SHIP PROGRADE ", comp +   " / " + (comp - (comp_line+afd))).
//    prnt("COMPASS correction    ", afd).
//    prnt("my_heading            ", my_heading).
//    prnt("my_heading_diff       ", my_heading_diff).
//    prnt("").
//    prnt("Dest ground speed     ", dst_gnd_speed).
//    prnt("Dest alt              ", velPID:SETPOINT).
    wait 0.01.
}
print "Ready to end".
wait 9999999.