// CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
// #include "../util/plane.ks"
RUNONCEPATH("util/plane.ks").
// #include "../util/utils.ks"
RUNONCEPATH("util/utils.ks").
// #include "../util/dbg.ks"
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Full turn test".
flight_log("Full turn test").
wait until RCS.
local tests to list(
    // 0,
    heading(compass()+90, 0):forevector*10000,
    "20 -1",
    20,
    30
).
for test in tests{
    local angle to 0.
    local dir to 0.
    local pitch to 0.
    local dst to 0.
    local current_comp to compass().
    local relDst to angle.
    if test:ISTYPE("string") {
        local args to test:split(" ").
        set angle to args[0]:toScalar().
        if args:LENGTH > 1{
            set dir to args[1]:toScalar().
        }
        if args:LENGTH > 2{
            set pitch to args[2]:toScalar().
        }
    }
    if test:ISTYPE("scalar") {
        set angle to test.
        set dst to current_comp+angle.
    }
    if test:ISTYPE("vector") {
        set angle to test.
        set dst to angle.
        set relDst to dst - ship:body:position.
    }
    CLEARSCREEN.
    CLEARVECDRAWS().
    flight_log( "Test angle = " + angle + "°. Direction = " + dir + "°.  Current compass: " + current_comp + "°, Dest: " + (dst)+ "°").
    local lock dirVec to choose relDst + ship:body:position if test:ISTYPE("vector") else angleAxis(dst, UP:forevector) * north:forevector.
    local dirVecDraw to vecDraw(v(0,0,0), dirVec*100, green, "goal",1,true).
    set dirVecDraw:vecupdater to {return dirVec*100.}.
    local facingDraw to vecDraw(v(0,0,0), facing:forevector*100, red, "facing",1,true).
    set facingDraw:vecupdater to {return vxcl(UP:forevector, facing:forevector):normalized*100.}.
    turn(dst, dir, pitch).
    flight_log( "Turn is done").
    RCS OFF.
    SAS ON.
    wait until RCS.
}
wait until RCS.
flight_log( "Done").
wait 5.
wait 9999999.