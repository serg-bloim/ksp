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