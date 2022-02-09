local target_alt is SHIP:ALTITUDE.
local inp_state is 0.
local new_alt is "".
local numbers is "0123456789".
local max_elevation is 500.
declare function inp {
    until not terminal:input:haschar {
        local ch to terminal:input:getchar.
        if inp_state = 0 {
            if ch = "c"{
                set inp_state to 1.
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
SAS OFF.
until 0 {
    clearscreen.
    inp().
    print "Target height: " + target_alt.
    set wp to get_active_waypoint().
    if wp = 0 {
        print "No waypoint selected".
    } else {
        print wp.
        print "WP pos: " + wp:position.
        print wp:GEOPOSITION:bearing.
        set my_pos_alt to ship:GEOPOSITION:ALTITUDEPOSITION(target_alt).
        if my_pos_alt:mag > max_elevation{
            set my_pos_alt:mag to max_elevation.
        }
        CLEARVECDRAWS().
        print ship:position.
        print ship:position:vec.

        VECDRAW(
                ship:position,
                        my_pos_alt,
                        RGB(1,0,0),
                        my_pos_alt:MAG,
                        1.0,
                        TRUE,
                        0.2,
                        TRUE,
                        TRUE
                ).
        set direct_surf to VECTOREXCLUDE(ship:up:FOREVECTOR, wp:position).
        set direct_surf:mag to 1000.
        set direct_3d to my_pos_alt + direct_surf.
        VECDRAW(
                ship:position,
                        direct_3d,
                        RGB(1,0,1),
                        "",
                        1.0,
                        TRUE,
                        0.2,
                        TRUE,
                        TRUE
                ).
        if SHIP:CONTROL:PILOTPITCH <> 0{
            set target_alt to round((target_alt + 100 * SHIP:CONTROL:PILOTPITCH)/10)*10.
        }
        if SAS {
            UNLOCK STEERING.
            BREAK.
        }
        LOCK STEERING to direct_3d.
    }
    WAIT 0.05.
}