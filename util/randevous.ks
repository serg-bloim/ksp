parameter autostart is false.
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/orb.ks").
RUNONCEPATH("0://util/dir.ks").
RUNONCEPATH("0://util/func.ks").
declare function do_randevous{
    PARAMETER TRGT.
    RCS OFF.
    local targetOrbInterceptionTrueAnomaly is 0.
    local desired_dist_to_target is 200.
    start_reading_input().
    function align_orbits{
        local trgOrb is TARGET:ORBIT.
        ADD NODE(TIME:seconds + 10, 0, 0, 0).
        function node_time{
            PARAMETER T, N.
            set NEXTNODE:TIME to T.
            set NEXTNODE:NORMAL to N.        
            local trgOrbNorm is getOrbitNormal(trgOrb).
            local nodeOrbNorm is getOrbitNormal(NEXTNODE:ORBIT).
            RETURN 1000*VANG(trgOrbNorm, nodeOrbNorm).
        }
        local maneuver_time is descend(apply2p(node_time@), LIST(TIME:seconds,0))[0].
        IF maneuver_time < TIME:SECONDS {
            print "Node is in the past".
            set maneuver_time to descend(apply2p(node_time@), LIST(maneuver_time + SHIP:ORBIT:PERIOD / 2, 0))[0].
        }
        REMOVE NEXTNODE.
        // Calculate the desired velocity we need to achieve at the AN/DN node so the orbit aligns with the target orbit.
        // We need to rotate the velocity vector for the same rotate as from the current normal to the target normal.
        local alignment_rotation is ROTATEFROMTO(getOrbitNormal(SHIP:ORBIT), getOrbitNormal(trgOrb)).
        local current_vel is VELOCITYAT(SHIP, maneuver_time):ORBIT.
        local trg_vel is alignment_rotation * current_vel.
        local dv is trg_vel - current_vel.
        create_maneuver_deltav(maneuver_time, dv).
    }
    local Tt is 0.
    local Tsync is 0.
    local Ka is 0.
    function create_sync_node{
        local transfer_start_dirvec is -(POSITIONAT(TRGT, TRGT:ORBIT:ETA:PERIAPSIS + TIME:SECONDS) - TRGT:ORBIT:BODY:POSITION).
        function transfer_eta{
            PARAMETER T.
            local pos is POSITIONAT(SHIP, T).
            RETURN 1000*VANG(transfer_start_dirvec, pos - SHIP:ORBIT:BODY:POSITION).
        }
        local Ta is SHIP:ORBIT:PERIOD.
        local Tb is TRGT:ORBIT:PERIOD.
        local time_till_transfer_point is descend1d(transfer_eta@, TIME:seconds, 10, 0.1, 50) - TIME:SECONDS.
        if time_till_transfer_point < 0{
            set time_till_transfer_point to time_till_transfer_point + Ta.
        }
        local pb is Tb - TRGT:ORBIT:ETA:PERIAPSIS. // secs since last PE(interception point).
        local pa is Ta - time_till_transfer_point.
        local Ta_min is Ta.
        local Ta_max is Ta.
        set Tt to getOrbitPeriod(TRGT:ORBIT:BODY, SHIP:ORBIT:PERIAPSIS, TRGT:ORBIT:PERIAPSIS) / 2. // Period of a half transfer orbit
        IF TRGT:ORBIT:PERIAPSIS > SHIP:ORBIT:APOAPSIS{
            set Ta_max to 2 * Tt.
        } ELSE {
            set Ta_min to 2 * Tt.
        }
        ADD NODE(TIME:SECONDS + time_till_transfer_point, 0, 0 ,0).
        print "" 
        + "time_till_transfer_point=" + r2(time_till_transfer_point) + NL
        + "pa=" + r2(pa) + NL
        + "pb=" + r2(pb) + NL
        + "Tt=" + r2(Tt) + NL
        + "Ta_min=" + r2(Ta_min) + NL
        + "Ta_max=" + r2(Ta_max) + NL
        + "".
        local transfer_orbit_period_variation is 2.
        UNTIL FALSE{
            local kb_min is CEILING((Ta_min * Ka + Tt + Ta - pa + pb - transfer_orbit_period_variation)/Tb)-1.
            local kb_max is FLOOR((Ta_max * Ka + Tt + Ta - pa + pb + transfer_orbit_period_variation)/Tb)-1.
            print "Ka = " + Ka + " kb_min= " + kb_min + " kb_max=" + kb_max.
            if kb_min <= kb_max{
                set Kb to kb_min.
                print "Kb = " + Kb.
                BREAK.
            }
            set Ka to Ka + 1.
        }
        IF Ka > 0 {
            set Tsync to (Tb*(Kb + 1) - Tt - Ta + pa - pb)/Ka.
            print "Tsync=" + r2(Tsync).
            function adgust_period{
                PARAMETER p.
                set NEXTNODE:prograde to p.
                return abs(NEXTNODE:ORBIT:PERIOD - Tsync).
            }
            descend1d(adgust_period@, 0, 1, 0.1, 50).
        } ELSE{
            print "No syncing orbits, straight to the transfer.".
        }
        RETURN Ka.
    }
    function create_transfer_node{
      local ts is NEXTNODE:TIME.
      REMOVE NEXTNODE.
      ADD NODE(ts, 0, 0, 0).
      local xDirV is (SHIP:BODY:POSITION - POSITIONAT(SHIP, ts)).// Interception point directionV
      local trgOrbRadiusAtX is getOrbRadiusByDir(TRGT:ORBIT, xDirV).
      function find_prograde{
        PARAMETER p.
        set NEXTNODE:PROGRADE to p.
        RETURN ABS(trgOrbRadiusAtX - getOrbRadiusByDir(NEXTNODE:ORBIT, xDirV)).
      }
      descend1d(find_prograde@, 0).
      local P_transfer is getOrbitPeriod(TRGT:ORBIT:BODY, SHIP:ORBIT:PERIAPSIS, TRGT:ORBIT:PERIAPSIS) / 2. // Period of a half transfer orbit
      local skip_orbits is 0.
      local skip_orbits_min is 0.
      local skip_orbits_min_angle is 999.
      print "P_transfer = " + P_transfer.
      UNTIL skip_orbits > 1000 {
        local x_ts is NEXTNODE:TIME + skip_orbits * SHIP:ORBIT:PERIOD + P_transfer.
        local ang is VANG(POSITIONAT(TRGT, x_ts) - TRGT:ORBIT:BODY:POSITION, xDirV).
        IF ang < skip_orbits_min_angle{
            set skip_orbits_min_angle to ang.
            set skip_orbits_min to skip_orbits.
            print  " skip_orbits_min="+skip_orbits_min + " skip_orbits_min_angle="+skip_orbits_min_angle.
        }
        IF ang < 1 {
            break.
        }
        set skip_orbits to skip_orbits + 1.
      }
      print  " skip_orbits_min="+skip_orbits_min.
      set NEXTNODE:TIME to NEXTNODE:TIME + skip_orbits * SHIP:ORBIT:PERIOD.
      function randevous_precise{
        PARAMETER T_NODE, PROG.
        set NEXTNODE:TIME to T_NODE.
        set NEXTNODE:PROGRADE to PROG.
        function find_min_dist{
            PARAMETER X_TS.
            (POSITIONAT(SHIP, X_TS) - POSITIONAT(TRGT, X_TS)):MAG.
        }
        local intercept_T is descend1d(find_min_dist@, NEXTNODE:TIME + NEXTNODE:ORBIT:PERIOD/2).
        RETURN (POSITIONAT(SHIP, intercept_T) - POSITIONAT(TRGT, intercept_T)):MAG.
      }
      // Find the closest approach possible.
      descend(apply2p(randevous_precise@), LIST(NEXTNODE:TIME, NEXTNODE:PROGRADE), LIST(), 0.1, 20).

      // If the approach is too close, it can be risky due to possible collisions.
      // We need to adjust the node time to enlarge gap to at least @desired_dist_to_target

      function randevous_gap {
        PARAMETER T.
        set NEXTNODE:TIME to T.
        local intercept_T is T + NEXTNODE:ORBIT:PERIOD/2.
        local dist is POSITIONAT(SHIP, intercept_T) - POSITIONAT(TRGT, intercept_T).
        RETURN ABS(dist:MAG - desired_dist_to_target).
      }
      descend1d(randevous_gap@, NEXTNODE:TIME).
    }

    function complete_transfer{
        local T_x is NEXTNODE:TIME + NEXTNODE:ORBIT:PERIOD/2.
        local trgt_v is VELOCITYAT(TRGT, T_x):ORBIT.
        local ship_v is VELOCITYAT(SHIP, T_x):ORBIT.
        local dv is trgt_v - ship_v.
        create_maneuver_deltav(T_x, dv).
    }
    remove_all_nodes().
    print "Align orbit inclination".
    align_orbits().
    exec_node(NEXTNODE).
    remove_next_node().

    print "Sync orbits".
    local sync_orbs is create_sync_node().
    IF sync_orbs > 0 {
        exec_node(NEXTNODE).
    }
    print "Transfer to the target orbit".
    create_transfer_node().
    print "Complete the transfer".
    complete_transfer().
    exec_node(NEXTNODE).
    remove_next_node().
    exec_node(NEXTNODE).

    // Here we can wait till the last syncing orbit and if we accumulated any error, we can adjust for it by changing the last lap period.
    // find_transfer_start_time.
    // find_prograde.

    // exec_node(NEXTNODE).
    // remove NEXTNODE.
    // exec_node(NEXTNODE).
    stop_reading_input().
}