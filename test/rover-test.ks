//CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/utils.ks").
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
BRAKES ON.
print "Landing-test".
local body_c is SHIP:BODY:POSITION.

local wp1 is  WAYPOINT("1").
local wp2 is  WAYPOINT("2").
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
    parameter dir is FACING:VECTOR.
    return mod(360+vang2(NORTH:vector, VXCL(UP:VECTOR, dir)),360).
}
BRAKES OFF.
local wp_start is WAYPOINT("start").
if wp_start:position:mag > 70 and RCS{
    lock WHEELSTEERING to wp_start:GEOPOSITION.
    lock WHEELTHROTTLE to 1.
    wait until wp_start:POSITION:MAG < 50.
    lock WHEELSTEERING to wp1:GEOPOSITION.
    unlock WHEELTHROTTLE.
    BRAKES ON.
    wait until GROUNDSPEED < 0.01.
    unlock WHEELSTEERING.
}

declare function angle_for_dist{
    parameter dist.
    local adist is abs(dist).
    if adist < 1{
        return 0.
    } else if adist > 200{
        set dist to dist / adist * 200.
    }
    return - dist / 200 * 45.
}
set anglePID to PIDLOOP(
        0.1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.03,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0.1,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -45,   // min possible throttle is zero.
                45    // max possible throttle is one.
        ).
set anglePID:SETPOINT to 0.
SAS OFF.
WAIT UNTIL SAS.
SAS OFF.
lock WHEELTHROTTLE to 1.
local angle is 0.
until 0 {
    local vline is p2-p1.
    set vecd:start to p1.
    set vecd:vec to vline.
    local n is VCRS(vline,SHIP:BODY:POSITION - p1):NORMALIZED.
    local nup is VCRS(vline,n).
    local d is -n * p1.
    local a is vang2(SHIP:FACING:VECTOR, vline).
    local comp is compass().
    local comp_line is compass(vline).
    print ("N    : " + n) at (1,2).
    print ("DIST : " + d) at (1,3).
    print ("p1   : " + p1) at (1,4).
    print ("p2   : " + p2) at (1,5).
//    set angle to anglePID:UPDATE(TIME:SECONDS, d).
    lock WHEELSTEERING to comp_line + angle_for_dist(d).
    print ("angle: " + angle) at (1,7).
    print ("COMPASS SHIP: " + comp) at (1,8).
    print ("COMPASS LINE: " + comp_line) at (1,9).
    print ("COMPASS delta   : " + (comp - comp_line)) at (1,10).
    print ("COMPASS correction   : " + angle_for_dist(d)) at (1,11).

    wait 0.1.
}
//show_vect(n:NORMALIZED*10).
LOCK WHEELTHROTTLE TO 0.
print "Ready to end".
wait 9999999.