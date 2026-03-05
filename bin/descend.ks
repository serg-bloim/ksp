RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/maneuvers.ks").
local init_lng is 200.
local home_coords is LATLNG(-0.0972605782956235,-74.5576240495215).
lock CUR_LNG to MOD(SHIP:geoposition:lng + 360, 360).
print "waiting for LNG="+init_lng + " currently="+CUR_LNG.
SAS OFF.
lock STEERING to SHIP:retrograde.
until is_close(CUR_LNG, init_lng, 1){
    print "waiting for LNG="+init_lng + " currently="+CUR_LNG + "                    " at (0,1).
    wait 0.2.
}
wait until is_close(CUR_LNG, init_lng, 1).
SET descend_node to NODE(TIME + 5, 0, 0, -100 ).
ADD descend_node.
exec_node(descend_node).
SAS OFF.
lock steering_angle to cap(home_coords:bearing,-5,5).
lock STEERING to SHIP:srfretrograde * R(0,-steering_angle,0).
function stage_all{
    until stage:number = 0 {
        stage.
        wait 0.
    }
}
when SHIP:altitude - cap(SHIP:GEOPOSITION:terrainheight, 0, 9999999999) < 2000 then {
    print "Height check".
    stage_all.
}
CLEARSCREEN.
until (SHIP:GEOPOSITION:POSITION - home_coords:position):mag < 3000{
    print "Dst: " + ROUND((SHIP:GEOPOSITION:POSITION - home_coords:position):mag/1000) + " km" at (0,3).
    wait 0.
}
print "parachutes".
stage_all.
print "done".