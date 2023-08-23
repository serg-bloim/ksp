// #include "../util/log.ks"
RUNONCEPATH("util/log.ks").
function show_rot {
    declare parameter rot.
    set front to rot:vector*1000.
    set up1 to rot:upvector*500.
    set right to rot:STARVECTOR*500.
    VECDRAW(V(0,0,0),front, red, "fore", 1, true).
    VECDRAW(V(0,0,0),up1, blue, "up", 1, true).
    VECDRAW(V(0,0,0),right, green, "right", 1, true).
}
function show_vect {
    declare parameter vec.
    declare parameter lbl is "".
    declare parameter color is red.
    declare parameter origin is V(0,0,0).
    VECDRAW(origin,vec, color, lbl, 1, true).
}
FUNCTION print_lex{
    PARAMETER obj.
    for k in obj:keys
        print k + " : " + obj[k].
}
set dbg to also_print(create_simple_logger("log/dbg-main.log")).