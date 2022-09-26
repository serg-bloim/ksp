CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
RUNONCEPATH("util/plane.ks").
RUNONCEPATH("util/dbg.ks").
CLEARSCREEN.
CLEARVECDRAWS().
print "Fly2point test ".

wait until RCS.
SAS OFF.

print ("Wide turn to 90").
wide_turn(90, 1).
wait 10.
print ("Wide turn to 180").
wide_turn(180, 1).
print ("In direction of 180").

local wp1 is  WAYPOINT("Line-start").
local wp2 is  WAYPOINT("Lane-end").
lock p1 to wp1:POSITION.
lock p2 to wp2:POSITION.
lock soi to SHIP:BODY:POSITION.
local vd1 is VECDRAW(p1,(p2-p1), green, "", 1, true).
lock c to vector_along_geo(p1, p1-p2, 30e3, 1000).
local vd2 is VECDRAW(p1,(c-p1), blue, "", 1, true).
lock norm to VCRS(p1-soi,p2-soi).
lock c1 to vector_along_geo(c, norm, 10e3).
lock c2 to vector_along_geo(c, -norm, 10e3).
local vd3 is VECDRAW(c,(c1-c), red, "c1", 1, true).
local vd4 is VECDRAW(c,(c2-c), red, "c2", 1, true).
ON c{
    set vd1:START to p1.
    set vd1:VEC to p2-p1.

    set vd2:START to p1.
    set vd2:VEC to c-p1.

    set vd3:START to c.
    set vd3:VEC to c1-c.

    set vd4:START to c.
    set vd4:VEC to c2-c.
    print(norm) at(10,10).
    PRESERVE.
}
RCS OFF.
wait until RCS.
print ("Flying to C1").
//fly2point(c1).
LOCK STEERING to c1.
LOCK THROTTLE to 1.
wait until c1:MAG < 1000.
unlock STEERING.
unlock THROTTLE.
SAS ON.
KUniverse:PAUSE().
print ("Near C1").
wide_turn(compass(p1), 1).
print ("In direction of p1").
//until 0 {
//    set arrow to rot * arrow.
//    set clock:vec to arrow.
//    wait 0.5.
//}
//show_vect()
print "Ready to end".
wait 9999999.