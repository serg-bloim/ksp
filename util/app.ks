function create_app {
    PARAMETER NAME.
    PARAMETER run_func.
    PARAMETER CFG is LEXICON().
    local app is LEXICON("name", NAME, "cfg", cfg).
    set app:run to {run_func(app).}.
    create_setters(app).
    RETURN app.
}
function create_setters{
    PARAMETER app.
    local setters is LEXICON("app", app).
    local cfg is app:cfg.
    function setter {
        PARAMETER key.
        PARAMETER val.
        print "set app("+ app:NAME +"):cfg['" + key + "'] to " + val.
        set cfg[key] to val.
        RETURN setters.
    }
    set app:setters to setters.
    for k in app:cfg:keys {
        print "setup setter " + k.
        // print app:setters.
        set setters[k] to setter@:bind(k).
    }
}