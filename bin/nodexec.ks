RUNONCEPATH("/util/utils.ks").
RUNONCEPATH("/util/maneuvers.ks").
CLEARSCREEN.
print("Node Execution").
for nd in ALLNODES {
    if esc_pressed(){
        BREAK.
    }
    print ("Maneuver execution").
    print("").
    exec_node(nd).
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
SAS ON.
