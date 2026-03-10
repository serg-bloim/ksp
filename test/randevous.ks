RUNONCEPATH("0://util/randevous.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://test/mun_lifter.ks").


until FALSE {
    local parabola3d is {
        PARAMETER X, Y.
        set X to X - 3.
        set Y to Y - 4.
        RETURN 5*X*X + 3*Y*Y + 5.
    }.
    local res is descend(apply2p(parabola3d), LIST(10, 10)).
    print res.
    RCS OFF.
    WAIT UNTIL RCS.
}

