RUNONCEPATH("0://util/app.ks").
RUNONCEPATH("0://util/orb.ks").
RUNONCEPATH("0://util/rcs.ks").
RUNONCEPATH("0://util/kinematics.ks").
RUNONCEPATH("0://util/steering.ks").
function create_dock_app{
    function def_cfg{
        local cfg is LEXICON().
        set cfg:target_port to SHIP:ROOTPART.
        set cfg:my_port to SHIP:ROOTPART.
        set cfg:indicate_ports to FALSE.
        set cfg:approach_dist to 100.
        RETURN cfg.
    }
    function dock2target{
        PARAMETER target_vessel, app.
        for dp in get_all_docking_ports(SHIP) {
            local target_dp is get_matching_docking_port(target_vessel, dp).
            if target_dp:ISTYPE("Part") {
                app:log("Found a matching port in " + target_vessel:NAME).
                app:setters
                        :my_port(dp)
                        :target_port(target_dp).
                RETURN.
            }
        }
        app:log("Couldn't find matching ports").
    }
    function app_run{
        PARAMETER app.
        // Plan:
        // 1. Get to the close proximity of the target ship.
        // 2. Find the approach point (defined as the point towards the targert port at the approach distance).
        // 3. If the direct path to the approach point isn't clean, find an auxilary point that is.
        //    Auxilary point is defined as another point at the approach distance from the target ship that has a clear path to the approach point.
        //    Auxilary point is usually 90º from the approach point.
        // 3.1 Move to the auxilary point.
        // 4. Move to the approach point.
        // 5. Move to the target port. We should be pretty aligned at this point, so it should be a straight shot.
        // 6. When close to the docking port, stop at 5 meters and do the final alignment.
        // 7. When aligned, move to the target port and dock.
//        { // Draw docking ports indicators.
//            app:log("Stage 1").
//            if app:cfg:indicate_ports {
//                CLEARVECDRAWS().
//                //                show_rot(app:cfg:my_port:FACING, app:cfg:my_port:POSITION).
//                //                show_rot(app:cfg:target_port:FACING, app:cfg:target_port:POSITION).
//            }
//        }
//        { // Get to the approach point by passing auxilary points if nexessary.
//            app:log("Stage 2").
//            function get_auxilary_dir{
//                PARAMETER approach_dir_v. // vector from the target port to the approach point.
//                local ship_v is -app:cfg:target_port:POSITION. // vector from the target port to the ship.
//                IF VANG(ship_v, approach_dir_v) <= 90 {
//                    RETURN approach_dir_v:NORMALIZED.
//                }
//                local norm is VCRS(ship_v, approach_dir_v).
//                local ship_dir is LOOKDIRUP(ship_v, norm).
//                RETURN ship_dir:STARVECTOR.
//            }
//            lock approach to app:cfg:target_port:FACING:FOREVECTOR * app:cfg:approach_dist.
//            lock next_aux to get_auxilary_dir(approach) * app:cfg:approach_dist.
//            local aux is next_aux.
//            show_vect(app:cfg:target_port:FACING:FOREVECTOR * 10, "port", red, app:cfg:target_port:POSITION).
//            show_vect(-app:cfg:target_port:POSITION, "ship", red, app:cfg:target_port:POSITION).
//            show_vect(aux, "aux", blue, app:cfg:target_port:POSITION).
//
//            // Orient towards the auxilary point.
//            lock aux_dir_v to app:cfg:target_port:POSITION + aux.
//            SAS OFF.
//            RCS ON.
//            lock STEERING to LOOKDIRUP(aux_dir_v, SHIP:UP:FOREVECTOR).
//            app:log("Rotate to AUX point").
//            function wait_facing_aux{
//                PARAMETER precision.
//                wait_cond(3, {
//                    local ang_diff is VANG(SHIP:FACING:FOREVECTOR, aux_dir_v).
//                    app:log("Angle to AUX point: " + ang_diff).
//                    RETURN ang_diff < precision.
//                }).
//            }
//            wait_facing_aux(1).
//            app:log("Pointing to the AUX point 1º").
//            // Calc max rcs thrust.
//            UNLOCK STEERING.
//            wait 0.
//            SAS ON.
//            RCS ON.
//            app:log("[RCS Acc test] Starting").
//            local rcs_acc is find_rcs_acc(5, 1).
//            app:log("[RCS Acc test] RCS fwd max acc is " + rcs_acc).
//            //            app:log("[RCS Acc test] Translation speed: " + approach_speed).
//            //            app:log("[RCS Acc test] Expected acc/break time is " + approach_speed / rcs_acc).
//            //            local min_breaking_dist is calc_dist(rcs_acc, approach_speed, approach_speed / rcs_acc).
//            //            app:log("[RCS Acc test] Expected acc/break distance is " + min_breaking_dist).
//            app:log("Starting the translation").
//            UNTIL (app:cfg:target_port:POSITION + approach):MAG < 10{
//                app:log("aux_dir_v: " + aux_dir_v).
//                set aux to next_aux.
//                IF (approach - aux):MAG < 5 {
//                    app:log("Heading to the approach point").
//                } ELSE {
//                    app:log("Heading to the aux point").
//                }
//                rcs_move_relative_to_target2(app:cfg:target_port:SHIP, aux, 5).
//            }
//            app:log("Arrived to the approach point").
//            rcs_stop_relative_to_target(app:cfg:target_port:SHIP, app:log).
//            app:log("Arrived").
//            set SHIP:CONTROL:TRANSLATION to V(0,0,0).
//
//            // RCS towards the auxilary point. Accelerate to 5m/s
//        }
        {
            // Align with the port.
            // Reduce the distance to 10 meters. For instance if the target port is 100 meters away, we can accelerate 45 meters fwd, then brake for 45 meters and then coast for the last 10 meters while doing the final alignment.
            app:log("Stage 3").
            app:log("Align direction with the port").
            local transform_remote_port_inverse is R(180, 0, 0).
            local transform_local_port_to_heading is -app:cfg:my_port:FACING * SHIP:FACING.
            local transform_full is transform_remote_port_inverse * transform_local_port_to_heading.

            lock connecting_steering to app:cfg:target_port:FACING * transform_full.
            CLEARVECDRAWS().
            show_rot(app:cfg:target_port:FACING * transform_full).
            SAS OFF.
            WAIT 0.
            lock STEERING to connecting_steering.
            show_rot(app:cfg:target_port:FACING * transform_remote_port_inverse, app:cfg:target_port:POSITION).
            show_rot(app:cfg:my_port:FACING, app:cfg:my_port:POSITION).
//            wait_steering_stable(1).
//            UNLOCK STEERING.
            WAIT 0.
//            SAS ON.

            CLEARVECDRAWS().
            show_rot(app:cfg:target_port:FACING * transform_remote_port_inverse, app:cfg:target_port:POSITION).
            show_rot(app:cfg:my_port:FACING, app:cfg:my_port:POSITION).

            app:log("Ship's direction is aligned with the port").
            app:log("Place the ship 10m in front of the port").
            local my_port_offset is -app:cfg:my_port:FACING * app:cfg:my_port:POSITION.
            // Calculate vector from target ship to my ship when they are perfectly docked.
            lock attach_point to (app:cfg:target_port:POSITION - app:cfg:target_port:SHIP:POSITION) // Offset from target ship to target port.
                    + (app:cfg:target_port:FACING * transform_remote_port_inverse) * -my_port_offset. // Offset from my port to my COM(when my port is aligned with the target port).
            local dist is 10.
            function get_point_in_front_of_port {
                PARAMETER dist is 0.
                RETURN attach_point + app:cfg:target_port:FACING:FOREVECTOR * dist.
            }
            show_vect(attach_point, "COM", white , app:cfg:target_port:SHIP:POSITION).
            show_vect(get_point_in_front_of_port(10) - attach_point, "COM", white , app:cfg:target_port:SHIP:POSITION+attach_point).
//            show_vect((app:cfg:target_port:FACING * transform_remote_port_inverse) * my_port_offset, "COM", white, app:cfg:target_port:POSITION).
//            show_vect((app:cfg:target_port:FACING * transform_remote_port_inverse) * -my_port_offset, "COM", red).
            RCS ON.
            rcs_move_relative_to_target2(app:cfg:target_port:SHIP, get_point_in_front_of_port(10), 5).
            wait_steering_stable(1).
            rcs_move_relative_to_target2(app:cfg:target_port:SHIP, get_point_in_front_of_port(1), 1).
            wait_steering_stable(0.1).
            rcs_move_relative_to_target2(app:cfg:target_port:SHIP, get_point_in_front_of_port(0), 0.2).
        }
        print "This app prints "+ app:cfg:my_port.
    }
    local custom_setters is LEXICON().
    set custom_setters:dock2target to dock2target@.
    local app is  create_app("DOCKING_APP", app_run@, def_cfg(), custom_setters).
    RETURN app.
}