function get_ETA_AN_or_DN{
    PARAMETER trgOrb.
    local f_criteria to {
        PARAMETER T.
        local shipDir is getOrbitableDirection(SHIP).
        local anDir is getAscendingNodeDirection(SHIP:ORBIT, trgOrb).
        local angle2AN is angleBetweenDirs(shipDir, anDir).
        print "angle2AN: " + angle2AN.
        local andnVec is anDir:FOREVECTOR.
        IF angle2AN > 190{
            set angle2AN to angle2AN - 180.
            set andnVec to -andnVec.
        }
        local pos is POSITIONAT(SHIP, T) - SHIP:BODY:POSITION.
        RETURN VANG(pos, andnVec).
    }.
    return bisect_search(f_criteria, 0, 0.01, TIME:SECONDS, 1, 50).
}