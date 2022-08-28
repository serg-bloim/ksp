RUNONCEPATH("ui/ui.ks").
local ap_ui_disabled is ui_reg(open("ap-ui/dis.txt"):readall():STRING).
local ap_ui_main is ui_reg(open("ap-ui/main.txt"):readall():STRING).
local ap_ui_change_alt is ui_reg(open("ap-ui/chalt.txt"):readall():STRING).

local ap_ui_main_alt is ui_reg_lbl(ap_ui_main, 17,2,12).
local ap_ui_main_alt_tune is ui_reg_lbl(ap_ui_main, 19,3,7).
local ap_ui_main_stable is ui_reg_lbl(ap_ui_main, 14,5,7).
local ap_ui_main_dst is ui_reg_lbl(ap_ui_main, 14,6,14).
local ap_ui_main_mode is ui_reg_lbl(ap_ui_main, 14,7,14).
local ap_ui_main_wp_l1 is ui_reg_lbl(ap_ui_main, 14,8,14).
local ap_ui_main_wp_l2 is ui_reg_lbl(ap_ui_main, 2,9,26).

local ap_ui_chalt_curr is ui_reg_lbl(ap_ui_change_alt, 16,3,12).
local ap_ui_chalt_new is ui_reg_lbl(ap_ui_change_alt, 16,5,12).

local target_alt is round(SHIP:ALTITUDE).
local fine_tune_alt is 0.
local inp_state is 0.
local new_alt is "".
local numbers is "0123456789".
local max_elevation is 500.
local fine_tune_cooldown is 10.
local stable_since is 0.
local needs_pause is FALSE.
local refresh_delay is 0.05.
local old_rcs is RCS.
local wp to 0.
local wp_old_name is "".
set pitchPID to PIDLOOP(
                0.1,   // adjust throttle 0.1 per 5m in error from desired altitude.
                0.03,  // adjust throttle 0.1 per second spent at 1m error in altitude.
                0.1,   // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
                -5,   // min possible throttle is zero.
                15    // max possible throttle is one.
        ).

function show_main_ui{
    ui_switch(ap_ui_main).
    ui_prnt_lbl(ap_ui_main_alt, target_alt).
    ui_prnt_lbl(ap_ui_main_alt_tune, round(fine_tune_alt, 6)).
    ui_prnt_lbl(ap_ui_main_stable, round(TIME:SECONDS - stable_since,1)).
}
declare function disable{
    RCS OFF.
    SAS ON.
    UNLOCK STEERING.
    ui_switch(ap_ui_disabled).
}
declare function enable{
    RCS ON.
    SAS OFF.
    show_main_ui.
}
function limit{
    declare parameter val.
    declare parameter min.
    declare parameter max.
    if val > max return max.
    if val < min return min.
    return val.
}
declare function inp {
    until not terminal:input:haschar {
        local ch to terminal:input:getchar.
        if inp_state = 0 {
            if ch = "c"{
                set inp_state to 1.
                ui_switch(ap_ui_change_alt).
                ui_prnt_lbl(ap_ui_chalt_curr, target_alt).
            }
            else if ch = "s"{
                enable.
            }
            else if ch = "t"{
                disable.
            }
            else if ch = terminal:input:UPCURSORONE{
                set target_alt to target_alt + 100.
                ui_prnt_lbl(ap_ui_main_alt, target_alt).
            }
            else if ch = terminal:input:DOWNCURSORONE{
                set target_alt to target_alt - 100.
                ui_prnt_lbl(ap_ui_main_alt, target_alt).
            }
        } else if inp_state = 1 {
            if numbers:find(ch) >= 0 {
                set new_alt to new_alt + ch.
            }
            if ch = terminal:input:BACKSPACE and new_alt:length > 0{
                set new_alt to new_alt:remove(new_alt:length-1, 1).
            } else if ch = "q"{
                set new_alt to "".
                set inp_state to 0.
                show_main_ui.
            } else if ch = terminal:input:ENTER {
                set target_alt to new_alt:tonumber(target_alt).
                set new_alt to "".
                set inp_state to 0.
                show_main_ui.
            }
            ui_prnt_lbl(ap_ui_chalt_new, new_alt).
        }
    }
}
declare function get_active_waypoint {
    for wp in ALLWAYPOINTS() {
        if wp:ISSELECTED{
            return wp.
        }
    }
    return 0.
}
when KUniverse:CANQUICKSAVE then {
    KUniverse:QUICKSAVETO("Autopilot_start").
}
function show_rot {
    declare parameter rot.
    set front to rot:vector*20.
    set up1 to rot:upvector*20.
    set star to rot:STARVECTOR*20.
    VECDRAW(V(0,0,0),front, red, "", 1, true).
    VECDRAW(V(0,0,0),up1, blue, "", 1, true).
    VECDRAW(V(0,0,0),star, green, "", 1, true).
}
function show_vect {
    declare parameter vec.
    declare parameter lbl is "".
    declare parameter color is red.
    VECDRAW(V(0,0,0),vec, color, lbl, 1, true).
}
disable().
until 0 {
    CLEARVECDRAWS().
    inp().
    if wp = 0 or not wp:isselected{
        set wp to get_active_waypoint().
    }

    if wp = 0 or not RCS {
        if old_rcs{
            disable.
        }
    } else {
        if wp:name <> wp_old_name{
            ui_prnt_lbl(ap_ui_main_wp_l1, wp:name:substring(0,min(14, wp:name:length))).
            if wp:name:length > 14 {
                ui_prnt_lbl(ap_ui_main_wp_l2, wp:name:substring(14,min(wp:name:length - 14, 26))).
            }
        }
        if not old_rcs {
            SAS OFF.
            set steering_dir to FACING.
            LOCK STEERING to steering_dir.
            show_main_ui.
        }
        set sbp to -SHIP:BODY:POSITION.
        set air_dist to VECTORANGLE((wp:position+sbp), sbp) * sbp:MAG * constant:DegToRad.
        ui_prnt_lbl(ap_ui_main_stable, round(TIME:SECONDS - stable_since,1)).
        ui_prnt_lbl(ap_ui_main_dst, (CHOOSE ROUND(air_dist/1000, 1) + " km" if air_dist > 10000 ELSE ROUND(air_dist) + " m")).


        set my_pos_alt to ship:GEOPOSITION:ALTITUDEPOSITION(target_alt + fine_tune_alt).
        if my_pos_alt:mag > max_elevation{
            set my_pos_alt:mag to max_elevation.
        }

        set direct_surf to VECTOREXCLUDE(ship:up:FOREVECTOR, wp:position).
        set direct_surf:mag to 1000.
        set direct_3d to my_pos_alt + direct_surf.


        set azimuth to vang(VXCL(UP:Vector, SHIP:FACING:vector), VXCL(UP:Vector, direct_3d)).

        if ABS(azimuth) < 10 {
            ui_prnt_lbl(ap_ui_main_mode, "precise").
            set mag_delta to target_alt - SHIP:ALTITUDE.
            set vel_target to mag_delta / 10.
            set pitch to pitchPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
            set pitchPID:SETPOINT to vel_target.
            set pitch_axis to VCRS(direct_surf, SHIP:UP:VECTOR).
            set fwd to direct_surf.
            set direct_3d to ANGLEAXIS(pitch, pitch_axis)*fwd*50.
            SET steering_dir to LOOKDIRUP(direct_3d, direct_3d + UP:vector * 10000).
            ui_prnt_lbl(ap_ui_main_alt_tune, round(pitch, 2)).
        }else{
            ui_prnt_lbl(ap_ui_main_mode, "wide turn").
            set horizon_facing to HEADING(SHIP:BEARING, 0,0).
            set pitch to -limit(azimuth,0,40).
            set local_target to LOOKDIRUP(SHIP:FACING:vector, direct_3d) *  R(pitch, 0 , 0). // Roll against target and pitch 40 degrees.
            set local_target to VXCL(UP:VECTOR, local_target:Vector). // Project onto horizon.
            set local_target:mag to 1.
            set local_target to local_target + UP:Vector*0.2.
            set dir to LOOKDIRUP(SHIP:FACING:vector, local_target).
            set roll_diff to ABS(dir:roll - SHIP:FACING:roll).
            if roll_diff > 5 {
                set pitch to pitch * 2 / (roll_diff - 3).
            }
            SET steering_dir to dir * R(pitch,0,0).
        }

        if SHIP:CONTROL:PILOTPITCH <> 0{
            set target_alt to round((target_alt + 100 * SHIP:CONTROL:PILOTPITCH)/10)*10.
            ui_prnt_lbl(ap_ui_main_alt, target_alt).
        }
        if SAS {
            disable.
        }
        if ABS(SHIP:VERTICALSPEED) > 1{
            set stable_since to TIME:SECONDS.
        }
        if TIME:SECONDS - stable_since > fine_tune_cooldown {
            set fine_tune_alt to target_alt + fine_tune_alt - SHIP:ALTITUDE.
            set stable_since to TIME:SECONDS.
            ui_prnt_lbl(ap_ui_main_alt_tune, round(fine_tune_alt, 6)).
        }
        if air_dist < 15000 {
            if air_dist < 1000 {
                disable.
            }
            if needs_pause{
                KUniverse:PAUSE().
                set needs_pause to FALSE.
            }
        } else {
            set needs_pause to TRUE.
        }
    }
    set old_rcs to RCS.
    WAIT refresh_delay.
}