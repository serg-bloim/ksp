RUNONCEPATH("0://util/log.ks").
function geopositionOfAt{
    PARAMETER _BODY.
    PARAMETER pos.
    PARAMETER T.
    local geoWithoutBodyRot is _BODY:geopositionof(pos).
    local dt is T - TIME:SECONDS.
    local bodyRotationDeg is 360 * dt / _BODY:ROTATIONPERIOD.
    RETURN _BODY:GEOPOSITIONLATLNG(geoWithoutBodyRot:LAT, geoWithoutBodyRot:LNG - bodyRotationDeg).
}
function get_g_acc{
    PARAMETER _BODY.
    PARAMETER _alt.
    local _r is _BODY:RADIUS + _alt.
    RETURN _BODY:MU / _r^2.
}