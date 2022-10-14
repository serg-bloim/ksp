// #include "../util/plane.ks"
RUNONCEPATH("util/plane.ks").
// #include "../util/utils.ks"
RUNONCEPATH("util/utils.ks").
// #include "../util/dbg.ks"
RUNONCEPATH("util/dbg.ks").

print "Circling around".
RCS ON.
SAS OFF.
local rollPID to PIDLOOP(
        0.01,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.000001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0.003,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -0.3,   // min possible throttle is zero.
                0.3    // max possible throttle is one.
        ).
set rollPID:SETPOINT to 0.
local rollAnglePID to PIDLOOP(
        2,   // adjust throttle 0.1 per 5m in error from desired altitude.
               0.5,  // adjust throttle 0.1 per second spent at 1m error in altitude.
              0.3,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                0,   // min possible throttle is zero.
                85    // max possible throttle is one.
        ).
set rollAnglePID:setpoint to 0.
set rollPID:SETPOINT to 0.
set ship:control:pitch to 0.5.
local dst_alt to 8000.
until 0 {
    set prnt_n to 10.
    local actual_roll to horizon_roll().
    local vert_acc to ship:sensors:acc * up:vector.
    local da to dst_alt - ship:altitude.
    local dst_vvel to da / 5.
    local dv to dst_vvel - ship:verticalspeed.
    local dst_vacc to dv / 5.
    local dvacc to dst_vacc - vert_acc.
    set rollAnglePID:setpoint to dst_vacc.
    local dstAngle to 90-rollAnglePID:update(time:seconds, vert_acc).
    set rollPID:SETPOINT to dstAngle.
    local roll to rollPID:update(time:seconds, actual_roll).
    set ship:control:roll to roll.
    prnt("dst_alt      ", dst_alt).
    prnt("alt          ", ship:altitude).
    prnt("dst_vvel     ", dst_vvel).
    prnt("vspeed       ", ship:verticalspeed).
    prnt("dst_vacc     ", dst_vacc).
    prnt("vert_acc     ", vert_acc).
    prnt("actual_roll  ", actual_roll).
    prnt("dstAngle     ", dstAngle).
    prnt("roll         ", roll).

    if SAS{
        break.
    }
    wait 0.01.
}
SAS ON.