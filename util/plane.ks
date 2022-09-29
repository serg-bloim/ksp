// #include utils.ks
RUNONCEPATH("/util/utils.ks").
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
    parameter a1.
    parameter a2.
    local res to 0.
    set res to mod(a2-a1,360).
    if res < 0{
        set res to res + 360.
    }
    return res.
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
declare function wide_turn{
    parameter dst_azimuth.
    parameter direction is 0.  // +-1
    parameter stabilize4 is 3.  // +-1
    local start_azimuth to compass().
    log "Start wide_turn()" to "/log/flight-test.log".

    log "   dst_azimuth   = " + dst_azimuth to "/log/flight-test.log".
    log "   start_azimuth = " + start_azimuth to "/log/flight-test.log".
    log "   direction     = " + direction to "/log/flight-test.log".

    if direction = 0{
        set direction to choose 1 if dst_azimuth - start_azimuth > 0 else -1.
        log "   set direction to " + direction to "/log/flight-test.log".
    }
    if (dst_azimuth - start_azimuth)*direction < 0{
        // If it needs to cross 0° or 360°
        set start_azimuth to start_azimuth - direction * 360.
    }
    local pitchPID to PIDLOOP(
            0.001,   // adjust throttle 0.1 per 5m in error from desired altitude.
                    0.001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                    0.001,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                    -1,   // min possible throttle is zero.
                    1    // max possible throttle is one.
            ).

    set pitchPID:SETPOINT to 0.
    local rollPID to PIDLOOP(
            0.001,   // adjust throttle 0.1 per 5m in error from desired altitude.
                    0.0001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                    0.03,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                    -0.1,   // min possible throttle is zero.
                    0.1    // max possible throttle is one.
            ).
    // set rollPID:KP to 0.
    // set rollPID:KI to 0.
    // set rollPID:KD to 0.
    set rollPID:SETPOINT to 0.
    SAS OFF.
    local max_pitch to 5.
    print ("wide turn : " + dst_azimuth).
    until 0 {
        set prnt_n to 5.
        local UPPROGRADE is SHIP:VELOCITY:ORBIT * UP:VECTOR.
        local pitch to pitchPID:UPDATE(TIME:SECONDS, UPPROGRADE).
        local  current_comp to compass().
        local adiff to compass()-dst_azimuth.

        local  actual_roll to horizon_roll().
        local actual_pitch to 90 - vectorangle(ship:up:forevector, ship:prograde:FOREVECTOR).
        local dir_modifier to cap(1-abs(direction*(90+actual_pitch)-actual_roll)/90,0,1).
        local  pitch to cap(abs(adiff), 0, max_pitch)/max_pitch.
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
        prnt("pitch        ", pitch).
        prnt("dir_modifier ", dir_modifier).
        prnt("actual_pitch ", actual_pitch).
        prnt("actual_roll  ", actual_roll).
        prnt("wdpp         ", wrong_dir_pitch_penalty).
        prnt("roll         ", roll).
        prnt("current_comp ", current_comp).
        prnt("SRFPROGRADE  ", compass(SRFPROGRADE:VECTOR)).
        prnt("comp         ", compass()).
        if abs(adiff) < 1{
            break.
        }
        wait 0.01.
    }
    // LOCK STEERING to HEADING(dst_azimuth, 0, 0).
    local lock roll_angle to 90 - vectorangle(ship:up:forevector, ship:facing:STARVECTOR).
    print ("Fine tuning").
            SET ship:control:roll to 0.
        SET ship:control:yaw to 0.
        SET ship:control:pitch to 0.
        
    LOCK STEERING to HEADING(dst_azimuth, 0, 0).
    wait_cond(stabilize4, {return ABS(dst_azimuth-compass()) < 1 and abs(roll_angle) < 1.}).
    UNLOCK STEERING.
    UNLOCK THROTTLE.
    SAS ON.
    print ("DONE.").
}

declare function fly2point{
    parameter dst.
    local lock bc to SHIP:BODY:POSITION.
    local rel_dst is dst - bc.
    local lock dst2 to bc + rel_dst.
    local sasrecovery to SasOffBackup().
    LOCK THROTTLE to 1.

    until vxcl(UP:VECTOR, dst2):MAG < 1000{
        LOCK STEERING to dst2.
        print("Compass: " + compass()) at (1,2).
        print("dist: " + vxcl(UP:VECTOR, dst2):MAG) at (1,2).
        wait 0.1.
    }
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