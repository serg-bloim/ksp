// #include utils.ks
RUNONCEPATH("/util/utils.ks").
local flight_log_path to "/log/flight-test.log".
deletePath(flight_log_path).
declare function flight_log{
    parameter msg.
    log msg to flight_log_path.
}
declare function release_controlls{
    SET SHIP:CONTROL:NEUTRALIZE to TRUE.
}
declare function vang2{
    parameter v1.
    parameter v2.
    local res is vang(v1, v2).
    if vang(UP:VECTOR, VCRS(v1, v2)) > 90{
        set res to - res.
    }
    return res.
}
declare function compass{
    parameter dir is FACING.
    if dir:ISTYPE("Direction"){
        set dir to dir:forevector.
    }
    return mod(360+vang2(NORTH:vector, VXCL(UP:VECTOR, dir)),360).
}
declare function angle180{
    // Returns a relative angle from angle `from` to angle `to`
    parameter from,to.
    local diff to mod(to - from,360).
    if diff > 180{
        return diff-360.
    } else if diff < -180{
        return diff + 360.
    }else{
        return diff.
    }
}
declare function angle_diff{
    parameter from, to, dir is 0.
    local rel_angle to angle180(from, to).
    if dir = 0 return rel_angle.
    if rel_angle*dir >= 0{
        return rel_angle*dir.
    } else{
        return rel_angle*dir + 360.
    }
}


declare function vector_along_geo{
    parameter start. // vector
    parameter dir.   // vector
    parameter dist.  // scalar, meters.
    parameter alt is -1. // altitude above sea lvl
    parameter body is SHIP:BODY.
    local bc is body:POSITION.
    local v1 is start - bc.
    local r is v1:MAG.
    if alt = -1 {
        set alt to r.
    }else{
        set alt to body:RADIUS + alt.
    }
    local alpha is 360 * dist / (2 * CONSTANT:PI * r).
    local rot is ANGLEAXIS(alpha,VCRS(v1, dir)).
    local res is rot*v1.
    set res:MAG to alt.
    return bc + res.
}
declare function horizon_roll{
    parameter dir to ship:facing.
    local hrzn to UP.
    local dirUp to vxcl(dir:forevector, hrzn:forevector).
    local adiff to vAng(dirUp, dir:upvector).
    if adiff > 0 and adiff < 180 {
        if dir:starvector * dirUp > 0{
            set adiff to -adiff.
        }
    }
    return adiff.
}
local always_false is {return false.}.
declare function wide_turn{
    parameter   dst,
                direction is 0,  // +-1
                precision is 1,
                stop_predicate is always_false.
    local start_azimuth to compass().
    flight_log("Start wide_turn()" ).
    flight_log( "   dst type      = " + (choose "point" if dst:istype("vector") else "azimuth") ).
    flight_log( "   dst           = " + dst ).
    flight_log( "   start_azimuth = " + start_azimuth ).
    flight_log( "   direction     = " + direction ).
    local dst_azimuth_func to {return dst.}.
    if dst:istype("vector"){
        local dst_rel to dst - ship:body:position.
        set dst_azimuth_func to {return compass(ship:body:position + dst_rel).}.
    }
    if direction = 0{
        set direction to choose 1 if dst_azimuth_func() - start_azimuth > 0 else -1.
        flight_log( "   set direction to " + direction ).
    }
    local pitchPID to PIDLOOP(
            1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                    0.000000000000000000000001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                    0.000000000000000000000001,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                    -1,   // min possible throttle is zero.
                    1    // max possible throttle is one.
            ).
    // we set pitch setpoint to 2° above horizon.
    // So if actual pitch if higher, it will do nothing, but if it is on 0(where it should be),
    // it will try to raise and then, roll will try to lower the prograde back to 0°
    set pitchPID:SETPOINT to 2. 
    local rollPID to PIDLOOP(
            0.001,   // adjust throttle 0.1 per 5m in error from desired altitude.
                    0.0001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                    0.03,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                    -0.2,   // min possible throttle is zero.
                    0.2    // max possible throttle is one.
            ).
    set rollPID:SETPOINT to 0.
    SAS OFF.
    local max_pitch to 5.
    until 0 {
        set prnt_n to 10.
        local UPPROGRADE is SHIP:VELOCITY:ORBIT * UP:VECTOR.
        local pitch to pitchPID:UPDATE(TIME:SECONDS, UPPROGRADE).
        local current_comp to compass().
        local dst_azimuth to dst_azimuth_func().
        local adiff to abs(angle_diff(current_comp, dst_azimuth)).

        local  actual_roll to horizon_roll().
        local actual_pitch to 90 - vectorangle(ship:up:forevector, ship:prograde:FOREVECTOR).
        local dir_modifier to 1.
        if actual_pitch < 0{
            set pitch to 1.
        }else {
            set pitch to cap(abs(adiff), 0, max_pitch)/max_pitch.
            set dir_modifier to cap(1-(direction*(90+actual_pitch)-actual_roll)/90,0,1).
        }
        if RCS{
            set  ship:control:pitch to pitch*dir_modifier.
        }
        local wrong_dir_pitch_penalty to 0.
        if actual_roll * direction < 0{
            // if roll and dir are different directions, add penalty
            set wrong_dir_pitch_penalty to 90.
            if actual_roll * direction < -90{
                set wrong_dir_pitch_penalty to direction*90.
            }
        }
        local roll to 0.
        if RCS{
            set roll to -direction * rollPID:UPDATE(TIME:SECONDS, actual_pitch+wrong_dir_pitch_penalty).
        }
        set ship:control:roll to roll.
        prnt("start_azimuth ", start_azimuth).
        prnt("dst_azimuth  ", dst_azimuth).
        prnt("adiff        ", adiff).
        prnt("UPPROGRADE   ", UPPROGRADE).
        prnt("pitch        ", pitch).
        prnt("dir_modifier ", dir_modifier).
        prnt("actual_pitch ", actual_pitch).
        prnt("actual_roll  ", actual_roll).
        prnt("wdpp         ", wrong_dir_pitch_penalty).
        prnt("roll         ", roll).
        prnt("current_comp ", current_comp).
        prnt("SRFPROGRADE  ", compass(SRFPROGRADE:VECTOR)).
        prnt("comp         ", compass()).
        if adiff < precision or stop_predicate(){
            break.
        }
        wait 0.01.
    }
    release_controlls().
}

declare function precise_turn{
    parameter   dst, // scalar for azimuth or vector for a point.
                dst_pitch is 0,
                stable4 is 3,
                presition is 1.
    local pitchPID to PIDLOOP(
        0.01, 
        0.01, 
        0.000000000000000001, 
        -1,    
        1      
        ).

    set pitchPID:SETPOINT to 0.
    local rollPID to PIDLOOP(
        0.001,  
        0.0001, 
        0.001,   
        -0.2,   
        0.2  
        ).
    flight_log( "   dst type      = " + (choose "point" if dst:istype("vector") else "azimuth") ).
    local dst_azimuth_func to {return dst.}.
    if dst:istype("vector"){
        local dst_rel to dst - ship:body:position.
        set dst_azimuth_func to {return compass(ship:body:position + dst_rel).}.
    }
    local adiff to 999999.
    local actual_pitch to 0.
    local lock comperr to adiff.
    local lock pitcherr to actual_pitch - dst_pitch.
    local end_cond to create_condition(stable4, {return abs(adiff) < presition and abs(actual_pitch - dst_pitch) < presition.}).
    local sasRevert to SasOffBackup().
    until 0 {
        set prnt_n to 10.
        local actual_comp to compass().
        local dst_azimuth to dst_azimuth_func().
        set adiff to cap(dst_azimuth - actual_comp, -10, 10).
        local angle_dist to sqrt(adiff^2 + (actual_pitch - dst_pitch)^2).
        local actual_roll to horizon_roll().
        local desired_roll to cap(-0.015196457909201211 * adiff*adiff*adiff + -2.1807000649687325e-12 * adiff*adiff + 11.567082346531924 * adiff + -2.2155610679419624e-12, -90, 90).
        set actual_pitch to 90 - vectorangle(ship:up:forevector, ship:prograde:FOREVECTOR).
        set rollPID:setpoint to desired_roll.
        local roll to rollPID:update(time:seconds, actual_roll).
        local roll_diff to abs((90 - actual_roll) - (arcTan2(dst_pitch-actual_pitch, dst_azimuth-actual_comp))).
        local roll_modifier to cap((90 - roll_diff)/90, -1, 1).
        local pitch to pitchPID:update(time:seconds, -angle_dist*roll_modifier).
        if end_cond(){
            break.
        }
        prnt("dst_azimuth  ", dst_azimuth).
        prnt("actual_comp  ", actual_comp).
        prnt("adiff        ", adiff).
        prnt("actual_pitch ", actual_pitch).
        prnt("dst_pitch    ", dst_pitch).
        prnt("actual_roll  ", actual_roll).
        prnt("desired_roll ", desired_roll).
        prnt("roll_diff    ", roll_diff).
        prnt("roll_modifier", roll_modifier).
        prnt("angle_dist   ", angle_dist).
        prnt("pitchPID     ", -angle_dist*roll_modifier).
        prnt("roll         ", roll).
        prnt("pitch        ", pitch).
        prnt("comperr      ", comperr).
        prnt("pitcherr     ", pitcherr).
        set ship:control:roll to roll.
        set ship:control:pitch to pitch.
        wait 0.01.
    }
    sasRevert().
    release_controlls().
}
declare function turn{
    parameter dst, dir is 0, dst_pitch is 0.
    local azimuth to compass().
    local dst_compass to dst.
    local rel_dst to dst.
    if dst:istype("vector"){
        set rel_dst to dst - ship:body:position.
        set dst_compass to compass(dst).
    }
    local ang_diff to angle_diff(azimuth, dst_compass, dir).
    flight_log("Start wide_turn()").
    flight_log("ang_diff = " + ang_diff).
    if abs(ang_diff) > 10{
        flight_log( "Start wide turn" ).
        wide_turn(dst, dir, 10).
    }
    flight_log( "Start precise turn" ).
    if dst:istype("vector"){
        set dst to rel_dst + ship:body:position.
    }
    precise_turn(dst, dst_pitch).
    flight_log( "Finished turn").
    release_controlls().
}
declare function fly2point{
    parameter dst.
    local lock bc to SHIP:BODY:POSITION.
    local rel_dst is dst - bc.
    local lock dst2 to bc + rel_dst.
    local sasrecovery to SasOffBackup().

   unlock STEERING.
   unlock THROTTLE.
   sasrecovery().

}
declare function prepare_landing{
    parameter wp1.
    parameter wp2.
    local lock p1 to wp1:POSITION.
    local lock p2 to wp2:POSITION.
    local lock soi to SHIP:BODY:POSITION.
    local vd1 is VECDRAW(p1,(p2-p1), green, "", 1, true).
    local lock c to vector_along_geo(p1, p1-p2, 30e3, 1000).
    local vd2 is VECDRAW(p1,(c-p1), blue, "", 1, true).
    local lock norm to VCRS(p1-soi,p2-soi).
    local lock c1 to vector_along_geo(c, norm, 10e3).
    local lock c2 to vector_along_geo(c, -norm, 10e3).
    local dir to 1.
    if c2:MAG < c1:MAG{
        set dir to -1.
    }
    local lock c_goal to vector_along_geo(c, dir * norm, 1e3).

    local vd3 is VECDRAW(c,(c_goal-c), red, "c1", 1, true).
    set vd1:STARTUPDATER to {return p1.}.
    set vd1:VECUPDATER to {return p2-p1.}.
    set vd2:STARTUPDATER to {return p1.}.
    set vd2:VECUPDATER to {return c-p1.}.
    set vd3:STARTUPDATER to {return c.}.
    set vd3:VECUPDATER to {return c_goal-c.}.
    declare function update{
        // set vd1:START to p1.
        // set vd1:VEC to p2-p1.

        // set vd2:START to p1.
        // set vd2:VEC to c-p1.

        // set vd3:START to c.
        // set vd3:VEC to c_goal-c.

        // print(norm) at(10,10).
    }
    // ON c{

    // }
    CLEARSCREEN.
    print("Dir to C "+ compass(c_goal)).
    wide_turn(compass(c_goal), dir).
    update().
    CLEARSCREEN.
    print("Go to C").
    fly2point(c_goal).
    update().
    unlock STEERING.
    unlock THROTTLE.
    CLEARSCREEN.
    print("wide turn").
    wide_turn(compass(p2-p1), dir).
    update().
    print("Done").
    unset vd1.
    unset vd2.
    unset vd3.
}