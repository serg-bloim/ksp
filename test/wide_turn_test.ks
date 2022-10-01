CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
// #include "../util/plane.ks"
RUNONCEPATH("util/plane.ks").
// #include "../util/utils.ks"
RUNONCEPATH("util/utils.ks").
// #include "../util/dbg.ks"
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Fly2point test ".
print angle_diff(100, 120).
wait until RCS.
local tests to list(
    list(359,0),
    list(0,0),
    list(30,0),
    list(90,0),
    list(180,1)
).
for test in tests{
    local angle to test[0].
    local dir to test[1].
    CLEARSCREEN.
    CLEARVECDRAWS().
    print "Test angle = " + angle + "°, dir = " + dir.
    local lock dirVec to angleAxis(angle, UP:forevector) * north:forevector.
    local dirVecDraw to vecDraw(v(0,0,0), dirVec*100, green, "goal",1,true).
    set dirVecDraw:vecupdater to {return dirVec*100.}.
    local facingDraw to vecDraw(v(0,0,0), facing:forevector*100, red, "facing",1,true).
    set facingDraw:vecupdater to {return vxcl(UP:forevector, srfPrograde:forevector):normalized*100.}.
    wide_turn(angle, dir).
    print "Turn is done".
    RCS OFF.
    wait until RCS.
}
wait until RCS.
print "Done".
wait 5.
wait 9999999.