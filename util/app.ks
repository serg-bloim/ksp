function create_app {
    PARAMETER NAME.
    PARAMETER run_func.
    PARAMETER CFG is LEXICON().
    local app is LEXICON("name", NAME, "cfg", cfg).
    set app:run to {run_func(app).}.
    RETURN app.
}