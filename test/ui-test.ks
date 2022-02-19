RUNONCEPATH ("ui.ks").
local main to ui_reg("Hello World").
local config to ui_reg("Let's show some params
abc = 0
def = 0
...
all of them are 0").
local lbl_abc to ui_reg_lbl(config, 6,1).
local lbl_def to ui_reg_lbl(config, 6,2).
set abc to 0.
set def to 0.
ui_switch(main).
wait 0.5.
ui_switch(config).
wait 0.5.
until 0 {
    ui_prnt_lbl(lbl_abc, abc).
    ui_prnt_lbl(lbl_def, def).
    set abc to abc + 1.
    set def to def + 3.
    wait 0.
}