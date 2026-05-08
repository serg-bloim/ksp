RUNONCEPATH("util/utils.ks").

function wait_steering_stable{
    PARAMETER precision is 0.1.
    wait_cond2({RETURN ABS(SteeringManager:ANGLEERROR) < precision.}, 3).
}