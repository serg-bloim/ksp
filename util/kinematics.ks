function calc_dist{
    PARAMETER a0, v0, t.
    RETURN v0 * t + a0 * t^2 / 2.
}

function get_max_breaking_speed{
    PARAMETER dist_to_stop.
    PARAMETER breacking_acc.
    local time_to_stop is sqrt(2 * dist_to_stop / breacking_acc).
    RETURN time_to_stop * breacking_acc.
}