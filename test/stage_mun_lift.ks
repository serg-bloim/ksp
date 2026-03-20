RUNONCEPATH("0://app/body_lift.ks").
RUNONCEPATH("0://app/randevous.ks").

create_app_body_lift():setters
    :alt(30000)
    :autostart(FALSE)
    :warp_all_transfers(TRUE)
    :app()
    :run().

create_app_randevous():setters
    :target(TARGET)
    :AUTOSTART(FALSE)
    :app()
    :warp_all_transfers()
    :intercept_at_target_pe()
    :run().
