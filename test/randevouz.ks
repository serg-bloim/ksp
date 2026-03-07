parameter autostart is false.
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/orb.ks").
declare function do_randevouz{
    RCS OFF.
    PRINT "Enable RCS".
    // WAIT UNTIL RCS.

    function find_prograde{
        local starting_alt is (SHIP:ORBIT:apoapsis + SHIP:orbit:periapsis) / 2.
        local target_alt is (TARGET:ORBIT:apoapsis + TARGET:orbit:periapsis) / 2.
        SET nodeTime TO TIME:SECONDS + 30.
        // Create node (example: 100 m/s prograde burn)
        LOCAL myNode TO NODE(nodeTime, 0, 0, 0).

        // Add it to the flight plan
        ADD myNode.
    
        print "starting_alt: " + starting_alt.
        local f_prograde to {
            PARAMETER X.
            set myNode:PROGRADE to X.
            wait 0.2.
            if abs(starting_alt - myNode:orbit:apoapsis) > abs(starting_alt - myNode:orbit:periapsis) {
                RETURN myNode:orbit:apoapsis.
            }ELSE{
                RETURN myNode:orbit:periapsis.
            }
        }.
        bisect_search(f_prograde, target_alt, 400, 0, 1, 20).
    }
    function find_transfer_start_time{
        local myNode TO NEXTNODE.
        local transfer_dt is myNode:ORBIT:PERIOD / 2.
        local f_approach to {
            PARAMETER T.
            set myNode:TIME to T.
            wait 0.2.
            RETURN (POSITIONAT(SHIP, T + transfer_dt) - POSITIONAT(TARGET, T + transfer_dt)):MAG.
        }.
        local t0 is TIMESTAMP():SECONDS + 30.
        local transfer_t0 is bisect_search(f_approach, 0, 400, t0, 1, 50).
        print transfer_t0.
    }
    find_prograde.
    find_transfer_start_time.
    RCS OFF.
    WAIT UNTIL RCS.
    PRINT "REBOOTING....".
    REBOOT.
}
do_randevouz().