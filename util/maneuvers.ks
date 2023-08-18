RUNONCEPATH("/util/utils.ks").
RUNONCEPATH("/util/stages.ks").
set G0 to 9.80665.
// declare function get_burn_duration{
//     declare parameter dv.
//     declare parameter mymass.
//     declare parameter isp.
//     declare parameter thrust.
//     local ex_vel is isp * G0.
//     local flow_rate is thrust / ex_vel.
//     local end_mass is Constant:E ^ (ln(mymass) - dv/ex_vel).
//     local dm is mymass - end_mass.
//     local burn_time is dm / flow_rate.
//     return burn_time.
// }
declare function get_burn_duration{
    declare parameter dv.
    declare PARAMETER stages is list().
    if stages:empty {
        set stages to get_stages().
    }
    local total_burn_duration to 0.
    local last_stage is -1.
    // print stages.
    from {local it is stages:reverseiterator.} until not it:next step{} do {
        local s is it:value.
        if s:DV > dv {set last_stage to s. break.}.
        set dv to dv - s:DV.
        set total_burn_duration to total_burn_duration + s:BURN_DUR.
    }
    // not enough DV to execute the maneuver
    if last_stage = -1
        RETURN -1.
    // for s in stages{
    //     if s:DV > dv {set last_stage to s. break.}.
    //     set dv to dv - s:DV.
    //     set total_burn_duration to total_burn_duration + s:BURN_DUR.
    // }
    // print last_stage.
    local mymass to last_stage:MASS.
    local isp to last_stage:ISP.
    local thrust to last_stage:THRUST.
    local ex_vel is isp * G0.
    print "" +  " ex_vel: " + ex_vel +  " isp: " + isp.
    local end_mass is Constant:E ^ (ln(mymass) - dv/ex_vel).
    local flow_rate is thrust / ex_vel.
    local dm is mymass - end_mass.
    local burn_time is dm / flow_rate.
    print "" + " dv: " + dv + " burn_time: " + burn_time + " dm: " + dm + " flow_rate: " + flow_rate + " ex_vel: " + ex_vel.
    set total_burn_duration to total_burn_duration + burn_time.
    return total_burn_duration.
}
declare function exec_node{
    declare parameter nd.
    local exec_node_triggers_enabled to true.
    local warp_trigger_enabled to true.
    local done to False.
    local usingSas to SHIP:PARTSTAGGED("manexec:usesas"):length > 0.
    //print out node's basic parameters - ETA and deltaV
    print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).


    // Now we just need to divide deltav:mag by our ship's max acceleration
    // to get the estimated time of the burn.
    //
    // Please note, this is not exactly correct.  The real calculation
    // needs to take into account the fact that the mass will decrease
    // as you lose fuel during the burn.  In fact throwing the fuel out
    // the back of the engine very fast is the entire reason you're able
    // to thrust at all in space.  The proper calculation for this
    // can be found easily enough online by searching for the phrase
    //   "Tsiolkovsky rocket equation".
    // This example here will keep it simple for demonstration purposes,
    // but if you're going to build a serious node execution script, you
    // need to look into the Tsiolkovsky rocket equation to account for
    // the change in mass over time as you burn.
    //
    local total_fuel_consumption is 0.
    local total_thrust is 0.
    LIST ENGINES in eng.
    for e in eng{
        if e:IGNITION{
            set total_fuel_consumption to total_fuel_consumption + e:MAXMASSFLOW * e:THRUSTLIMIT / 100.
            set total_thrust to total_thrust + e:MAXTHRUST * e:THRUSTLIMIT / 100.
        }
    }
    // local isp is total_thrust / total_fuel_consumption / G0.
    local stages is get_stages().
    local burn_duration is get_burn_duration(nd:deltav:mag, stages).
    if burn_duration = -1
        RETURN FALSE.
    local before_midpoint_duration is get_burn_duration(nd:deltav:mag/2, stages).

    print "Total thrust: " + total_thrust.
    // print "Isp: " + isp.
    print "Estimated burn duration: " + round(burn_duration, 3) + "s".
    print "Node ETA : " + nd:eta.
    print "Time to burn : " + (nd:eta - before_midpoint_duration) .
    KUniverse:PAUSE().
    local warp_enabled to false.
    on chars_read_num{
        local ch to last_read_char:tolower().
        if ch = "w" {
            if kuniverse:timewarp:rate > 1 {
                print "Stop the warp".
                kuniverse:timewarp:cancelwarp().
                set warp_enabled to false.
            }else{
                print "Warp to the node".
                toggle warp_enabled.
            }
        }else if ch = "q"{
            set done to true.
        }
        return exec_node_triggers_enabled.
    }
    local prevSasMode to sasMode.
    if usingSas{
        SAS ON.
        wait 0.
        unlock steering.
        set sasMode to "MANEUVER".
    }else{
        SAS OFF.
        set man_vec to nd:deltav.
        lock steering to man_vec.
        wait until done or vang(man_vec, ship:facing:vector) < 1.
        lock steering to nd:deltav.
        print "The ship is facing the right direction".
    }
    if warp_enabled {
        // 10 - seconds before node burn start
        kuniverse:timewarp:warpto(time:seconds + nd:eta - before_midpoint_duration - 10).
    }
    ON warp_enabled {
        if warp_enabled {
            // 10 - seconds before node burn start
            kuniverse:timewarp:warpto(time:seconds + nd:eta - before_midpoint_duration - 10).
        }else{
            kuniverse:timewarp:cancelwarp().
        }
        return warp_trigger_enabled.
    }

    wait until done or nd:eta <= before_midpoint_duration.
    set warp_trigger_enabled to false.
    print "burn time".

    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    set tset to 0.
    lock throttle to tset.

    //initial deltav
    set dv0 to nd:deltav.
    print "done = " + done.
    until done{
        //recalculate current max_acceleration, as it changes while we burn through fuel
        set max_acc to total_thrust/ship:mass.

        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(nd:deltav:mag/max_acc, 1).

        //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
        //this check is done via checking the dot product of those 2 vectors
        if vdot(dv0, nd:deltav) < 0{
                    print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
                    lock throttle to 0.
                    break.
                }

        //we have very little left to burn, less then 0.1m/s
        if nd:deltav:mag < 0.1{
                    print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
                    //we burn slowly until our node vector starts to drift significantly from initial vector
                    //this usually means we are on point
                    wait until vdot(dv0, nd:deltav) < 0.5.

                    lock throttle to 0.
                    print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
                    set done to True.
                }
        wait 0.
    }
    print "done = " + done.
    if usingSas {
        set sasMode to prevSasMode.
    }else{
        unlock steering.
    }
    unlock throttle.
    set exec_node_triggers_enabled to false.
    set warp_trigger_enabled to false.
    kuniverse:timewarp:cancelwarp().
    wait 1.

    //set throttle to 0 just in case.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    return TRUE.
}