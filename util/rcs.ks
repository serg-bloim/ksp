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

    // Step 1. Stop relative to target.
    // We could skip stopping. But it needs to be tested. One concern is if rcs_acc will be calculated properly with some initial velocity sideways.

    log_only_main("Killing any relative velocity to the target before aligning.").
    log_only_main("Current relative velocity : " + velocity_actual:MAG ).
    rcs_stop_relative_to_target(trgt, 1, log_only_main).
    log_only_main("Stopped relative to the target").
    log_only_main("Current relative velocity : " + velocity_actual:MAG).

    // Step 2. Raise velocity to the max_speed in the direction of the destination.
    local start_time is TIME:SECONDS.
    local orig_pos is dst_v.
    local orig_vel is velocity_actual.
    local max_acc_dist is orig_pos:MAG * 0.55. // 55% of the distance ahead, cannot accelerate more than that to prevent overshooting due to the momentum.
    local min_acc_speed is min(1, max_speed).
    local rcs_acc is (min_acc_speed ^ 2) / 2 / dst_v:MAG. // this init rcs_acc helps to start moving if dst_v is small.
    until dst_v:MAG < 1 { // 10 is just some precision buffer
        wait 0.
        CLEARVECDRAWS().
        set dst_v to dst_v_f.
        show_vect(rel_trgt_pos, "dst_v", white, trgt:POSITION).
        local updated_acc is FALSE.
        IF (velocity_expected - velocity_actual) * dst_v:NORMALIZED > 0.3 // If expected velocity is ahead of the actual velocity in the direction of the destination, then we're still accelerating.
                AND (velocity_actual - orig_vel):MAG > 0.3 // If velocity_actual is already higher than the original velocity, then ship has done some acceleration already
        {

            set rcs_acc to (velocity_actual - orig_vel):MAG / (TIME:SECONDS - start_time).
            log_only_main("velocity_expected=" + velocity_expected + " velocity_actual=" + velocity_actual + " abc=" + ((velocity_expected - velocity_actual) * dst_v:NORMALIZED   )).
            set updated_acc to TRUE.
        }
        set approach_speed to min(max_speed, get_max_breaking_speed(dst_v:MAG, rcs_acc*0.85)).
        if dst_v:MAG > max_acc_dist AND approach_speed < min_acc_speed {
            // If we're far from breaking, then we should maintain a minimal speed to prevent the ship from stalling.
            set approach_speed to min_acc_speed.
        }
        log_only_main("iter. dist=" + dst_v:MAG + " approach_speed=" + approach_speed + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION + " rcs_acc=" + rcs_acc + " updated_acc: " + updated_acc).

        show_vect(velocity_expected, "vel expected", red, V(20, 0,0)).
        show_vect(velocity_actual, "vel actual", green, V(20, 0,0)).
        local dt is velocity_expected - velocity_actual.
        local correction is -SHIP:FACING * dt.
        set SHIP:CONTROL:TRANSLATION to correction / rcs_acc * 1.2.

    }
    log_only_main("Arrived to the destination. Stopping the final velocity: " + velocity_actual:MAG).
    rcs_stop_relative_to_target(trgt, 1, log_only_main).
    log_only_main("Stopped relative to the target. Dist is " + dst_v:MAG).
    log_only_main("Current relative velocity : " + velocity_actual:MAG).
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
//    local KpX is Kp.
//    local KpY is Kp.
//    local KpZ is Kp.
    local stable_ts is TIME:SECONDS + 5.
    local dvel is dvel_f.
    local dvel_rel is V(0,0,0).
    until TIME:SECONDS >= stable_ts {
        local dvel_prev is dvel.
        set dvel to dvel_f.
        local dvel_rel_prev is dvel_rel.
        set dvel_rel to -SHIP:FACING * dvel. // Velocity in Ship's reference frame.
        logger("dvel=" + dvel + " d_vel_rel=" + dvel_rel).
        IF NOT (dvel_rel:MAG < precision) {
            set stable_ts to TIME:SECONDS + stable_time.
        }ELSE{
            //            logger("Stable for " + (TIME:SECONDS - stable_ts + 5) + " seconds. dvel:MAG=" + dvel:MAG).
        }
        if dvel_rel:X * dvel_rel_prev:X < 0 {
            // If we are close to the target velocity and the velocity is not increasing, stop accelerating in that direction to prevent overshooting.
            set SHIP:CONTROL:STARBOARD to 0.
        }
        if dvel_rel:Y * dvel_rel_prev:Y < 0 {
            set SHIP:CONTROL:TOP to 0.
        }
        if dvel_rel:Z * dvel_rel_prev:Z < 0 {
            set SHIP:CONTROL:FORE to 0.
        }
        local dtrans is Kp * dvel_rel.
        set SHIP:CONTROL:TRANSLATION to SHIP:CONTROL:TRANSLATION - dtrans.
                logger("dvel=" + dvel + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION + " dtrans=" + dtrans).
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
function rcs_thrusters_remove_rotation{
    LIST RCS IN rcs_parts.
    local restore is LIST().
    local restore_fields is LIST("YAWENABLED", "PITCHENABLED", "ROLLENABLED").
    for p in rcs_parts {
        local restore_item is LEXICON("part", p, backup, LEXICON()).
        for f in restore_fields {
            set restore_item:backup[f] to p[f].
        }
        set p:YAWENABLED to FALSE.
        set p:PITCHENABLED to FALSE.
        set p:ROLLENABLED to FALSE.
        restore:add(restore_item).
    }
    RETURN restore.
}
function rcs_thrusters_restore{
    PARAMETER backup.
    LIST RCS IN rcs_parts.
    local restore_fields is LIST("YAWENABLED", "PITCHENABLED", "ROLLENABLED").
    for bitem in backup {
        local p is bitem["part"].
        for f in restore_fields {
            set p[f] to restore_item:backup[f].
        }
    }
}