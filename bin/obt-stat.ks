RUNONCEPATH("/util/utils.ks").
CLEARSCREEN.
//print NEXTNODE.
//local obt is NEXTNODE:ORBIT:NEXTPATCH.
declare function obt_period{
    declare parameter obt.
    if obt:ECCENTRICITY>1 {
        return 0.
    } else{
        return obt:PERIOD.
    }
}
//declare function obt_desc{
//    declare parameter obt.
//    print "BODY : " + obt:BODY.
//    print "PERIAPSIS : " + obt:PERIAPSIS.
//    print "APOAPSIS : " + obt:APOAPSIS.
//    print "ECCENTRICITY : " + obt:ECCENTRICITY.
//    print "SEMIMAJORAXIS : " + obt:SEMIMAJORAXIS.
//    print "SEMIMINORAXIS : " + obt:SEMIMINORAXIS.
//    print "ARGUMENTOFPERIAPSIS : " + obt:ARGUMENTOFPERIAPSIS.
//    print "TRUEANOMALY : " + obt:TRUEANOMALY.
//    print "TRANSITION : " + obt:TRANSITION.
//    print "PERIOD : " + obt_period(obt).
//}
//print 1.
//obt_desc(NEXTNODE:ORBIT).
//print "".
//print 2.
//obt_desc(NEXTNODE:ORBIT:NEXTPATCH).
//
//local a is 1/0.

local nl is "
".
declare function redraw{
    local txt is "".
    local i is 0.
    if HASNODE {
        local patch is NEXTNODE:ORBIT.
        until patch:ISTYPE("Boolean") {
            set txt to txt +  "  " + patch:NAME + nl.
            set txt to txt +  "    APOAPSIS :" + patch:APOAPSIS + nl.
            set txt to txt +  "    PERIAPSIS :" + patch:PERIAPSIS + nl.
            set txt to txt +  "    INCLINATION :" + patch:INCLINATION + nl.
            set txt to txt +  "    PERIOD :" + obt_period(patch) + nl.
            set txt to txt +  nl +" " + nl.
            if patch:HASNEXTPATCH{
                set patch to patch:NEXTPATCH.
            } else{
                set patch to FALSE.
            }
        }
    }
    CLEARSCREEN.
    print txt.
}
until esc_pressed(){
    redraw.
    wait 0.2.
}

