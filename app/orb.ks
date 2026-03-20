RUNONCEPATH("0://util/app.ks").
RUNONCEPATH("0://util/orb.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://app/maneuvers.ks").
RUNONCEPATH("0://util/maneuvers.ks").

function create_circular_orbit_app{
    function def_cfg{
        local cfg is LEXICON().
        set cfg:alt to 100000.
        set cfg:orb_normal_v to V(0,0,0).
        set cfg:warp_all_transfers to FALSE.
        set cfg:incl_err to 0.1.
        set cfg:alt_err to 10.
        set cfg:ecc_err to 0.0001.
        RETURN cfg.
    }
    function cs_equatorial_orbit{PARAMETER _BODY, app.
        set app:cfg:orb_normal_v to getOrbitNormal(CREATEORBIT(0,0,10000,0,0,0,0,_BODY)).
    }
    local custom_setters is LEXICON(
        "equatorial_orbit", cs_equatorial_orbit@
    ).
    function getOppositeExtremumTs{
        PARAMETER orb.
        local pet is orb:ETA:PERIAPSIS.
        local apt is orb:ETA:APOAPSIS.
        RETURN TIME:SECONDS + (CHOOSE pet if ABS(pet - orb:PERIOD / 2) < ABS(apt - orb:PERIOD / 2) else apt).
    }
    function createNodeWithOppositeAlt{
        PARAMETER TS.
        PARAMETER _ALT.
        local nd is NODE(TS, 0, 0, 0).
        ADD nd.
        function find_prograde{
            PARAMETER P.
            set NEXTNODE:PROGRADE to P.
            local node_dir is POSITIONAT(SHIP, NEXTNODE:TIME) - SHIP:OBT:BODY:POSITION.
            local pe_dir is getOrbitPeDir(NEXTNODE:OBT):FOREVECTOR.
            // We compare direction to the node and directio to the PE after node. If their angle is more that 90, then PE is opposite.
            local oppositeExtremum is CHOOSE NEXTNODE:OBT:PERIAPSIS if VANG(node_dir, pe_dir) > 90 ELSE NEXTNODE:OBT:APOAPSIS.
            RETURN ABS(oppositeExtremum - _ALT).
        }
        print "Build alt at site 1.".
        set descend1d_logger to app:log@.
        descend1d(find_prograde@, 0, 1, 0.0001, 50).
    }
    function app_run{
        PARAMETER app.
        remove_all_nodes().
        local cfg is app:cfg.
        local exec_next_node is create_exec_next_node():setters
            :remove_node(TRUE)
            :auto_warp(app:cfg:warp_all_transfers)
            :app():run@.


        IF SHIP:ORBIT:INCLINATION < cfg:incl_err {
            app:log("Inclination is within limits (" + cfg:incl_err + ")").
        }ELSE{
            app:log("Align the inclination.").
            create_align_orbit_incl_app()
                :setters
                :target_orb_norm_v(app:cfg:orb_normal_v)
                :app():run().

            // exec_next_node().
            exec_node(NEXTNODE).
        }
        local alt_min is cfg:alt - cfg:alt_err.
        local alt_max is cfg:alt + cfg:alt_err.
        IF SHIP:ORBIT:PERIAPSIS = cap(SHIP:ORBIT:PERIAPSIS,alt_min, alt_max) AND SHIP:ORBIT:APOAPSIS = cap(SHIP:ORBIT:APOAPSIS, alt_min, alt_max) {
            app:log("Altitude is within limits (" + cfg:alt + "+-" + cfg:alt_err + ")").
        }ELSE{
            app:log("Align the altitude.").
            if SHIP:ORBIT:ECCENTRICITY < cfg:ecc_err {
                app:log("Eccentrecity is low, do not wait till PeAp.").
                createNodeWithOppositeAlt(TIME:SECONDS + 60, cfg:alt).
                local node_burn_time_till_midpoint is get_burn_duration(NEXTNODE:deltav:mag/2).
                remove_next_node().
                createNodeWithOppositeAlt(TIME:SECONDS + 60 + node_burn_time_till_midpoint, cfg:alt).
            }ELSE{
                app:log("Eccentrecity is hign, find the next Pe or Ap node").
                local nextPeApTs is getNextPeApTs(SHIP).
                createNodeWithOppositeAlt(nextPeApTs, cfg:alt).
                local node_burn_time_till_midpoint is get_burn_duration(NEXTNODE:deltav:mag/2).
                // 60 - extra time for stabilization and redirection. Potentially we could do it towards PROGRADE before the calculations.
                if NEXTNODE:TIME - node_burn_time_till_midpoint - 60 < TIME:SECONDS {
                    remove_next_node().
                    createNodeWithOppositeAlt(nextPeApTs+SHIP:OBT:PERIOD/2, cfg:alt).
                }
            }
            // exec_next_node().

            // createNodeWithOppositeAlt(getOppositeExtremumTs(SHIP:OBT), cfg:alt).
            // exec_next_node().
        }
        
    }

    local app is create_app("CIRCULAR_ORBIT", app_run@, def_cfg(), custom_setters).
    RETURN app.
}

function create_align_orbit_incl_app{
    // This app creates a node that aligns current orbit with another orbit(get inclination to 0).
    function def_cfg{
        local cfg is LEXICON().
        set cfg:target_orb_norm_v to V(0,0,0).
        RETURN cfg.
    }
    function app_run{
        PARAMETER app.
        // improve initial position for the upcoming AN_DN node by taking normal vector for each orb plane, then two normals to those two vectors are the directions to the AN and DN nodes. 
        local trgOrbNorm is app:cfg:target_orb_norm_v.
        ADD NODE(TIME:seconds + 10, 0, 0, 0).
        function node_time{
            PARAMETER N, T.
            set NEXTNODE:TIME to T.
            set NEXTNODE:NORMAL to N.
            local nodeOrbNorm is getOrbitNormal(NEXTNODE:ORBIT).
            RETURN 1000*VANG(trgOrbNorm, nodeOrbNorm).
        }
        local maneuver_time is descend(apply2p(node_time@), LIST(0, TIME:SECONDS+SHIP:ORBIT:PERIOD/6))[1].
        IF maneuver_time < TIME:SECONDS {
            print "Node is in the past".
            set maneuver_time to descend(apply2p(node_time@), LIST(maneuver_time + SHIP:ORBIT:PERIOD / 2, 0))[0].
        }
        REMOVE NEXTNODE.
        // Calculate the desired velocity we need to achieve at the AN/DN node so the orbit aligns with the target orbit.
        // We need to rotate the velocity vector for the same rotate as from the current normal to the target normal.
        local alignment_rotation is ROTATEFROMTO(getOrbitNormal(SHIP:ORBIT), trgOrbNorm).
        local current_vel is VELOCITYAT(SHIP, maneuver_time):ORBIT.
        local trg_vel is alignment_rotation * current_vel.
        local dv is trg_vel - current_vel.
        create_maneuver_deltav(maneuver_time, dv).
    }
    local app is  create_app("ORBIT:ALIGN", app_run@, def_cfg()).
    RETURN app.
}