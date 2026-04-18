RUNONCEPATH("util/utils.ks").

function wait_steering_stable{
    PARAMETER precision.
    wait_cond2({RETURN SteeringManager:ANGLEERROR < precision.}, 3).
}