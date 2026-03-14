RUNONCEPATH("0://util/dir.ks").
function circularOrbDv{
    parameter _alt.
    parameter _body is ship:body.
    return SQRT(_body:MU/(_body:RADIUS+_alt)).
}

function getOrbitNormal{
    //Should reuse RETURN getOrbitAnDir(orb):UPVECTOR.
    PARAMETER orb.
    local bodyRotNorm is orb:BODY:ANGULARVEL.
    local refMeridian is VXCL(bodyRotNorm, SOLARPRIMEVECTOR).
    local ascendingNodeVec is ANGLEAXIS(orb:LONGITUDEOFASCENDINGNODE, bodyRotNorm) * refMeridian.
    local orbNormVec is ANGLEAXIS(-orb:INCLINATION, ascendingNodeVec) * bodyRotNorm:NORMALIZED.
    RETURN orbNormVec.
}
function getOrbitAnDir{
    // Returns a direction that points towards Periapsis and UP is normal to the orbit plane. Reference is Body's center
    PARAMETER orb.
    local bodyRotNorm is orb:BODY:ANGULARVEL.
    local refMeridian is VXCL(bodyRotNorm, SOLARPRIMEVECTOR).
    local ascendingNodeVec is ANGLEAXIS(orb:LONGITUDEOFASCENDINGNODE, bodyRotNorm) * refMeridian.
    local orbNormVec is ANGLEAXIS(-orb:INCLINATION, ascendingNodeVec) * bodyRotNorm:NORMALIZED.
    RETURN LOOKDIRUP(ascendingNodeVec, orbNormVec).
}

function getOrbitPeDir{
    // Returns a direction that points towards Periapsis and UP is normal to the orbit plane. Reference is Body's center
    PARAMETER orb.
    local anDir is getOrbitAnDir(orb).
    RETURN ANGLEAXIS(orb:ARGUMENTOFPERIAPSIS, anDir:UPVECTOR) * anDir.
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

function altitudeAt{
    PARAMETER obj, t.
    local pos is POSITIONAT(obj, t).
    local bodyC is POSITIONAT(obj:ORBIT:BODY, t).
}
function getOrbRadiusByTrueAnomaly{
    PARAMETER orb, ta.
    RETURN orb:SEMIMAJORAXIS * (1 - orb:ECCENTRICITY^2) / (1 + orb:ECCENTRICITY * COS(ta)).
}
function getOrbTrueAnomalyByDir{
    PARAMETER orb, dirV.
    local peDir is getOrbitPeDir(orb).
    local dirInOrbPlane is LOOKDIRUP(VXCL(peDir:UPVECTOR, dirV), peDir:UPVECTOR).
    // show_rot(peDir, orb:BODY:POSITION).
    // show_rot(dirInOrbPlane, orb:BODY:POSITION).
    RETURN angleBetweenDirs(peDir, dirInOrbPlane).
}
function getOrbRadiusByDir{
    PARAMETER orb, dirV.
    RETURN getOrbRadiusByTrueAnomaly(orb, getOrbTrueAnomalyByDir(orb, dirV)).
}
function getOrbAltByDir{
    PARAMETER orb, dirV.
    RETURN getOrbRadiusByDir(orb, dirV) - orb:BODY:RADIUS.
}
function getOrbitPeriod{
    PARAMETER _body, pe, ap.
    local a is (pe + ap + 2* _body:radius) / 2.
    RETURN 2*constant:pi*sqrt(a^3 / _body:mu).
}