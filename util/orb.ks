function circularOrbDv{
    parameter _alt.
    parameter _body is ship:body.
    return SQRT(_body:MU/(_body:RADIUS+_alt)).
}

function getOrbitNormal{
    PARAMETER orb.
    local bodyRotNorm is orb:BODY:ANGULARVEL.
    local refMeridian is VXCL(bodyRotNorm, SOLARPRIMEVECTOR).
    local ascendingNodeVec is ANGLEAXIS(orb:LONGITUDEOFASCENDINGNODE, bodyRotNorm) * refMeridian.
    local orbNormVec is ANGLEAXIS(-orb:INCLINATION, ascendingNodeVec) * bodyRotNorm:NORMALIZED.
    RETURN orbNormVec.
}

function getOrbitableDirection{
    PARAMETER trg.
    local orbNorm is getOrbitNormal(trg:ORBIT).
    RETURN LOOKDIRUP(trg:POSITION - trg:ORBIT:BODY:POSITION, orbNorm).
}

function getAscendingNodeDirection{
    // Returns Vector in SOI-Frame.
    PARAMETER orbFrom.
    PARAMETER orbTo.
    local oNormFrom is getOrbitNormal(orbFrom).
    local oNormTo is getOrbitNormal(orbTo).
    local anVec is VCRS(oNormFrom, oNormTo).
    RETURN LOOKDIRUP(anVec, oNormFrom).
}