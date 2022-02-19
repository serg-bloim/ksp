local ui_uis to list().
local ui_comps to list().
local ui_active_ui to -1.
function ui_reg{
    declare parameter txt.
    local id to ui_uis:LENGTH.
    local ui to lex().
    set ui:id to id.
    set ui:txt to txt.
    ui_uis:add(ui).
    return id.
}
function ui_switch{
    declare parameter id.
    if id = ui_active_ui return.
    clearscreen.
    set ui_active_ui to id.
    print ui_uis[id]:txt.
}
function ui_reg_lbl{
    declare parameter ui.
    declare parameter x.
    declare parameter y.
    declare parameter len is 0.
    declare parameter padright is TRUE.
    local id to ui_comps:LENGTH.
    local comp to lex().
    set comp:id to id.
    set comp:ui to ui.
    set comp:x to x.
    set comp:y to y.
    set comp:len to len.
    set comp:padright to padright.
    ui_comps:add(comp).
    return id.
}
function ui_prnt_lbl{
    declare parameter id.
    declare parameter val.
    local comp is ui_comps[id].
    if comp:ui = ui_active_ui {
        set val to val:tostring.
        print (CHOOSE val:padright(comp:len) if comp:padright else val:padleft(comp:len)) at(comp:x, comp:y).
    }
}