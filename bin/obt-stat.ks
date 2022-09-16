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
    local txt is "Orbits: " + nl.
    declare function print_patch{
        declare parameter patch.
        set txt to txt +  "  " + patch:NAME + nl.
        set txt to txt +  "    APOAPSIS :" + patch:APOAPSIS + nl.
        set txt to txt +  "    PERIAPSIS :" + patch:PERIAPSIS + nl.
        set txt to txt +  "    INCLINATION :" + patch:INCLINATION + nl.
        set txt to txt +  "    PERIOD :" + obt_period(patch) + nl.
        set txt to txt +  nl +" " + nl.
    }
    set txt to txt + "Actual orbit:" + nl.
    for p in SHIP:PATCHES{
        print_patch(p).
    }
    set txt to txt + nl.
    if HASNODE {
        set txt to txt + "Projected orbit:" + nl.
        local patch is NEXTNODE:ORBIT.
        until not patch:HASNEXTPATCH {
            print_patch(patch).
            set patch to patch:NEXTPATCH.
        }
        print_patch(patch).
        local i is 0.
        local dv_total is 0.
        set txt to txt  + nl + nl.
        for n in ALLNODES{
            set i to i + 1.
            local dv is sqrt(n:PROGRADE^2+n:RADIALOUT^2+n:NORMAL^2).
            set dv_total to dv_total + dv.
            set txt to txt + "Node " + i + " : " + round(dv) + "/" + round(dv_total) + nl.
        }
    }
    CLEARSCREEN.
    print txt.
}
until esc_pressed(){
    redraw.
    wait 0.2.
}

