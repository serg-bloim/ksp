RUNONCEPATH("0://util/app.ks").
RUNONCEPATH("0://util/body.ks").
RUNONCEPATH("0://util/vector.ks").
RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://app/orb.ks").
RUNONCEPATH("0://app/maneuvers.ks").
function create_landing_app{
    function def_cfg{
        local cfg is LEXICON().
        set cfg:loc to LATLNG(0,0).
        set cfg:warp_all_transfers to FALSE.
        set cfg:show_loc to FALSE.
        RETURN cfg.
    }
    function app_run{
        PARAMETER app.
        local cfg is app:cfg.
        if cfg:show_loc {
            local srfpos is cfg:loc:position.
            local origin is SHIP:BODY:POSITION + (srfpos - SHIP:BODY:POSITION) * 1.2.
            CLEARVECDRAWS().
            show_vect(srfpos - origin, "", red, origin).
        }
        { // Stage 1. Circle Equatorial orbit
            app:log("Stage 1. Circle Equatorial orbit").
            create_circular_orbit_app():setters
                :equatorial_orbit(SHIP:BODY)
                :alt(30000)
                :alt_err(100)
                :warp_all_transfers(cfg:warp_all_transfers)
                :app()
                :run().
        }
        
        local plannedHoverAlt is 2000.
        { // Measure the landing trajectory time
            local node_ts is TIME:SECONDS+30.
            local node_dirv is POSITIONAT(SHIP, node_ts)-BODY:POSITION.
            local nodeOrbDir is LOOKDIRUP(node_dirv, getOrbitNormal(SHIP:ORBIT)).
            local dir90DegFwd is nodeOrbDir:STARVECTOR.
            local nodeVel is VELOCITYAT(SHIP, node_ts):orbit.
            local rotAtNodeTowardsNorth is ANGLEAXIS(-cfg:loc:LAT, LOOKDIRUP(SHIP:BODY:angularvel, dir90DegFwd):STARVECTOR).
            local trgVel is rotAtNodeTowardsNorth * VELOCITYAT(SHIP, node_ts):ORBIT.
            local dv is trgVel - nodeVel.
            create_maneuver_deltav(node_ts, dv).

            // calc the descend trajectory
            local landingTerraingHeight is max(0,cfg:loc:TERRAINHEIGHT).

            local landingDir is rotAtNodeTowardsNorth * dir90DegFwd.
            print landingDir.
            show_orb_vec(landingDir).
            local descendNode is NODE(NEXTNODE:TIME + 1, 0, 0, -20).
            ADD descendNode.
            function make_descend_trajectory{
                PARAMETER P.
                SET descendNode:PROGRADE to P.
                RETURN getOrbAltByDir(descendNode:ORBIT, landingDir).
            }
            set descend1d_logger to log_only_main.
            descend1d(distTo(landingTerraingHeight + plannedHoverAlt, make_descend_trajectory@)).
            print getOrbAltByDir(descendNode:ORBIT, landingDir).

            // Merge two nodes into a single node. 
            local trgVel is VELOCITYAT(SHIP, descendNode:TIME + descendNode:ORBIT:PERIOD - 1):ORBIT.
            remove_all_nodes().
            create_maneuver_deltav(node_ts, trgVel - VELOCITYAT(SHIP, node_ts):ORBIT).

            // Calc time from the node till landing
            function angular_proximity_landing{
                PARAMETER T.
                local pos is POSITIONAT(SHIP, T).
                local orbDir is pos - SHIP:BODY:POSITION.
                RETURN VANG(orbDir, landingDir).
            }
            local landing_ts is descend1d(angular_proximity_landing@, node_ts + NEXTNODE:ORBIT:PERIOD / 4).
            local descendTime is landing_ts - node_ts.
            app:log("Descend time is " + r2(descendTime) + "s").
            local minimumPrepTime is 30.
            // Calc LNG when SHIP is above landing.
            function ts2land_lng{
                PARAMETER T.
                set T to max(T, TIME:SECONDS + minimumPrepTime).
                set NEXTNODE:TIME to T.
                local landingPos is POSITIONAT(SHIP, T + descendTime).
                RETURN geopositionOfAt(SHIP:BODY, landingPos, T + descendTime):LNG.
            }
            local start_ts is descend1d({PARAMETER T. 
                RETURN dist_between_angles(cfg:loc:LNG, ts2land_lng(T)).
            }, TIME:seconds + minimumPrepTime).
            if dist_between_angles(ts2land_lng(start_ts), cfg:loc:LNG) > 1{
                app:log("First attempt to find a starting time for the descend gives landing LNG: " + r2(ts2land_lng(start_ts)) + "("+r2(ABS(ts2land_lng(start_ts) - cfg:loc:LNG))+")").
                set start_ts to descend1d({PARAMETER T. 
                    RETURN dist_between_angles(cfg:loc:LNG, ts2land_lng(T)).
                }, TIME:seconds + SHIP:ORBIT:PERIOD).
            }
            set NEXTNODE:TIME to start_ts.
            app:log("Final attempt to find a starting time for the descend gives landing LNG: " + r2(ts2land_lng(start_ts)) + "("+r2(ABS(ts2land_lng(start_ts) - cfg:loc:LNG))+")").

            local landing_ts is NEXTNODE:TIME + descendTime.

            ADD NODE(landing_ts, 0, 0, 0).
            create_exec_next_node():setters
                :remove_node(TRUE)
                :auto_warp(app:cfg:warp_all_transfers)
                :app():run().
        } 
        {   // breaking maneuver
            print "breaking maneuver".
            local landing_ts is NEXTNODE:TIME.
            // Calc Brake maneuver
            local v_horiz is VELOCITYAT(SHIP, landing_ts):surface.
            local thrust_max is get_total_thrust().
            lock a_max to thrust_max/ship:mass*0.8.
            local g is get_g_acc(SHIP:BODY, plannedHoverAlt).
            // local a_usable is a_max - g.
            lock a_horizontal to a_max - g.
            local t_vert is sqrt(2 * plannedHoverAlt / a_horizontal).
            local t_horiz is v_horiz:MAG / a_max.
            local total_time is t_vert + t_horiz.
            local w is a_max * (t_horiz^2) / 2.
            print "v_horiz:MAG: " + v_horiz:MAG.
            print "a_max: " + a_max.
            print "t_vert: " + t_vert.
            print "t_horiz: " + t_horiz.
            print "w: " + w.
            print "Return the landing mark " + total_time + "s back dur to the braking maneuver.".
            local a_goal is a_max.
            // Create a breaking node w meters before the landing position
            function find_breaking_node_ts{
                PARAMETER T.
                RETURN (POSITIONAT(SHIP, T) - POSITIONAT(SHIP, landing_ts)):MAG.
            }
            print 123.
            local horizontal_breaking_start_ts is descend1d(distTo(w, find_breaking_node_ts@), landing_ts-10).
            print horizontal_breaking_start_ts.
            ADD NODE(horizontal_breaking_start_ts, 0, 0, 0).

            function to_body{
                PARAMETER _v.
                RETURN _v - BODY:POSITION.
            }
            function from_body{
                PARAMETER _v.
                RETURN _v + BODY:POSITION.
            }

            SAS ON.
            wait 0.
            set SASMODE to "RETROGRADE".
            wait 3.
            kuniverse:timewarp:warpto(horizontal_breaking_start_ts - 10).
            wait until TIME:SECONDS > horizontal_breaking_start_ts - 10.
            kuniverse:timewarp:cancelwarp().
            wait until TIME:SECONDS > horizontal_breaking_start_ts.
            lock landing_pos_srf to cfg:loc:POSITION.
            lock landing_pos_air to from_body(to_body(landing_pos_srf):NORMALIZED * (BODY:RADIUS+ALTITUDE)).
            SAS OFF.
            // lock compensate_twrds_landing to PROGRA
            lock x0 to landing_pos_air:MAG.
            local g is get_g_acc(SHIP:BODY, plannedHoverAlt).
            lock a_max to thrust_max/ship:mass.
            lock a_horizontal to SQRT(a_max^2 - g^2).
            lock steering_up_v to LOOKDIRUP(landing_pos_air, SHIP:up:forevector):upvector.
            lock compensate_prograde_v to VXCL(steering_up_v, PROGRADE:forevector).
            lock breaking_dir_v to -compensate_prograde_v.
            // lock breaking_dir_v to -landing_pos_air.
            lock braking_v to breaking_dir_v:NORMALIZED * a_horizontal + g*SHIP:up:forevector.
            lock STEERING to LOOKDIRUP(braking_v, SHIP:up:forevector).
            lock a_max_prograde to braking_v * RETROGRADE:FOREVECTOR * 0.8.
            lock a_max_prograde to ABS(braking_v * VXCL(UP:forevector, RETROGRADE:FOREVECTOR)) * 0.8.

            lock time_till_v0 to SHIP:GROUNDSPEED / a_max_prograde.
            lock dist_till_v0 to a_max_prograde * (time_till_v0^2) / 2.
            UNTIL time_till_v0 < 5 {
                if x0 > dist_till_v0{
                    lock THROTTLE to 0.
                    wait until x0 <= dist_till_v0.
                    print "NO MORE GAP".
                }
                lock THROTTLE to 1.
                print "THROTTLE " + r2(time_till_v0).
                wait 5.
            }
            lock THROTTLE to 0.
            print "Time left till target: " + r2(time_till_v0).
            local steer is STEERING.
            local final_time is SHIP:GROUNDSPEED / a_horizontal.
            UNLOCK ALL.
            lock STEERING to steer.
            lock THROTTLE to 1.
            wait final_time.
            lock THROTTLE to 0.
            UNLOCK ALL.
        }
        {   // Vertical landing
            print "Vertical landing".
            SAS ON.
            wait 0.
            set SASMODE to "RETROGRADE".
            local landing_height is cfg:loc:TERRAINHEIGHT.
            local slow_descend_height is 50.
            local slow_descend_speed is 5.
            lock dh to SHIP:ALTITUDE - landing_height-slow_descend_height.

            local g is get_g_acc(SHIP:BODY, plannedHoverAlt).
            local thrust_max is get_total_thrust().
            lock a_max to thrust_max/ship:mass.
            lock a_max_v to a_max - g.
            lock time_till_v0 to (SHIP:VERTICALSPEED - slow_descend_speed) / a_max_v.
            lock x_till_v0 to a_max_v * (time_till_v0^2) / 2.
            print "x_till_v0: "+ x_till_v0.
            print "dh: "+ dh.
            wait until dh < x_till_v0.
            LOCK THROTTLE to 1.
            wait until -SHIP:VERTICALSPEED < slow_descend_speed.
            LOCK THROTTLE to g / a_max.
            wait until SHIP:STATUS = "LANDED".
            LOCK THROTTLE to 0.
            UNLOCK ALL.
        }
    }
    RETURN create_app("LANDING", app_run@, def_cfg()).
}