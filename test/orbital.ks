// RUNONCEPATH("0://app/body_lift.ks").
RUNONCEPATH("0://app/randevous.ks").
RUNONCEPATH("0://app/landing.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://util/maneuvers.ks").

FOR p IN SHIP:PARTS {
    PRINT p:NAME + " [" + p:TAG + "]".
}
