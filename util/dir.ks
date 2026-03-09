function angleBetweenDirs{
    // If two directions have the same "UP" component from LOOKDIRUP(lookAt,lookUp). Then the function returns an angle from the first dir to the second dir.
    PARAMETER dirFrom.
    PARAMETER dirTo.
    RETURN (dirFrom * dirTo:INVERSE):YAW.
}