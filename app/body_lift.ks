RUNONCEPATH("0://util/app.ks").
RUNONCEPATH("0://util/maneuvers.ks").
RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/orb.ks").
function create_app_body_lift{
    function def_cfg{
        local cfg is LEXICON().
        set cfg:ALT to 100000.
        set cfg:DIR to 0.
        set cfg:AUTOSTART to TRUE.
        set cfg:COUNTDOWN to 3.
        RETURN cfg.
    }
    function app_run{
        PARAMETER app.
        local prog_done to false.

        print "Lifting to " + app:cfg:alt + " around " + SHIP:BODY:NAME.
        CLEARSCREEN.
        clearVecDraws().
        start_reading_input().
        print "Turn on SAS to start the rocket".
        toggle RCS.
        SAS OFF.
        if not app:cfg:AUTOSTART {
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
        set prograde_dir to app:cfg:DIR.
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
        local dst_apoapsis is 30000.
        set dst_apoapsis to dst_apoapsis - 200.
        set angle_func to create_angle_func(dst_apoapsis, 0.01).
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
        for part in SHIP:PARTSTAGGED("stage_on_empty") {
            print "Staging part detected: " + part.
                            local res is part:resources[0].
            
            WHEN res:AMOUNT < 0.01 and stage:number > part:separatedin THEN{
                IF prog_done {return false.}
                WAIT 0.1.
                print "Staging " + part:separatedin.
                STAGE.
                return true.
            }
        }
        local srf_radar is ALT:RADAR.
        lock ground_clearance to ALT:RADAR - srf_radar.
        IF app:cfg:COUNTDOWN > 0 {
            LOCK THROTTLE TO twr2throttle(0.95).
            LOCK STEERING TO LOOKDIRUP(dirup:forevector, SHIP:facing:upvector).
            print("Launch in...").
            countdown(app:cfg:COUNTDOWN).
        }
        STAGE.
        LOCK THROTTLE TO twr2throttle(1.5).
        WAIT UNTIL prog_done or ground_clearance > 10.
        if prog_done return.

        // After 10m clearance orient the ship.
        LOCK STEERING TO dirup.

        // WAIT UNTIL prog_done or VDOT(SHIP:VELOCITY:SURFACE, SHIP:UP:VECTOR) > 50.
        // if prog_done return.
        WAIT UNTIL prog_done or ground_clearance > 50.
        if prog_done return.
        LOCK STEERING TO prograde_east.
        LOCK THROTTLE TO calc_throttle().
        if prog_done return.
        PRINT "CLEARENCE > 50".
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
        PRINT "attack_angle to 110".
        LOCK THROTTLE to 0.
        // lock upApref to (positionAt(SHIP, TIME+eta:apoapsis) - BODY:position):normalized.
        LOCK THROTTLE to twr2throttle(0.3).
        set dst_apoapsis to dst_apoapsis + 180.
        WAIT UNTIL prog_done or OBT:APOAPSIS > dst_apoapsis.
        if prog_done return.
        print "Apoapsis - 20 reached!".
        // lock upApref to (positionAt(SHIP, TIME+eta:apoapsis) - BODY:position):normalized.
        LOCK THROTTLE to twr2throttle(0.01).
        
        wait until vang(prograde_east:forevector, ship:facing:vector) < 1.
        print "The ship is facing the right direction".

        set dst_apoapsis to dst_apoapsis + 20.
        WAIT UNTIL prog_done or OBT:APOAPSIS > dst_apoapsis.
        LOCK THROTTLE to 0.
        print "Apoapsis reached!".
        LOCK attack_angle to 90.

        // lock upApref to upref.
        // local dirvector to ANGLEAXIS(prograde_dir,upref) * north:forevector.
        // lock dirup to ANGLEAXIS(-90,upApref) * lookDirUp(upApref, dirvector).
        // lock prograde_east to ANGLEAXIS(-attack_angle,dirvector)*dirup.
        // LOCK STEERING TO prograde_east.
        // show_vect(prograde_east:forevector *20).
        local time_till_burn is 99999.
        LOCK attack_angle to 89.

        print "Preparing for the maneuver".
        LOCK THROTTLE TO 0.
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
        
        UNLOCK STEERING.
        UNLOCK THROTTLE.
        exec_node(circular_obt).
        stop_reading_input().
        SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    }
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
    RETURN create_app("BODY_LIFT", app_run@, def_cfg()).
}