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
    local aux_dir_v is dst_dir_v_dgt().
    lock velocity_expected to aux_dir_v:NORMALIZED * approach_speed.
    lock velocity_actual to SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT.

    until aux_dir_v:MAG < 1 { // 10 is just some precision buffer
        set approach_speed to min(max_approach_speed, get_max_breaking_speed(aux_dir_v:MAG, rcs_acc*0.85)).
        log_only_main("iter. dist=" + aux_dir_v:MAG + " approach_speed=" + approach_speed + " SHIP:CONTROL:TRANSLATION=" + SHIP:CONTROL:TRANSLATION).
        CLEARVECDRAWS().
//        show_vect(aux, "aux", blue, app:cfg:target_port:POSITION).
        show_vect(velocity_expected, "vel expected", red, V(20, 0,0)).
        show_vect(velocity_actual, "vel actual", green, V(20, 0,0)).
        local dt is velocity_expected - velocity_actual.
        local correction is -SHIP:FACING * dt.
        set SHIP:CONTROL:TRANSLATION to correction / rcs_acc * 1.2.
        wait 0.
        set aux_dir_v to dst_dir_v_dgt().
    }
}