function reflect{
    PARAMETER _v.
    PARAMETER axis_v.
    local ang is VANG(_v, axis_v).
    if ang = 0{
        RETURN _v.
    }
    local rot is ANGLEAXIS(ang*2, VCRS(_v, axis_v)).
    RETURN rot * _v.
}
function absv{
    PARAMETER _v.
    RETURN V(ABS(_v:X), ABS(_v:Y), ABS(_v:Z)).
}
function project_v{
    PARAMETER a, b. // Project vector a onto b.
    RETURN (a*b) * b:NORMALIZED.
}