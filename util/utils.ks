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
global ESC is CHAR(27).
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
declare function create_condition{
    parameter stable_time, cond.
    local stable_since to 2147483647.
    return {
        if cond(){
            set stable_since to min(time:seconds,stable_since).
        }else{
            set stable_since to 2147483647.
        }
        return time:seconds - stable_since > stable_time.
    }.
}
declare function wait_cond{
    parameter stable_time, predicate.
    local cond to create_condition(stable_time, predicate).
    until cond(){
        wait 0.1.
    }
}
declare function timed_condition{
    parameter predicate.
    parameter timed_action.
    local stable_since to 2147483647.
    return {
        local res to predicate().
        local now to time:seconds.
        set stable_since to choose min(stable_since, now) if res else 2147483647.
        timed_action(now - min(stable_since, now), res).
        return res.
    }.
}
declare function SasOffBackup{
    if SAS {
        SAS OFF.
        return {SAS ON.}.
    }
    return {}.
}

declare function prnt{
    parameter lbl.
    parameter val is "".
    print (lbl + " : " + val + "                 ") at (1,prnt_n).
    set prnt_n to prnt_n+1.
}
declare function vector2angle{
    parameter x, y.
    return 0.
}
declare function start_timer{
    parameter dur.
    local started to time:seconds.
    return {return time:seconds - started > dur.}.
}
declare function check_flag{
    parameter name.
    return SHIP:PARTSTAGGEDPATTERN(name):LENGTH > 0.
}
declare function show_terminal_if_required{
    if check_flag("show_terminal"){
        CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
    }
}
local exit_reading_input to false.
declare function start_reading_input{
    global chars_read_num to 0.
    global last_read_char to "".
    set exit_reading_input to false.
    when exit_reading_input or terminal:input:haschar then{
        if exit_reading_input{
            return false.
        }
        local ch to terminal:input:getchar().
        set last_read_char to ch.
        set chars_read_num to chars_read_num + 1.
        return true.
    }
}
declare function stop_reading_input{
    set exit_reading_input to true.
}


