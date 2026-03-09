RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/dir.ks").
RUNONCEPATH("0://util/orb.ks").
print "Hello".

until FALSE {
    CLEARVECDRAWS().
    local myOrb is SHIP:ORBIT.
    local trgOrb is TARGET:ORBIT.
    local mag is myOrb:BODY:RADIUS * 2.
    local myOrbNorm is getOrbitNormal(myOrb).
    local trgOrbNorm is getOrbitNormal(trgOrb).
    local anDir is getAscendingNodeDirection(myOrb, trgOrb).
    local shipDir is getOrbitableDirection(SHIP).
    // show_vect(myOrbNorm * mag, "SHIP", red, myOrb:BODY:POSITION).
    // show_vect(trgOrbNorm * mag, "TRG", green, myOrb:BODY:POSITION).
    // show_vect(anDir:FOREVECTOR * mag, "AN", red, myOrb:BODY:POSITION).
    show_rot(shipDir, myOrb:BODY:POSITION).
    show_rot(anDir, myOrb:BODY:POSITION).
    local ship2an is anDir * shipDir:inverse.
    print ship2an.
    print angleBetweenDirs(shipDir, anDir).
    // print angleBetweenDirs(anDir, shipDir).
    wait 0.5.
}

