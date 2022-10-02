set G0 to 9.80665.
declare function get_burn_duration{
    declare parameter dv.
    declare parameter mymass.
    declare parameter isp.
    declare parameter thrust.
    local ex_vel is isp * G0.
    local flow_rate is thrust / ex_vel.
    local end_mass is Constant:E ^ (ln(mymass) - dv/ex_vel).
    local dm is mymass - end_mass.
    local burn_time is dm / flow_rate.
    return burn_time.
}
declare function exec_node{
    declare parameter nd.
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
    local isp is total_thrust / total_fuel_consumption / G0.
    local burn_duration is get_burn_duration(nd:deltav:mag, ship:mass, isp, total_thrust).
    local before_midpoint_duration is get_burn_duration(nd:deltav:mag/2, ship:mass, isp, total_thrust).

    print "Estimated burn duration: " + round(burn_duration, 3) + "s".
    print "Node ETA : " + nd:eta.
    print "Time to burn : " + (nd:eta - before_midpoint_duration) .

    SAS OFF.
    lock steering to nd:deltav.
    wait until nd:eta <= (before_midpoint_duration + 60).


    //now we need to wait until the burn vector and ship's facing are aligned
    wait until vang(nd:deltav, ship:facing:vector) < 0.25.
    print "The ship is facing the right direction".

    //the ship is facing the right direction, let's wait for our burn time. It's late for ~ 1 sec
    wait until nd:eta <= before_midpoint_duration.
    print "burn time".

    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    set tset to 0.
    lock throttle to tset.

    set done to False.
    //initial deltav
    set dv0 to nd:deltav.
    until done
            {
                //recalculate current max_acceleration, as it changes while we burn through fuel
                set max_acc to total_thrust/ship:mass.

                //throttle is 100% until there is less than 1 second of time left to burn
                //when there is less than 1 second - decrease the throttle linearly
                set tset to min(nd:deltav:mag/max_acc, 1).

                //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
                //this check is done via checking the dot product of those 2 vectors
                if vdot(dv0, nd:deltav) < 0
                        {
                            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
                            lock throttle to 0.
                            break.
                        }

                //we have very little left to burn, less then 0.1m/s
                if nd:deltav:mag < 0.1
                        {
                            print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
                            //we burn slowly until our node vector starts to drift significantly from initial vector
                            //this usually means we are on point
                            wait until vdot(dv0, nd:deltav) < 0.5.

                            lock throttle to 0.
                            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
                            set done to True.
                        }
            }
    unlock steering.
    unlock throttle.
    wait 1.

    //set throttle to 0 just in case.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}