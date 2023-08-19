@CLOBBERBUILTINS on.
set fp to "orbits/report.txt".
if not exists(fp){
    create(fp).
}
local fd is open(fp).
fd:CLEAR().
fd:WRITELN("Equatorial intersections").
LOCK GP TO SHIP:GEOPOSITION.
declare function log_msg{
    declare parameter msg.
    print msg.
    fd:WRITELN(msg).
}

SET KUNIVERSE:TIMEWARP:RATE TO 100.
wait until ABS(GP:LAT) < 15.
SET KUNIVERSE:TIMEWARP:RATE TO 10.
wait until ABS(GP:LAT) < 2.
KUNIVERSE:TIMEWARP:CANCELWARP().
local offset is 0.
SET iter to 0.
ON (GP:LAT > 0) {
    if iter = 0{
        set offset to -GP:LNG.
    }
    SET iter to iter + 1.
    local dir is choose "SOUTHBOUND" if GP:LAT < 0 else "NORTHBOUND".
    log_msg(iter + " " + ROUND(GP:LAT,2) + " " + ROUND(360-MOD(GP:LNG+360,360),5) + " " + ROUND(360-MOD(GP:LNG+720 + offset,360),5)  +" " + dir).
    KUNIVERSE:TIMEWARP:WARPTO(time:seconds + 15*60+16).
    return true.
}

wait until iter > 132.