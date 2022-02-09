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
local enabled is FALSE.
declare function disable{
    set enabled to FALSE.
    SAS ON.
    UNLOCK STEERING.
}
declare function enable{
    set enabled to TRUE.
    SAS OFF.
}
declare function inp {
    until not terminal:input:haschar {
        local ch to terminal:input:getchar.
        if inp_state = 0 {
            if ch = "c"{
                set inp_state to 1.
            }
            else if ch = "s"{
               enable.
            }
            else if ch = "t"{
                disable.
            }
            else if ch = terminal:input:UPCURSORONE{
                set target_alt to target_alt + 100.
            }
            else if ch = terminal:input:DOWNCURSORONE{
                set target_alt to target_alt - 100.
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
            } else if ch = terminal:input:ENTER {
                set target_alt to new_alt:tonumber(target_alt).
                set new_alt to "".
                set inp_state to 0.
            }
        }
    }
    if inp_state = 1 {
        print "Enter new altitude: " + new_alt.
        print " ".
        print " ".
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
until 0 {
    clearscreen.
    print "Autopilot v1".
    inp().
    set wp to get_active_waypoint().
    if wp = 0 or not enabled {
        print "Autopilot disabled".
    } else {
        set sbp to -SHIP:BODY:POSITION.
        set air_dist to VECTORANGLE((wp:position+sbp), sbp) * sbp:MAG * constant:DegToRad.
        print "Target altitude:    " + target_alt.
        print "Tune altitude:    + " + round(fine_tune_alt, 1).
        print "Stable for (s): " + round(TIME:SECONDS - stable_since,1).
        print wp.
        print "Travel distance: " + (CHOOSE ROUND(air_dist/1000, 1) + " km" if air_dist > 10000 ELSE ROUND(air_dist) + " m").
        print "".
        print "Flight plan:".


        set my_pos_alt to ship:GEOPOSITION:ALTITUDEPOSITION(target_alt + fine_tune_alt).
        if my_pos_alt:mag > max_elevation{
            set my_pos_alt:mag to max_elevation.
        }

        set direct_surf to VECTOREXCLUDE(ship:up:FOREVECTOR, wp:position).
        set direct_surf:mag to 1000.
        set direct_3d to my_pos_alt + direct_surf.
        if SHIP:CONTROL:PILOTPITCH <> 0{
            set target_alt to round((target_alt + 100 * SHIP:CONTROL:PILOTPITCH)/10)*10.
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
        }
        if air_dist < 15000 {
            if air_dist < 1000 {
                disable.
            }
            if needs_pause{
                KUniverse:PAUSE().
                print "unpaused".
                set needs_pause to FALSE.
            }
        } else {
            set needs_pause to TRUE.
        }
        LOCK STEERING to direct_3d.
    }
    WAIT refresh_delay.
}