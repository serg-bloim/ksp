CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
// #include "../util/plane.ks"
RUNONCEPATH("util/plane.ks").
// #include "../util/dbg.ks"
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Fly2point test ".

SAS OFF.
wait until RCS.
local p1 is vector_along_geo(V(0,0,0),compass()+90, 1E3).
local lock bc to SHIP:BODY:POSITION.
local rel_dst is dst - bc.
local lock dst2 to bc + rel_dst.

fly2point(p1).
wait 9999999.