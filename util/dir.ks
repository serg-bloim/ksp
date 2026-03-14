function angleBetweenDirAndVector{
    // If two directions have the same "UP" component from LOOKDIRUP(lookAt,lookUp). Then the function returns an angle from the first dir to the second dir.
    PARAMETER dirFrom.
    PARAMETER vTo.
    local d is VXCL(dirFrom:UPVECTOR, vTo).
    local dang is VANG(dirFrom:FOREVECTOR, d).
    if d * dirFrom:STARVECTOR < 0{
        set dang to 360 - dang.
    }
    RETURN dang.
}
function angleBetweenDirs{
    // If two directions have the same "UP" component from LOOKDIRUP(lookAt,lookUp). Then the function returns an angle from the first dir to the second dir.
    PARAMETER dirFrom.
    PARAMETER dirTo.
    RETURN angleBetweenDirAndVector(dirFrom, dirTo:FOREVECTOR).
}

function angleBetweenDirsOld{
    // If two directions have the same "UP" component from LOOKDIRUP(lookAt,lookUp). Then the function returns an angle from the first dir to the second dir.
    PARAMETER dirFrom.
    PARAMETER dirTo.
    print "angleBetweenDirs(" + dirFrom + ","+dirTo:INVERSE+") = " + (dirFrom * dirTo:INVERSE).
    RETURN (dirFrom * dirTo:INVERSE):YAW.
}