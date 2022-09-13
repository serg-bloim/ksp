declare function countdown{
    declare parameter cnt is 10.
    declare parameter delay is 1.
    UNTIL cnt = 0 {
        PRINT cnt.
        SET cnt to cnt - 1.
        WAIT delay.
    }
    PRINT "0".
}