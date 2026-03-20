RUNONCEPATH("0://util/list.ks").
function r2{
    PARAMETER X.
    RETURN ROUND(X, 2).
}
function descend{
    PARAMETER func.
    PARAMETER x0.
    PARAMETER dx is LIST().
    PARAMETER eps is 0.1.
    PARAMETER max_iters is 5.
    PARAMETER max_piters is 20.
    local CMP_EPS is 0.001.
    GLOBAL EXIT_CODE is -1. // EXIT_CODE is UNDEFINED
    GLOBAL EXIT_ITERS is 0.
    if dx:length = 0{
        set dx to map({PARAMETER x. RETURN 1.}, x0).
    }
    if x0:LENGTH <> dx:LENGTH{
        GLOBAL EXIT_CODE is 1.
        RETURN 1/0.
    }
    local iter is 0.
    local xs is x0:COPY().
    local dxx is map({PARAMETER x. RETURN 2.}, x0).
    UNTIL FALSE {
        set iter to iter + 1.
        if iter > max_iters {
            print "too many iterations".
            GLOBAL EXIT_ITERS is iter.
            GLOBAL EXIT_CODE is 2. // Out of iters
            RETURN xs.
        }
        local modifications is FALSE.
        FROM {local pi is 0.} UNTIL pi = xs:LENGTH STEP {set pi to pi + 1.} DO {
            // print "Iter " + iter + "." + pi.
            local a is xs[pi].
            local da is dx[pi].
            function fi{
                PARAMETER X.
                set xs[pi] to X.
                RETURN func(xs).
            }
            local a_new is descend1d(fi@, a, da, eps, max_piters).
            if EXIT_CODE <> 0 {
                print "WARNING descend->descend1d failed with EXIT_CODE=" + EXIT_CODE.
            }
            set xs[pi] to a_new.
            set dx[pi] to (a_new - a) / 16.
        }
        IF NOT MODIFICATIONS {
            // print "FOUND SOLUTION".
            GLOBAL EXIT_ITERS is iter.
            GLOBAL EXIT_CODE is 0. // Solved
            RETURN xs.
        }
    }
}
function descend1d{
    PARAMETER f.
    PARAMETER x0.
    PARAMETER dx is 1.
    PARAMETER eps is 0.1.
    PARAMETER max_iters is 20.
    GLOBAL EXIT_CODE is -1. // EXIT_CODE is UNDEFINED
    GLOBAL EXIT_ITERS is 0.
    function mid{
        PARAMETER a, b.
        RETURN (a + b) / 2.
    }
    function min3{
        PARAMETER a, b, c.
        RETURN min(a, min(b, c)).
    }
    
    local logger is {PARAMETER msg.}.
    if DEFINED descend1d_logger {
        set logger to descend1d_logger.
    }
    local iters is 0.
    set dx to ABS(dx).
    local x_left is x0 - dx.
    local x_right is x0 + dx.
    local y_left is f(x_left).
    local y_right is f(x_right).
    local y_min is min(y_left, y_right).
    // expansion
    local found_bounaries is 0.
    UNTIL found_bounaries = 2 {
        set found_bounaries to 0.
        logger(iters + " Expand f("+r2(x_left)+")="+r2(y_left) + " | f("+r2(x_right)+")="+r2(y_right) + " | f_min="+r2(y_min)).
        IF y_left > y_min { set found_bounaries to found_bounaries + 1.}
        ELSE{
            set x_left to x_left - dx.
            set y_left to f(x_left).
        }
        IF y_right > y_min { set found_bounaries to found_bounaries + 1.}
        ELSE{
            set x_right to x_right + dx.
            set y_right to f(x_right).
        }
        set y_min to min3(y_min, y_left, y_right).
        set dx to dx * 2.
        set iters to iters + 1.
        if iters >= max_iters{
            GLOBAL EXIT_ITERS is iters.
            GLOBAL EXIT_CODE is 2. // Out of iters
            RETURN mid(x_left, x_right).
        }
    }

    // shrink
    local x_center is mid(x_left, x_right).
    local y_center is f(x_center).
    UNTIL iters >= max_iters {
        set iters to iters + 1.
        logger(iters + " Shrink f("+r2(x_left)+")="+r2(y_left) + " | f("+r2(x_center)+")="+r2(y_center) + " | f("+r2(x_right)+")="+r2(y_right) + " dx=" + r2(x_right - x_left)).
        IF ABS(x_right - x_left) < eps {
            GLOBAL EXIT_ITERS is iters.
            GLOBAL EXIT_CODE is 0.
            RETURN x_center.
        }
        local x_mid_left is mid(x_left, x_center).
        local x_mid_right is mid(x_center, x_right).

        local y_mid_left is f(x_mid_left).
        local y_mid_right is f(x_mid_right).

        set y_min to min3(y_mid_left, y_center, y_mid_right).
        if y_mid_left = y_min{
            set x_right to x_center.
            set y_right to y_center.

            set x_center to x_mid_left.
            set y_center to y_mid_left.
        } ELSE IF y_mid_right = y_min{
            set x_left to x_center.
            set y_left to y_center.

            set x_center to x_mid_right.
            set y_center to y_mid_right.
        } ELSE {
            set x_right to x_mid_right.
            set y_right to y_mid_right.

            set x_left to x_mid_left.
            set y_left to y_mid_left.
        }
    }
    print "Ran out of iterations " + iters + "/" + max_iters.
    GLOBAL EXIT_ITERS is iters.
    GLOBAL EXIT_CODE is 2. // Out of iters
    return x_center.
}
function apply1p{
    PARAMETER func.
    RETURN {
        PARAMETER lst.
        RETURN func(lst[0]).
    }.
}
function apply2p{
    PARAMETER func.
    RETURN {
        PARAMETER lst.
        RETURN func(lst[0], lst[1]).
    }.
}
function apply3p{
    PARAMETER func.
    RETURN {
        PARAMETER lst.
        RETURN func(lst[0], lst[1], lst[2]).
    }.
}