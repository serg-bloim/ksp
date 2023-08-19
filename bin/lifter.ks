@CLOBBERBUILTINS on.
parameter autostart is false.
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/orb.ks").
declare function do_lifter{
    parameter autostart.
    local prog_done to false.
    function create_angle_func{
        parameter h is 80000, b is 0.25, c is 2, a is 80, off is 0.
        return {
            parameter _alt.
            if _alt<=0 {
                RETURN off.
            }
            return a/(1+b*((_alt/h)^(-c) - 1)) + off.
        }.
    }
    function internal{
            // CLEARSCREEN.
            clearVecDraws().
            start_reading_input().
            local prograde_dir to 3.
            local prograde_dirs to list("East", "South", "West","North").
            local changing_prograde_dir to true.
            ON RCS{
                IF prog_done {return false.}
                if changing_prograde_dir {
                    set prograde_dir to mod(prograde_dir + 1,prograde_dirs:length).
                    print "Ready to lift rocket to the " + prograde_dirs[prograde_dir] at (0,2).
                }
                return changing_prograde_dir.
            }
            print "Turn on SAS to start the rocket".
            toggle RCS.
            wait until prograde_dir = 0.
            SAS OFF.
            if not autostart{
                local autostart_trigger to false.
                when autostart_trigger or last_read_char:tolower() = "t" then{
                    IF prog_done {return false.}
                    if autostart_trigger{
                        return.
                    }
                    SAS ON.
                }
                WAIT UNTIL SAS.
                set autostart_trigger to true.
            }
            when last_read_char:tolower() = "q" then{
                    IF prog_done {return false.}
                    print "Detected 'q', exiting".
                    set prog_done to true.
                }
            RCS OFF.
            CLEARSCREEN.
            print "prograde_dir is " + prograde_dir + "(" +prograde_dirs[prograde_dir]+ ")".
            local prograde_dirs to list(0, 90+13, 180, -90-13).
            set prograde_dir to prograde_dirs[prograde_dir].
            print "prograde_dir is " + prograde_dir.
            set changing_prograde_dir to false.

            function createApVelocityTracker{
                local lastApVal is OBT:apoapsis.
                local lastUpdateTime is TIME:seconds.
                local lastApVelocity is 0.
                return {
                    if TIME:SECONDS - lastUpdateTime > 0{
                        local ap is OBT:apoapsis.
                        set lastApVelocity to (ap - lastApVal) / (TIME:SECONDS - lastUpdateTime).
                        set lastUpdateTime to TIME:SECONDS.
                        set lastApVal to ap.
                    }
                    return lastApVelocity.
                }.
            }
            local apVelTracker is createApVelocityTracker().
            lock upref to up:forevector.
            lock upApref to upref.
            // lock upApref to (positionAt(SHIP, TIME+eta:apoapsis) - BODY:position):normalized.
            local dirvector to ANGLEAXIS(prograde_dir,upref) * north:forevector.
            lock dirup to ANGLEAXIS(-90,upApref) * lookDirUp(upApref, dirvector).
            SAS OFF.
            local dst_apoapsis is 80000.
            set dst_apoapsis to dst_apoapsis - 1000.
            set angle_func to create_angle_func(dst_apoapsis).
            lock attack_angle to angle_func(SHIP:altitude).
            local smoothThrottle is create_angle_func(500, 0.25, 2, 1, 0.05).
            function calc_throttle{
                // return 1.
                local angleVsApoapsis is VANG(upApref, ship:facing:forevector).
                local dAp is dst_apoapsis - OBT:APOAPSIS.
                local dApPos is CHOOSE dAp if dAp >=0 else 0.
                local throttle_ is smoothThrottle(dApPos) / cos(angleVsApoapsis).
                // print "ApAngle: " + round(angleVsApoapsis, 2) + " dAp: " + round(dAp, 2) + " throttle_: " + round(throttle_, 2) + " smoothThrottle(dAp): " + round(smoothThrottle(dAp), 2).
                return CHOOSE throttle_ if dAp > 0 else 0.
            }
            lock prograde_east to ANGLEAXIS(-attack_angle,dirvector)*dirup.
            LOCK STEERING TO dirup.
            LOCK STEERING TO prograde_east.
            LOCK THROTTLE TO twr2throttle(2.87e-05 * SHIP:ALTITUDE + 0.95).
            local stage_cnt to 1.
            for p in SHIP:PARTSTAGGED("stage_on_empty") {
                print "Staging part detected: " + p:NAME.
                local res is p:RESOURCES[0].
                local stage_iter to stage_cnt.
                set stage_cnt to stage_cnt + 1.
                WHEN res:AMOUNT < 0.01 THEN{
                    IF prog_done {return false.}
                    WAIT 0.1.
                    print "Staging " + stage_iter.
                    STAGE.
                }
            }
            print("Launch in...").
            // countdown(3).

            STAGE.
            LOCK THROTTLE TO calc_throttle().
            // UNLOCK THROTTLE.
            // wait 30.

            // set dir_east_10degree to ANGLEAXIS(-9.5,dirvector)*dirup.
            // set dir_east_10degree to lookDirUp(dir_east_10degree:forevector, ship:up:forevector).
            // show_rot(dir_east_10degree).

            WAIT UNTIL prog_done or VDOT(SHIP:VELOCITY:SURFACE, SHIP:UP:VECTOR) > 100.
            if prog_done return.
            PRINT "SPEED > 100 m/s".
            // LOCK STEERING TO dir_east_10degree.
            WAIT UNTIL prog_done or SHIP:ALTITUDE > 10000.
            if prog_done return.
            PRINT "ALTITUDE > 10k".
            // LOCK THROTTLE TO twr2throttle(10).

            //ON attack_angle{
            //    print (round(attack_angle,2)) at (5,3).
            //    return true.
            //}
            // WHEN SHIP:ALTITUDE > 30000 THEN{
            //     if prog_done return.
            //     PRINT "ALTITUDE > 30k".
            //     SET NAVMODE to "ORBIT".
            // }
            WAIT UNTIL prog_done or OBT:APOAPSIS > dst_apoapsis.
            if prog_done return.
            print "Apoapsis - 1000 reached!".
            WAIT UNTIL prog_done or SHIP:ALTITUDE > 40000.
            if prog_done return.
            PRINT "ALTITUDE > 40k".
            PRINT "attack_angle to 85".
            LOCK THROTTLE to twr2throttle(0.1).
            LOCK attack_angle to 85.
            lock upApref to (positionAt(SHIP, TIME+eta:apoapsis) - BODY:position):normalized.
            
            wait until vang(prograde_east:forevector, ship:facing:vector) < 1.
            print "The ship is facing the right direction".
            
            LOCK THROTTLE TO calc_throttle().
            set dst_apoapsis to dst_apoapsis + 1000.
            WAIT UNTIL prog_done or OBT:APOAPSIS > dst_apoapsis.
            print "Apoapsis reached!".
            LOCK attack_angle to 90.

            // lock upApref to upref.
            // local dirvector to ANGLEAXIS(prograde_dir,upref) * north:forevector.
            // lock dirup to ANGLEAXIS(-90,upApref) * lookDirUp(upApref, dirvector).
            // lock prograde_east to ANGLEAXIS(-attack_angle,dirvector)*dirup.
            // LOCK STEERING TO prograde_east.
            // show_vect(prograde_east:forevector *20).
            WAIT UNTIL prog_done or SHIP:ALTITUDE > 50000.
            if prog_done return.
            local time_till_burn is 99999.
            LOCK attack_angle to 89.
            SET circular_obt to NODE(TIME + 100, 0, 0, 10).
            ADD circular_obt.
            until time_till_burn < 15{
                print "Preparing for the maneuver".
                LOCK THROTTLE TO calc_throttle().
                wait 5.
                LOCK THROTTLE TO 0.
                remove circular_obt.
                set ut to TIMESTAMP() + SHIP:OBT:ETA:APOAPSIS.
                set velocity_at_ap to VELOCITYAT(SHIP, ut):ORBIT:MAG.
                set circular_obt_velocity to circularOrbDv(OBT:apoapsis).
                set dv to circular_obt_velocity-velocity_at_ap.
                SET circular_obt to NODE(ut, 0, 0, dv ).
                ADD circular_obt.
                set time_till_burn to circular_obt:ETA - get_burn_duration(dv/2).
                print "velocity at AP: " + velocity_at_ap.
                print "required velocity at AP: " + circular_obt_velocity.
                print "DV: " + dv.
                print "time_till_burn: " + time_till_burn.
            }
            
            UNLOCK STEERING.
            UNLOCK THROTTLE.
            exec_node(circular_obt).
            stop_reading_input().
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

    }
    internal.
    set prog_done to true.
    unlock steering.
    unlock throttle.
    SAS ON.
    print "DONE".
}
do_lifter(autostart).