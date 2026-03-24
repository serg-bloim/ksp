// RUNONCEPATH("0://app/body_lift.ks").
RUNONCEPATH("0://app/randevous.ks").
RUNONCEPATH("0://app/landing.ks").
RUNONCEPATH("0://util/func.ks").
RUNONCEPATH("0://util/maneuvers.ks").


// wait 1.
// create_app_body_lift():setters
//     :alt(30000)
//     :autostart(FALSE)
//     :warp_all_transfers(TRUE)
//     :app
//     :run().
// wait 3.
set log_only_main to create_rolling_logger("/log/test/orbit.log").
set log_main to also_print(log_only_main).

CLEARVECDRAWS().
// print "Test".
// print BODY:rotationperiod.
// local dt is 1000.
// print dt / BODY:rotationperiod * 360.
// print geopositionOfAt(SHIP:BODY, SHIP:POSITION, TIME:seconds):LNG.
// print geopositionOfAt(SHIP:BODY, SHIP:POSITION, TIME:seconds+dt):LNG.
// remove_all_nodes().
// ADD NODE(TIME:seconds+1000, 0,0,0).
create_landing_app():setters
    :loc(LATLNG(20, 20))
    :show_loc(TRUE)
    :warp_all_transfers(TRUE)
    :app()
    :run().