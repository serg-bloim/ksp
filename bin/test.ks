switch to 0.
// CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

RUNONCEPATH("util/dbg.ks").
clearVecDraws().
print eta:apoapsis.
print SHIP:position.
local apPos is positionAt(SHIP, TIME+eta:apoapsis).
local pePos is positionAt(SHIP, TIME+eta:periapsis).
local apVec is positionAt(SHIP, TIME+eta:apoapsis) - BODY:position.
show_vect(apPos, "ap", red).
show_vect(pePos, "pe", green).
show_vect(apVec*2, "Apoapsis", blue, BODY:position).


run "bin/lifter.ks"(true).