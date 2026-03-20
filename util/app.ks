RUNONCEPATH("0://util/log.ks").
function create_app {
    PARAMETER NAME.
    PARAMETER run_func.
    PARAMETER CFG is LEXICON().
    PARAMETER custom_setters is LEXICON().
    local app is LEXICON("name", NAME, "cfg", cfg).
    set app:run to {run_func(app).}.
    create_logger(app).
    create_setters(app).
    create_custom_setters(app, custom_setters).
    RETURN app.
}
function create_setters{
    PARAMETER app.
    local setters is LEXICON("app", {RETURN app.}).
    local cfg is app:cfg.
    function setter {
        PARAMETER key.
        PARAMETER val.
        app:log("set app("+ app:NAME +"):cfg['" + key + "'] to " + val).
        set cfg[key] to val.
        RETURN setters.
    }
    set app:setters to setters.
    for k in app:cfg:keys {
        app:log("setup setter " + k).
        set setters[k] to setter@:bind(k).
    }
}
function create_custom_setters{
    PARAMETER app.
    PARAMETER custom_setters.
    function setter {
        PARAMETER name.
        PARAMETER func.
        PARAMETER val.
        app:log("invoke app("+ app:NAME +"):setters:"+ name + "()").
        func(val, app).
        RETURN app:setters.
    }

    for k in custom_setters:keys {
        app:log("setup custom setter " + k).
        app:setters:add(k, setter@:bind(k, custom_setters[k])).
    }
}
function create_logger{
    PARAMETER app.
    set app:base_logger to log_only_main@.
    set app:log to {
        PARAMETER msg.
        app:base_logger("[" + app:name + "] " + msg).
    }.
}