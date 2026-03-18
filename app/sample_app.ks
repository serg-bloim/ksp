RUNONCEPATH("0://util/app.ks").
function create_sample_app{
    function def_cfg{
        local cfg is LEXICON().
        set cfg:str to "Hello World".
        RETURN cfg.
    }
    function app_run{
        PARAMETER app.
        print "This app prints "+ app:cfg:str.
    }
    local app is  create_app("SAMPLE_APP", app_run@, def_cfg()).
    set app:change_string to {
        PARAMETER str.
        set app:cfg:str to str.
    }.
    RETURN app.
}