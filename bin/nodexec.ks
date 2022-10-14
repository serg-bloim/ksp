// #include "../util/utils.ks"
RUNONCEPATH("/util/utils.ks").
// #include "../util/maneuvers.ks"
RUNONCEPATH("/util/maneuvers.ks").
CLEARSCREEN.
print("Node Execution").
start_reading_input().
local exit to false.
on chars_read_num{
    local ch to last_read_char:tolower().
    if ch = "q" or ch = ESC{
        set exit to true.
    }
}
for nd in ALLNODES {
    if exit{
        BREAK.
    }
    print ("Maneuver execution").
    print("").
    exec_node(nd).
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
stop_reading_input().
SAS ON.
