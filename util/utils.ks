declare function cap{
    parameter val.
    parameter min is 0.
    parameter max is 0.
    if val < min{
        return min.
    }
    if val > max{
        return max.
    }
    return val.
}
declare function countdown{
    declare parameter cnt is 10.
    declare parameter delay is 1.
    UNTIL cnt = 0 {
        PRINT cnt.
        SET cnt to cnt - 1.
        WAIT delay.
    }
    PRINT "0".
}
local ESC is CHAR(27).
declare function wait_until_esc{
    until terminal:input:getchar = ESC{

    }
}
declare function esc_pressed{
    return terminal:input:haschar and terminal:input:getchar = ESC.
}
declare function twr2throttle{
    parameter twr.
    local maxthrust is SHIP:MAXTHRUST.
    if maxthrust = 0{
        return 0.
    }
    local r is SHIP:ALTITUDE+SHIP:BODY:RADIUS.
    local weight is SHIP:MASS * SHIP:BODY:MU / r / r.
    local thrust is twr * weight.
    return thrust / SHIP:MAXTHRUST.
}
declare function current_thrust{
    local thr to 0.
    LIST ENGINES in es.
    for e in es{
        set thr to thr + e:thrust.
    }
    return thr.
}
declare function wait_cond{
    parameter stable_time, cond.
    local stable_since to 2147483647.
        until time:seconds - stable_since > stable_time{
            if cond(){
                set stable_since to min(time:seconds,stable_since).
            }else{
                set stable_since to 2147483647.
            }
            wait 1.
    }
}