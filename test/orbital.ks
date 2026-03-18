RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/dir.ks").
RUNONCEPATH("0://util/func.ks").

UNTIL FALSE {
    function find_landing_time{
        PARAMETER T.
        local pos is POSITIONAT(SHIP, T).
        local _alt is (SHIP:BODY:POSITION - pos):MAG - SHIP:BODY:RADIUS.
        // print _alt.
        RETURN ABS(_alt).
    }
    local landing_ts is descend1d(find_landing_time@, NEXTNODE:TIME+10, 100, 1, 100).
    print "Landing in " + r2(landing_ts - NEXTNODE:TIME) + " s. at " + r2(landing_ts) + " s.".
    local landing is POSITIONAT(SHIP, landing_ts).
    CLEARVECDRAWS().
    show_vect(landing*1.5,"", red, SHIP:BODY:POSITION).
    WAIT 10.
}
