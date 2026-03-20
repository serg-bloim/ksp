// RUNONCEPATH("0://app/body_lift.ks").
RUNONCEPATH("0://app/randevous.ks").
// RUNONCEPATH("0://app/landing.ks").
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


remove_all_nodes().
ADD NODE(TIME:SECONDS + 10, 0, 0, 0).
descend1d({PARAMETER P.
    set NEXTNODE:PROGRADE to P.
    RETURN ABS(NEXTNODE:OBT:APOAPSIS - 30000).
}, 20, 1, 0.001, 50).

// exec_node(NEXTNODE).

create_exec_next_node():setters
    :remove_node(FALSE)
    :auto_warp(TRUE)
    :app():run().


// create_app_randevous():setters
//     :target(TARGET)
//     :AUTOSTART(FALSE)
//     :app()
//     :warp_all_transfers()
//     :intercept_at_target_pe()
//     :run().


// create_exec_next_node():setters
//     :remove_node(TRUE)
//     :auto_warp(TRUE)
//     :app():run().



// create_landing_app():setters
//     :loc(LATLNG(0, 0))
//     :show_loc(TRUE)
//     :warp_all_transfers(TRUE)
//     :app()
//     :run().