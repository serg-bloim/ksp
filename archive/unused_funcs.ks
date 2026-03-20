function get_ETA_AN_or_DN{
    PARAMETER trgOrb.
    local f_criteria to {
        PARAMETER T.
        local shipDir is getOrbitableDirection(SHIP).
        local anDir is getAscendingNodeDirection(SHIP:ORBIT, trgOrb).
        local angle2AN is angleBetweenDirs(shipDir, anDir).
        print "angle2AN: " + angle2AN.
        local andnVec is anDir:FOREVECTOR.
        IF angle2AN > 190{
            set angle2AN to angle2AN - 180.
            set andnVec to -andnVec.
        }
        local pos is POSITIONAT(SHIP, T) - SHIP:BODY:POSITION.
        RETURN VANG(pos, andnVec).
    }.
    return bisect_search(f_criteria, 0, 0.01, TIME:SECONDS, 1, 50).
}

function descend{
    PARAMETER func.
    PARAMETER x0.
    PARAMETER dx is LIST().
    PARAMETER eps is 0.1.
    PARAMETER max_iters is 5.
    PARAMETER max_piters is 10.
    local CMP_EPS is 0.001.
    if dx:length = 0{
        set dx to map({PARAMETER x. RETURN 1.}, x0).
    }
    if x0:LENGTH <> dx:LENGTH{
        RETURN 1/0.
    }
    local iter is 0.
    local xs is x0:COPY().
    local dxx is map({PARAMETER x. RETURN 2.}, x0).
    UNTIL FALSE {
        set iter to iter + 1.
        if iter > max_iters {
            print "too many iterations".
            RETURN xs.
        }
        local modifications is FALSE.
        FROM {local pi is 0.} UNTIL pi = xs:LENGTH STEP {set pi to pi + 1.} DO {
            // print "Iter " + iter + "." + pi.
            local a is xs[pi].
            local da is dx[pi].
            // local center_v is func(xs).
            // set xs[pi] to a - da.
            // local left_v is func(xs).
            // set xs[pi] to a + da.
            // local right_v is func(xs).
            local dxx is 2.
            // if right_v - center_v > CMP_EPS AND left_v - center_v > CMP_EPS {
            //     // min is between a - da and a + da, no need to expand the range.
            //     set dxx to 1.
            // }
            local piter is 0.
            until piter > max_piters {
                set piter to piter + 1.
                set xs[pi] to a - da.
                local left_v is func(xs).
                set xs[pi] to a + da.
                local right_v is func(xs).
                set xs[pi] to a.
                local center_v is func(xs).
                local left_dv is left_v - center_v.
                local right_dv is right_v - center_v.
                // print "pi_"+piter + " a=" + r2(a) + " da=" + r2(da) + " left=" + r2(left_v) + " center=" + r2(center_v) + " right=" + r2(right_v).
                IF ABS(right_dv) < CMP_EPS AND ABS(left_dv) < CMP_EPS{
                    // print "EXIT COND 1".
                    BREAK.
                } ELSE IF (right_dv > CMP_EPS AND left_dv > CMP_EPS) OR ABS(right_dv) < CMP_EPS OR ABS(left_dv) < CMP_EPS {
                    // min is between a - da and a + da, no need to expand the range.
                    // print "FOUND RANGE --- ".
                    IF da < eps{
                        // print "EXIT COND 2".
                        BREAK.
                    }
                    set da to da / 4.
                    set dxx to 1.
                } ELSE {
                    IF left_v < right_v {
                        set a to a - da.
                    }ELSE{
                        set a to a + da.
                    }
                    set da to da * dxx.
            // set xs[pi] to a.
            // set dx[pi] to da.
            //         print xs.
            //         print center_v.
                }
                set modifications to TRUE.
            }
            set xs[pi] to a.
            set dx[pi] to da.
        }
        IF NOT MODIFICATIONS {
            // print "FOUND SOLUTION".
            RETURN xs.
        }
    }
}