RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/maneuvers.ks").
local init_lng is -65.
print "waiting for LNG="+init_lng + " currently="+SHIP:geoposition:lng.
lock STEERING to SHIP:retrograde.
wait until is_close(SHIP:geoposition:lng, init_lng, 1).
SET descend_node to NODE(TIME + 30, 0, 0, -100 ).
ADD descend_node.
exec_node(descend_node).
print "done".