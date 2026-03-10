RUNONCEPATH("0://util/randevous.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://test/mun_lifter.ks").


until FALSE {
    CLEARVECDRAWS().
    // remove_all_nodes().
    // ADD NODE(TIME:SECONDS, 0, 0, 0).
    // local incl is {
    //     PARAMETER T, N.
    //     set NEXTNODE:TIME to T.
    //     set NEXTNODE:NORMAL to N.
    //     WAIT 0.2.
    //     RETURN VANG(getOrbitNormal(NEXTNODE:orbit), getOrbitNormal(TARGET:ORBIT)).
    // }.
    // local res is descend(apply2p(incl), LIST(TIME:SECONDS, 0)).
    // apply2p(incl)(res).


    
    local t is NEXTNODE:TIME.
    remove_all_nodes().
    local orb_rotation is ROTATEFROMTO(getOrbitNormal(SHIP:ORBIT), getOrbitNormal(TARGET:ORBIT)).
    local vel_cur is VELOCITYAT(SHIP, t):ORBIT.
    local vel_trg is orb_rotation * vel_cur.
    local node_pos is POSITIONAT(SHIP, t).
    show_vect(vel_cur*50, "cur", red, node_pos).
    show_vect(vel_trg*50, "trg", green, node_pos).
    create_maneuver_deltav(t, vel_trg - vel_cur).
    show_vect(NEXTNODE:DELTAV*50, "dv_act", blue, node_pos).
    show_vect((vel_trg-vel_cur)*50, "dv_trg", purple, node_pos).

    
    // ADD NODE(t, 0, 0, 0).

    // local inclRadius is {
    //     PARAMETER P, N.
    //     set NEXTNODE:PROGRADE to P.
    //     set NEXTNODE:NORMAL to N.
    //     WAIT 0.5.
    //     RETURN 10 * VANG(getOrbitNormal(NEXTNODE:orbit), getOrbitNormal(TARGET:ORBIT)).
    // }.
    // local res is descend(apply2p(inclRadius), LIST(0, 0)).
    // apply2p(inclRadius)(res).
    // print res.
    RCS OFF.
    WAIT UNTIL RCS.
}