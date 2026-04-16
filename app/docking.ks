RUNONCEPATH("0://util/app.ks").
RUNONCEPATH("0://util/orb.ks").
RUNONCEPATH("0://util/rcs.ks").
RUNONCEPATH("0://util/kinematics.ks").
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
            if target_dp:TYPENAME = "Part" {
                app:log("Found a matching port in " + target_vessel:NAME).
                app:setters
                        :my_port(dp)
                        :target_port(target_dp).
                RETURN.
            }
        }
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
        { // Draw docking ports indicators.
            app:log("Stage 1").
            if app:cfg:indicate_ports {
                CLEARVECDRAWS().
                //                show_rot(app:cfg:my_port:FACING, app:cfg:my_port:POSITION).
                //                show_rot(app:cfg:target_port:FACING, app:cfg:target_port:POSITION).
            }
        }
        { // Get to the auxilary point.
            app:log("Stage 2").
            function get_auxilary_dir{
                PARAMETER approach_point_v. // vector from the target port to the approach point.
                local ship_v is -app:cfg:target_port:POSITION. // vector from the target port to the ship.
                IF VANG(ship_v, approach_point_v) <= 90 {
                    RETURN approach_point_v:NORMALIZED.
                }
                local norm is VCRS(ship_v, approach_point_v).
                local ship_dir is LOOKDIRUP(ship_v, norm).
                RETURN ship_dir:STARVECTOR.
            }

            local aux is get_auxilary_dir(app:cfg:target_port:FACING:FOREVECTOR) * app:cfg:approach_dist.
            show_vect(app:cfg:target_port:FACING:FOREVECTOR * 10, "port", red, app:cfg:target_port:POSITION).
            show_vect(-app:cfg:target_port:POSITION, "ship", red, app:cfg:target_port:POSITION).
            show_vect(aux, "aux", blue, app:cfg:target_port:POSITION).

            // Orient towards the auxilary point.
            lock aux_dir_v to app:cfg:target_port:POSITION + aux.
            SAS OFF.
            RCS ON.
            lock STEERING to LOOKDIRUP(aux_dir_v, SHIP:UP:FOREVECTOR).
            app:log("Rotate to AUX point").
            function wait_facing_aux{
                PARAMETER precision.
                wait_cond(3, {
                    local ang_diff is VANG(SHIP:FACING:FOREVECTOR, aux_dir_v).
                    app:log("Angle to AUX point: " + ang_diff).
                    RETURN ang_diff < precision.
                }).
            }
            wait_facing_aux(1).
            app:log("Pointing to the AUX point 1º").
            //            wait_facing_aux(0.1).
            //            app:log("Pointing to the AUX point 0.1º").
            app:log("Starting the translation").
            UNLOCK STEERING.
            // Calc max rcs thrust.

            wait 0.
            SAS ON.

            RCS ON.
            app:log("[RCS Acc test] Starting").
            local rcs_acc is find_rcs_acc(5, 1).
            app:log("[RCS Acc test] RCS fwd max acc is " + rcs_acc).
            //            app:log("[RCS Acc test] Translation speed: " + approach_speed).
            //            app:log("[RCS Acc test] Expected acc/break time is " + approach_speed / rcs_acc).
            //            local min_breaking_dist is calc_dist(rcs_acc, approach_speed, approach_speed / rcs_acc).
            //            app:log("[RCS Acc test] Expected acc/break distance is " + min_breaking_dist).
            local max_approach_speed is 5.
            local approach_speed is max_approach_speed.
            lock velocity_expected to aux_dir_v:NORMALIZED * approach_speed.
            lock velocity_actual to SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT.

            until aux_dir_v:MAG < 1 { // 10 is just some precision buffer
                set approach_speed to min(max_approach_speed, get_max_breaking_speed(aux_dir_v:MAG, rcs_acc*0.85)).
                app:log("iter. dist=" + aux_dir_v:MAG + " approach_speed=" + approach_speed + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION).
                CLEARVECDRAWS().
                show_vect(aux, "aux", blue, app:cfg:target_port:POSITION).
                show_vect(velocity_expected * 20, "vel expected", red).
                show_vect(velocity_actual * 20, "vel actual", green).
                local dt is velocity_expected - velocity_actual.
                local correction is -SHIP:FACING * dt.
                set SHIP:CONTROL:TRANSLATION to correction / rcs_acc * 1.2.
                wait 0.
            }
            app:log("Arrived").
            set SHIP:CONTROL:TRANSLATION to V(0,0,0).

            // RCS towards the auxilary point. Accelerate to 5m/s
        }
        print "This app prints "+ app:cfg:my_port.
    }
    local custom_setters is LEXICON().
    set custom_setters:dock2target to dock2target@.
    local app is  create_app("DOCKING_APP", app_run@, def_cfg(), custom_setters).
    RETURN app.
}