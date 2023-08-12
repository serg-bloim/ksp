@CLOBBERBUILTINS on.
function circularOrbDv{
    parameter body.
    parameter alt.
    return SQRT(body:MU/(body:RADIUS+alt)).
}