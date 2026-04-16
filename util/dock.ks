function is_matching_docking_port {
    PARAMETER other_part.
    PARAMETER my_port.
    IF other_part:HASMODULE("DockingPortModule") AND my_port:HASMODULE("DockingPortModule") {
        RETURN other_part:NODETYPE = my_port:NODETYPE.
    }
    IF my_port:HASMODULE("ModuleGrappleNode") and other_part:TAG = "docking_port" {
        RETURN TRUE.
    }
    RETURN FALSE.
}

function get_matching_docking_port{
    PARAMETER target_vessel.
    PARAMETER my_port.
    IF NOT target_vessel:LOADED {
        RETURN FALSE.
    }
    for p in target_vessel:PARTS {
        if is_matching_docking_port(p, my_port) {
            RETURN p.
        }
    }
    RETURN FALSE.
}
function get_all_docking_ports{
    PARAMETER target_vessel.

    local docks is target_vessel:PARTSTAGGED("docking_port").
    for m in target_vessel:MODULESNAMED("ModuleGrappleNode") {
        local p is m:PART.
        if p:TAG <> "docking_port" {
            docks:add(p).
        }
    }
    for m in target_vessel:MODULESNAMED("DockingPortModule") {
        local p is m:PART.
        if p:TAG <> "docking_port" {
            docks:add(p).
        }
    }
    return docks.
}