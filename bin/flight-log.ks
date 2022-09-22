RUNONCEPATH("/util/utils.ks").
CLEARSCREEN.
local flight_log to list().
LOCK ALT to FLOOR(SHIP:ALTITUDE/100).
LOCK attack_angle to vang(SHIP:FACING:VECTOR, UP:VECTOR).
local r is SHIP:ALTITUDE+SHIP:BODY:RADIUS.
LOG "time,alt,facing_angle,prog_angl,srf_prog_angl,thrust,weight,twr,ap,airspeed" to "/log/flight.log".
ON ALT{
    set datapoint to lexicon().
    local alti to SHIP:ALTITUDE.
    local angl to vang(SHIP:FACING:VECTOR, UP:VECTOR).
    local prog_angl to vang(SHIP:PROGRADE:VECTOR, UP:VECTOR).
    local srf_prog_angl to vang(SHIP:SRFPROGRADE:VECTOR, UP:VECTOR).
    local thrust to current_thrust().
    local weight to SHIP:MASS * SHIP:BODY:MU / r / r.
    local twr to thrust/weight.
    local ap to SHIP:APOAPSIS.
    local aspeed to SHIP:AIRSPEED.

    datapoint:add("alt", alti).
    datapoint:add("facing_angle", angl).
    datapoint:add("prog_angl", prog_angl).
    datapoint:add("srf_prog_angl", srf_prog_angl).
    datapoint:add("thrust", thrust).
    datapoint:add("weight", weight).
    datapoint:add("twr", twr).
    datapoint:add("ap", ap).
    datapoint:add("airspeed", aspeed).
    local line to  MISSIONTIME + "," + alti + "," + angl + "," + prog_angl + "," + srf_prog_angl + "," + thrust + "," + weight + "," + twr + "," + ap + "," + airspeed.
    log line to "/log/flight.log".
    print(line).
    PRESERVE.
}
wait until SHIP:PERIAPSIS > 79000.
wait 5.
WRITEJSON(flight_log, "/log/flight-log.json").