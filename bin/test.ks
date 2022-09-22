RUNONCEPATH("/util/utils.ks").
CLEARSCREEN.
declare local function gentle_throttle{
    local ap_gap is dst_apoapsis - OBT:APOAPSIS.
    print(ap_gap) at (5,5).
    local twr is 2.99e-05*ap_gap*ap_gap + 8.72e-03*ap_gap+0.0545.
    print(twr) at (5,6).
    local thr to twr2throttle(twr).
    print(thr) at (5,7).
    return thr.
}
local dst_apoapsis is 80000.
print "Apoapsis reached!".
WAIT UNTIL SHIP:ALTITUDE > 70000.
LOCK STEERING TO ANGLEAXIS(-80,SHIP:UP:TOPVECTOR)*SHIP:UP.
print "We've got into space!".
IF OBT:APOAPSIS < dst_apoapsis {
    print "Correcting APOAPSIS".

    LOCK THROTTLE TO max(0.01,gentle_throttle()).
    WAIT UNTIL OBT:APOAPSIS > dst_apoapsis.
    LOCK THROTTLE TO 0.
}