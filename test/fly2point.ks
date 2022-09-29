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

wait until RCS.
local destination is vector_along_geo(V(0,0,0),facing:forevector, 10000).
local lock bc to SHIP:BODY:POSITION.
local rel_dst to destination - bc.

local p1vd to vecDraw(v(0,0,0), destination, red, "p1",1,true).
set p1vd:vecupdater to {local dst to bc + rel_dst. set p1vd:label to round(dst:mag):tostring(). return dst.}.
print "Flying to the point ahead".
fly2point(destination).
print "Done".
wait 3.
print "Flying to the point 30° right".
set destination to vector_along_geo(V(0,0,0),facing:forevector, 10000).
set destination to angleAxis(30, UP:forevector) * destination.
set rel_dst to destination - bc.
fly2point(destination).
print "Done".
wait 3.
print "Flying to the point 60° right".
set destination to vector_along_geo(V(0,0,0),facing:forevector, 10000).
set destination to angleAxis(60, UP:forevector) * destination.
set rel_dst to destination - bc.
fly2point(destination).
print "Done".
wait 3.
print "Flying to the point 90° right".
set destination to vector_along_geo(V(0,0,0),facing:forevector, 10000).
set destination to angleAxis(90, UP:forevector) * destination.
set rel_dst to destination - bc.
fly2point(destination).
print "Done".
wait 3.
print "Flying to the point 120° right".
set destination to vector_along_geo(V(0,0,0),facing:forevector, 10000).
set destination to angleAxis(120, UP:forevector) * destination.
set rel_dst to destination - bc.
fly2point(destination).
print "Done".
wait 5.
wait 9999999.