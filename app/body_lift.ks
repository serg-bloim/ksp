RUNONCEPATH("0://util/app.ks").
function create_app_body_lift{
    function def_cfg{
        local cfg is LEXICON().
        set cfg:ALT to 100000.
        RETURN cfg.
    }
    function app_run{
        PARAMETER app.
        print "Lifting to " + app:cfg:alt + " around " + SHIP:BODY:NAME.
    }
    RETURN create_app("BODY_LIFT", app_run@, def_cfg()).
}