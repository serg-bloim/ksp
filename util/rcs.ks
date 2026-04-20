RUNONCEPATH("util/log.ks").
RUNONCEPATH("util/dbg.ks").
RUNONCEPATH("util/vector.ks").
RUNONCEPATH("util/kinematics.ks").

function precise_movement{
    PARAMETER velocity_actual_dgt.
    PARAMETER velocity_expected_dgt.
    PARAMETER stop_cond_dgt is { RETURN (velocity_actual - velocity_expected):MAG < 0.1. }.

    local velocity_actual is velocity_actual_dgt().
    local velocity_expected is velocity_expected_dgt().
    until NOT stop_cond_dgt() { // 10 is just some precision buffer
        set velocity_actual to velocity_actual_dgt().
        set velocity_expected to velocity_expected_dgt().
        local dt is velocity_expected - velocity_actual.
        local correction is -SHIP:FACING * dt.
        set SHIP:CONTROL:TRANSLATION to correction.
        wait 0.
    }

}

function find_rcs_acc{
    PARAMETER period is 1.
    PARAMETER rcs_thrust is 1.
    local vel_without_rcs is VELOCITYAT(SHIP, TIME:SECONDS + period):ORBIT.
    set SHIP:CONTROL:FORE to rcs_thrust.
    local start_time is TIME:SECONDS.
    wait period.
    set SHIP:CONTROL:FORE to 0.
    wait 0.
    local end_time is TIME:SECONDS.
    local dv is SHIP:VELOCITY:ORBIT - vel_without_rcs.
    local rcs_acc is dv:MAG / rcs_thrust / (end_time - start_time).
    RETURN rcs_acc.
}

function rcs_move_relative_to_target{
    PARAMETER dst_dir_v_dgt. // Function delegate that returns a vector to the destination.
    PARAMETER rcs_acc is 1. // Max RCS acceleration. Can be found using find_rcs_acc function.
    PARAMETER max_speed is rcs_acc * 5. // Just some default value to prevent going too fast if the dst is far away. Can be calculated based on the distance to the target and rcs_acc.

    local max_approach_speed is max_speed.
    local approach_speed is max_approach_speed.
    local dst_v is dst_dir_v_dgt().
    lock velocity_expected to dst_v:NORMALIZED * approach_speed.
    lock velocity_actual to SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT.

    until dst_v:MAG < 1 { // 10 is just some precision buffer
        set approach_speed to min(max_approach_speed, get_max_breaking_speed(dst_v:MAG, rcs_acc*0.85)).
        log_only_main("iter. dist=" + dst_v:MAG + " approach_speed=" + approach_speed + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION).

        show_vect(velocity_expected, "vel expected", red, V(20, 0,0)).
        show_vect(velocity_actual, "vel actual", green, V(20, 0,0)).
        local dt is velocity_expected - velocity_actual.
        local correction is -SHIP:FACING * dt.
        set SHIP:CONTROL:TRANSLATION to correction / rcs_acc * 1.2.
        wait 0.
        set dst_v to dst_dir_v_dgt().
    }
}
function rcs_move_relative_to_target2{
    PARAMETER trgt. // VESSEL or BODY to move relative to.
    PARAMETER rel_trgt_pos.
    PARAMETER max_speed is 5.

    local approach_speed is max_speed.
    lock dst_v_f to trgt:POSITION + rel_trgt_pos.
    local dst_v is dst_v_f.
    lock velocity_expected to dst_v:NORMALIZED * approach_speed.
    lock velocity_actual to SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT.

    // Step 1. Align Prograde towards destination.
    log_only_main("Aligning prograde towards destination.").
    log_only_main("Current angle is: " + VANG(velocity_actual, velocity_expected)).
    reach_relative_speed_to_target(trgt, project_v(velocity_actual, velocity_expected), 0.1, 0.5).
    log_only_main("Prograde is aligned towards destination.").
    log_only_main("Current angle is: " + VANG(velocity_actual, velocity_expected)).

    // Step 2. Raise velocity to the max_speed in the direction of the destination.
    local start_time is TIME:SECONDS.
    local orig_pos is dst_v.
    local orig_vel is velocity_actual.
    local max_acc_dist is orig_pos:MAG * 0.55. // 55% of the distance ahead, cannot accelerate more than that to prevent overshooting due to the momentum.
    local rcs_acc is 0.0001.
    until dst_v:MAG < 1 { // 10 is just some precision buffer
        wait 0.
        CLEARVECDRAWS().
        set dst_v to dst_v_f.
        IF (velocity_expected - velocity_actual) * dst_v > 0.5 {
            // If expected velocity is ahead of the actual velocity in the direction of the destination, then we're still accelerating.
            set rcs_acc to (velocity_actual - orig_vel):MAG / (TIME:SECONDS - start_time).
        }
        set approach_speed to min(max_speed, get_max_breaking_speed(dst_v:MAG, rcs_acc*0.85)).
        log_only_main("iter. dist=" + dst_v:MAG + " approach_speed=" + approach_speed + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION + " rcs_acc=" + rcs_acc).

        show_vect(velocity_expected, "vel expected", red, V(20, 0,0)).
        show_vect(velocity_actual, "vel actual", green, V(20, 0,0)).
        local dt is velocity_expected - velocity_actual.
        local correction is -SHIP:FACING * dt.
        set SHIP:CONTROL:TRANSLATION to correction / rcs_acc * 1.2.

    }
    // If reached the max_speed or the middle point(in fact 45% to account for errors), stop accelerating.
    // To calculate the past acceleration, find the dv and dt between now and when started the acceleration.

}
function reach_relative_speed_to_target{
    PARAMETER target.
    PARAMETER desired_rel_speed is V(0,0,0).
    PARAMETER precision is 0.1.
    PARAMETER stable_time is 5. // Time to consider the speed stable once within the precision range.
    PARAMETER logger is log_only_main.
    lock actual_rel_speed to target:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
    lock dvel_f to desired_rel_speed - actual_rel_speed.
    logger("Velocity diff is " + dvel_f:MAG).
    logger("Zeroing out relative velocity diff").
    local Kp is 0.05.
    local stable_ts is TIME:SECONDS + 5.
    local dvel is dvel_f.
    until TIME:SECONDS >= stable_ts {
        local dvel_prev is dvel.
        set dvel to dvel_f.
        local ddvel is dvel - dvel_prev.
        IF NOT (dvel:MAG < precision) {
            set stable_ts to TIME:SECONDS + stable_time.
        }ELSE{
            //            logger("Stable for " + (TIME:SECONDS - stable_ts + 5) + " seconds. dvel:MAG=" + dvel:MAG).
        }
        if abs(dvel:X) < abs(ddvel:X) {
            // If we are close to the target velocity and the velocity is not increasing, stop accelerating in that direction to prevent overshooting.
            set SHIP:CONTROL:STARBOARD to 0.
            //            logger("Stopping X translation. dvel:X=" + dvel:X + " ddvel:X=" + ddvel:X).
        }
        if abs(dvel:Y) < abs(ddvel:Y) {
            set SHIP:CONTROL:TOP to 0.
            //            logger("Stopping Y translation. dvel:Y=" + dvel:Y + " drel_vel:Y=" + ddvel:Y).
        }
        if abs(dvel:Z) < abs(ddvel:Z) {
            set SHIP:CONTROL:FORE to 0.
            //            logger("Stopping Z translation. dvel:Z=" + dvel:Z + " drel_vel:Z=" + ddvel:Z).
        }
        local dtrans is Kp * (dvel).
        local dtrans_framed is -SHIP:FACING * dtrans.
        set SHIP:CONTROL:TRANSLATION to SHIP:CONTROL:TRANSLATION - dtrans_framed.
        //        logger("dvel=" + dvel + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION + " dtrans=" + dtrans_framed).
        WAIT 0.
    }
    set SHIP:CONTROL:TRANSLATION to V(0,0,0).
    logger("Relative velocity stabilized. dvel=" + (target:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT):MAG).
}
function rcs_stop_relative_to_target{
    PARAMETER target.
    PARAMETER stable_time is 3.
    PARAMETER logger is log_only_main.
    reach_relative_speed_to_target(target, V(0,0,0), 0.1, stable_time, logger).
}