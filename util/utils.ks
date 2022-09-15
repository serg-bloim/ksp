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
local ESC is CHAR(27).
declare function wait_until_esc{
    until terminal:input:getchar = ESC{

    }
}
declare function esc_pressed{
    return terminal:input:haschar and terminal:input:getchar = ESC.
}