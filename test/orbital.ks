RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/dir.ks").
RUNONCEPATH("0://util/orb.ks").
print "Hello".

until FALSE {
    lock myOrb to SHIP:ORBIT.
    CLEARVECDRAWS().
    // show_rot(getOrbitPeDir(myOrb), myOrb:BODY:POSITION).
    // local tu is angleBetweenDirs(getOrbitPeDir(myOrb), getOrbitableDirection(SHIP)).
    // print "getOrbRadiusByDir() = " + getOrbRadiusByDir(myOrb, -myOrb:BODY:POSITION) + " getOrbAltByDir=" + getOrbAltByDir(myOrb, -myOrb:BODY:POSITION).
    // local poss is LIST().
    // FROM {local i is 1.} UNTIL i >1 STEP {set i to i + 1.} DO {
    //     poss:ADD(POSITIONAT(SHIP, TIME:SECONDS + SHIP:ORBIT:ETA:PERIAPSIS + 100* i * SHIP:ORBIT:PERIOD)).
    //     print i.
    // }
    local time_in_1orb is TIME:SECONDS + 1 * SHIP:ORBIT:PERIOD.
    local time_in_1000orb is TIME:SECONDS + 1000 * SHIP:ORBIT:PERIOD.
    local pos_in_1_orbs is POSITIONAT(SHIP, time_in_1orb).
    local pos_in_1000_orbs is POSITIONAT(SHIP, time_in_1000orb).
    print pos_in_1_orbs.
    print pos_in_1000_orbs.
    print "dist = " + (pos_in_1000_orbs - pos_in_1_orbs):MAG.

    VECDRAW(V(0,0,0), pos_in_1000_orbs, red, "", 1, true).
    // for p in poss {
        // show_vect(p).
    //             print p.
    // }
    // print angleBetweenDirs(shipDir, anDir).
    // print angleBetweenDirs(anDir, shipDir).
    wait 2.
}

