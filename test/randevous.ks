RUNONCEPATH("0://util/randevous.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://test/mun_lifter.ks").


until FALSE {
    local parabola3d is {
        PARAMETER X, Y.
        RETURN 5*X*X + 3*Y*Y + 4.
    }.
    local res is descend(apply2p(parabola3d), LIST(10, 10)).
    print res.
    RCS OFF.
    WAIT UNTIL RCS.
}

