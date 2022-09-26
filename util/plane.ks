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
    parameter dir is FACING:VECTOR.
    return mod(360+vang2(NORTH:vector, VXCL(UP:VECTOR, dir)),360).
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
declare function fly2point{
    parameter dst.
    local lock bc to SHIP:BODY:POSITION.
    local rel_dst is dst - bc.
    local lock dst2 to bc + rel_dst.
    SAS OFF.
    LOCK THROTTLE to 1.

    until dst2:MAG > 1000{
        LOCK STEERING to dst2.
        wait 0.1.
    }
//    unlock STEERING.
//    unlock THROTTLE.
//    SAS ON.
//    KUniverse:PAUSE().

}
declare function prnt{
    parameter lbl.
    parameter val is "".
    print (lbl + " : " + val + "                 ") at (1,prnt_n).
    set prnt_n to prnt_n+1.
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
    parameter direction.  // +-1
    local start_azimuth to compass().
    if (dst_azimuth - start_azimuth)*direction < 0{
        // If it needs to cross 0° or 360°
        set start_azimuth to start_azimuth - direction * 360.
    }
    set pitchPID to PIDLOOP(
            0.001,   // adjust throttle 0.1 per 5m in error from desired altitude.
                    0.001,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                    0.001,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                    -1,   // min possible throttle is zero.
                    1    // max possible throttle is one.
            ).

    set pitchPID:SETPOINT to 0.
    local max_roll to 0.1.
    set rollPID to PIDLOOP(
            0.01 * max_roll,   // adjust throttle 0.1 per 5m in error from desired altitude.
                    0.001  * max_roll,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                    0.001  * max_roll,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                    -1 * max_roll,   // min possible throttle is zero.
                    1 * max_roll    // max possible throttle is one.
            ).
    // set rollPID:KP to 0.
    set rollPID:KI to 0.
    set rollPID:KD to 0.
    set rollPID:SETPOINT to 0.
    SAS OFF.
    local max_pitch to 15.
    until 0 {
        set prnt_n to 5.
        local UPPROGRADE is SHIP:VELOCITY:ORBIT * UP:VECTOR.
        local pitch to pitchPID:UPDATE(TIME:SECONDS, UPPROGRADE).
    //        SET PITCH TO 0.
        LOCAL current_comp to compass().
        local adiff to dst_azimuth-start_azimuth.

        set pitch to cap(abs(adiff), 0, max_pitch)/max_pitch/2.
        set  ship:control:pitch to pitch.
        local actual_pitch to 90 - vectorangle(ship:up:forevector, ship:prograde:FOREVECTOR).
        local actual_roll to horizon_roll().
        local wrong_dir_pitch_penalty to 0.
        if actual_roll * direction > 0{
            // if roll and dir are different directions, add penalty
            set wrong_dir_pitch_penalty to 2*max_pitch-actual_pitch.
        }
        local roll to rollPID:UPDATE(TIME:SECONDS, actual_pitch+wrong_dir_pitch_penalty).
        set ship:control:roll to roll.
        prnt("adiff        ", adiff).
        prnt("pitch        ", pitch).
        prnt("actual_pitch ", actual_pitch).
        prnt("actual_roll  ", actual_roll).
        prnt("wdpp         ", wrong_dir_pitch_penalty).
        prnt("roll         ", roll).
        prnt("current_comp ", current_comp).
        prnt("SRFPROGRADE  ", compass(SRFPROGRADE:VECTOR)).
        prnt("comp         ", compass()).
        if abs(adiff) < 10{
            break.
        }
        wait 0.01.
    }
    // LOCK STEERING to HEADING(dst_azimuth, 0, 0).
    local lock roll_angle to 90 - vectorangle(ship:up:forevector, ship:facing:STARVECTOR).
    print ("Fine tuning").
    local a is 10.
    UNTIL a < 1 and roll_angle < 1{
        wait 0.01.
        set a to ABS(dst_azimuth-compass()).
        print ("azimuth          : " + a) at (3,10).
        print ("roll_angle       : " + roll_angle) at (3,11).
    }
    wait 3.
    UNLOCK STEERING.
    UNLOCK THROTTLE.
    SAS ON.
    print ("DONE.").
}

declare function prepare_landing{
    parameter wp1.
    parameter wp2.
    lock p1 to wp1:POSITION.
    lock p2 to wp2:POSITION.
    lock soi to SHIP:BODY:POSITION.
    local vd1 is VECDRAW(p1,(p2-p1), green, "", 1, true).
    lock c to vector_along_geo(p1, p1-p2, 30e3, 1000).
    local vd2 is VECDRAW(p1,(c-p1), blue, "", 1, true).
    lock norm to VCRS(p1-soi,p2-soi).
    lock c1 to vector_along_geo(c, norm, 10e3).
    lock c2 to vector_along_geo(c, -norm, 10e3).
    lock c_goal to c1.
    local dir to 1.
    if c2:MAG < c1:MAG{
        lock c_goal to c2.
        set dir to -1.
    }
    local vd3 is VECDRAW(c,(c_goal-c), red, "c1", 1, true).

    ON c{
        set vd1:START to p1.
        set vd1:VEC to p2-p1.

        set vd2:START to p1.
        set vd2:VEC to c-p1.

        set vd3:START to c.
        set vd3:VEC to c_goal-c.

        print(norm) at(10,10).
        PRESERVE.
    }
    print("Dir to C").
    wide_turn(compass(c_goal), dir).
    print("Go to C").
    fly2point(c_goal).
    wait until vxcl(UP:VECTOR, c_goal):MAG < 1000.
    unlock STEERING.
    unlock THROTTLE.
    print("wide turn").
    wide_turn(compass(p2-p1), dir).
    print("Done").
}