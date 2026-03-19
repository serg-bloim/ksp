RUNONCEPATH("0://util/func.ks").

function run_all{
    test_parabola_2d().
}

run_all().


function test_parabola_2d{
    function f{
        PARAMETER X.
        RETURN (X - 3)^2 + 5.
    }
    test_func(f@, 5, LIST(3), 0.1, 10, 1, 100).
}

function test_func{
    PARAMETER f.
    PARAMETER expected_res.
    PARAMETER expected_solution.
    PARAMETER expected_error.
    PARAMETER x0.
    PARAMETER dx.
    PARAMETER max_iters.

    local samples is 0.
    function f_wrapper{
        PARAMETER X.
        local Y is f(X).
        set samples to samples + 1.
        print samples + ". f(" + X + ") = " + Y.
        RETURN Y.
    }

    local res is descend1d_v2(f_wrapper@, x0, dx, expected_error, max_iters).
    print "Samples: " + samples.
    print "Result: " + res.
}