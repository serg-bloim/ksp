parameter autostart is false.
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/orb.ks").
RUNONCEPATH("0://util/dir.ks").
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
declare function do_randevous{
    PARAMETER TRGT.
    RCS OFF.
    start_reading_input().
    function align_orbits{
        PARAMETER trgOrb.

    }
    function find_prograde{
        local starting_alt is (SHIP:ORBIT:apoapsis + SHIP:orbit:periapsis) / 2.
        local target_alt is (TRGT:ORBIT:apoapsis + TRGT:orbit:periapsis) / 2.
        LOCAL myNode TO NEXTNODE.

        print "starting_alt: " + starting_alt.
        local f_prograde to {
            PARAMETER X.
            set myNode:PROGRADE to X.
            wait 0.
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
        print "transfer_dt: " + transfer_dt.
        local f_approach to {
            PARAMETER T.
            set myNode:TIME to T.
            wait 0.
            RETURN (POSITIONAT(SHIP, T + transfer_dt) - POSITIONAT(TRGT, T + transfer_dt)):MAG.
        }.
        local t0 is TIMESTAMP():SECONDS + 30.
        local transfer_t0 is bisect_search(f_approach, 0, 400, t0, 1, 50).
        if transfer_t0 < TIME:seconds {
            local sync_T is 1 / abs(1/SHIP:ORBIT:PERIOD - 1/TRGT:ORBIT:PERIOD).
            print "The transfer start is in the past, needs to add the orbits sync period (" + sync_T + ")".
            set transfer_t0 to transfer_t0 + sync_T.
        }
        print "Now T: " + TIME:SECONDS.
        print "Transfer start T: " + transfer_t0.
        print "Interception T: " + (transfer_t0 + transfer_dt).
        set NEXTNODE:TIME to transfer_t0.
    }
    function complete_transfer{
        local f_intersection to {
            PARAMETER T.
            RETURN (POSITIONAT(SHIP, T) - POSITIONAT(TRGT, T)):MAG.
        }.
        local transfer_t1 is bisect_search(f_intersection, 400, 100, TIME:seconds + SHIP:ORBIT:PERIOD / 2 - 30, 1, 50).
        local target_v is VELOCITYAT(TRGT, transfer_t1):ORBIT:MAG.
        ADD NODE(transfer_t1, 0, 0, target_v - VELOCITYAT(SHIP, transfer_t1):ORBIT:MAG).
    }
    remove_all_nodes.
    
    find_prograde.
    find_transfer_start_time.
    find_prograde.
    // exec_node(NEXTNODE).
    // remove NEXTNODE.
    // complete_transfer.
    // exec_node(NEXTNODE).
    stop_reading_input().
    RCS OFF.
    PRINT "Enable RCS".
    WAIT UNTIL RCS.
    PRINT "REBOOTING....".
    REBOOT.
}