// CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
// #include "../util/plane.ks"
RUNONCEPATH("util/plane.ks").
// #include "../util/utils.ks"
RUNONCEPATH("util/utils.ks").
// #include "../util/dbg.ks"
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Precise turn test ".
declare function f{
    parameter x,y.
    print "arctan2(" +x+", "+y+") = " + arcTan2(x, y).
}
wait until RCS.
local tests to list(
    10,
    "10 10",
    20,
    30
).
for test in tests{
    local angle to 0.
    local pitch to 0.
    if test:ISTYPE("string") {
        local args to test:split(" ").
        set angle to args[0]:toScalar().
        if args:LENGTH > 1{
            set pitch to args[1]:toScalar().
        }
    }
    if test:ISTYPE("scalar") {
        set angle to test.
    }
    CLEARSCREEN.
    CLEARVECDRAWS().
    local current_comp to compass().
    print "Test angle = " + angle + "°. Pitch = " + pitch + "°.  Current compass: " + current_comp + "°, Dest: " + (current_comp+angle)+ "°".
    local lock dirVec to angleAxis(current_comp+angle, UP:forevector) * north:forevector.
    local dirVecDraw to vecDraw(v(0,0,0), dirVec*100, green, "goal",1,true).
    set dirVecDraw:vecupdater to {return dirVec*100.}.
    local facingDraw to vecDraw(v(0,0,0), facing:forevector*100, red, "facing",1,true).
    set facingDraw:vecupdater to {return vxcl(UP:forevector, facing:forevector):normalized*100.}.
    wait 5.
    precise_turn(current_comp+angle, pitch).
    print "Turn is done".
    RCS OFF.
    wait until RCS.
}
wait until RCS.
print "Done".
wait 5.
wait 9999999.