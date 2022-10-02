declare function telemetry2file{
    parameter file.
    parameter data.
    local line to "0".
    for d in data{
        local repr to 0.
        if d:istype("scalar"){
            set repr to d.
        }else {
            set repr to CHAR(34) + d:TOSTRING() + CHAR(34).
        }
        set line to line + " , " + repr.
    }
    log line to file.
}
declare function file_next_suffix{
    parameter path.
    if not exists(path){
        return path.
    }
    local parts to path:split(".").
    local prefix to path.
    local ext to "".
    if parts:length > 1{
        set ext to "." + parts[parts:length-1].
        parts:remove(parts:length-1).
        set prefix to parts:join(".").
    }
    from {local x is 1.} UNTIL 0 STEP {set x to x+1.} DO {
        local p to prefix + "_" + x + ext.
        if not exists(p){
            return p.
        }
    }
}
declare function create_rolling_logger{
    parameter path.
    parameter print_time is true.
    if exists(path){
        local arc_path to file_next_suffix(path).
        movePath(path, arc_path).
    }
    return {
        parameter msg.
        log "[" + TIME:calendar + " " + time:clock + "] " + msg to path.
    }.
}
declare function also_print{
    parameter logger.
    return {
        parameter msg.
        logger(msg).
        print(msg).
    }.
}

global log_main to also_print(create_rolling_logger("/log/main.log")).