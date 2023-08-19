@CLOBBERBUILTINS on.
function circularOrbDv{
    parameter alt.
    parameter body is ship:body.
    return SQRT(body:MU/(body:RADIUS+alt)).
}