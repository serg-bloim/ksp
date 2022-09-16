function show_rot {
    declare parameter rot.
    set front to rot:vector*1000.
    set up1 to rot:upvector*500.
    set right to rot:STARVECTOR*500.
    VECDRAW(V(0,0,0),front, red, "", 1, true).
    VECDRAW(V(0,0,0),up1, blue, "", 1, true).
    VECDRAW(V(0,0,0),right, green, "", 1, true).
}
function show_vect {
    declare parameter vec.
    declare parameter lbl is "".
    declare parameter color is red.
    VECDRAW(V(0,0,0),vec, color, lbl, 1, true).
}