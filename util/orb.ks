function circularOrbDv{
    parameter _alt.
    parameter _body is ship:body.
    return SQRT(_body:MU/(_body:RADIUS+_alt)).
}