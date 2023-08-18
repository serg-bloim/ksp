function get_stages{
    lock throttle to 0.
    wait 0.
    
    // the ultimate product of the program
    // will contain lists of data about each stage
    
    list engines in engineList.
    
    local g is 9.80665.

    // have to activate engines to get their thrusts (for now)
    local stage_engines to list().
    local stage_fuels to list().
    local stage_masses to list().
    local stages to list().
    local allres is LEX().
    local resspec is LEX().
    for ares in SHIP:RESOURCES{
        allres:add(ares:name, 0).
        resspec:add(ares:name, ares).
    }
    // print allres.
    // print resspec.
    // print ship:engines[0]:CONSUMEDRESOURCES.

    // Need to better calculate the mass
    FROM {local i is stage:NUMBER + 1.} UNTIL i = 0 STEP {set i to i-1.} DO {
        stage_engines:add(list()).
        stage_fuels:add(allres:copy()).
        stage_masses:add(0).
        stages:add(LEX()).
    }
    for eng in engineList{
        stage_engines[eng:STAGE]:add(eng).
    }
    for part in ship:parts{
        local stg is part:separatedin + 1.
        if part:hasmodule("ModuleDecouple")
            set stg to stg + 1.
        set stage_masses[stg] to stage_masses[stg] + part:mass.
        if not part:RESOURCES:empty{
            for res in part:resources{
                set stage_fuels[stg][res:name] to stage_fuels[stg][res:name] + res:amount.
            }
        }
    }
    // print "stage_fuels".
    // print stage_fuels.
    from {local stg is 0. local total is 0.} until stg = stage_masses:length step{set stg to stg + 1.} do {
        set total to total + stage_masses[stg].
        set stage_masses[stg] to total.
    }
    // Need to calc:
    //  - mass
    //  - thrust
    //  - isp
    //  - dv
    //  - burntime
    //  - 
    //  - 
    from {local stg is stage_engines:length-1.} until stg < 0 step {set stg to stg -1.} do {
        local engs is stage_engines[stg].
        local stage_mass is stage_masses[stg].
        local stage_end_mass is stage_mass.
        local stage_fuel_mass_total is 0.
        local stage_fuel_mass_consumed is 0.
        local stage_thrust is 0.
        local stage_fuel_flow is 0.
        local stage_burntime is 0.
        local stage_min_acc is 0.
        local stage_max_acc is 0.
        local stage_isp is 0.
        local stage_dv is 0.

        if not engs:empty{
            for e in engs{
                set stage_thrust to stage_thrust + e:POSSIBLETHRUSTAT(0).
                set stage_fuel_flow to stage_fuel_flow + e:POSSIBLETHRUSTAT(0)/e:visp.
            }
            local consumption is allres:copy().
            for eng in engs{
                for res in eng:CONSUMEDRESOURCES:VALUES{
                    set consumption[res:name] to consumption[res:name] + res:MAXFUELFLOW.
                }
            }
            local total_res is stage_fuels[stg]:copy().
            // Here it checks if separators to the next stagesdo have crossfeed enabled, that means we can draw resources from the following stages.
            // Although this logic relies that all separators are a part of some stage action. If not, it may work incorrectly.
            // print "Total res for stage: " + stg.
            from {local borrowResStg is stg - 1. local separ is engs[0]:separator.} 
            until borrowResStg < 0
            step {set borrowResStg to borrowResStg - 1. set separ to separ:separator.} do {
                // print "1. borrowResStg: " + borrowResStg + " separ:FUELCROSSFEED: " + separ:FUELCROSSFEED.
                if separ:FUELCROSSFEED
                    for res in total_res:KEYS
                        set total_res[res] to total_res[res] + stage_fuels[borrowResStg][res].
                ELSE break.
                // set borrowResStg to borrowResStg - 1.
                // set separ to separ:separator.
            }
            // print "Total res for stage: " + stg.
            //     print_lex(total_res).
            set stage_burntime to 9999999999.
            for res in total_res:keys{
                set stage_fuel_mass_total to stage_fuel_mass_total + total_res[res] * resspec[res]:DENSITY.
                if consumption[res] > 0
                    set stage_burntime to MIN(stage_burntime, total_res[res]/consumption[res]).
            }
            if stage_burntime = 9999999999
                set stage_burntime to 0.
            if stage_burntime > 0{
                local consumed is allres:copy().
                for res in consumed:keys{
                    local res_amt is consumption[res]*stage_burntime.
                    set consumed[res] to res_amt.
                    set stage_fuel_mass_consumed to stage_fuel_mass_consumed + res_amt * resspec[res]:DENSITY.
                }
                from {local i is stg. local keepdoing is TRUE.} until (i < 0 or keepdoing = FALSE) step {set i to i - 1.} do {
                    // subtract consumed resources from this stage and upwards
                    for res in allres:keys{
                        local spendable is min (stage_fuels[i][res], consumed[res]).
                        set stage_fuels[i][res] to stage_fuels[i][res] - spendable.
                        set consumed[res] to consumed[res] - spendable.
                        set stage_masses[i] to stage_masses[i] - spendable * resspec[res]:DENSITY.
                    }
                    set keepdoing to FALSE.
                    for v in consumed:values{
                        if v > 0{
                            set keepdoing to TRUE.
                            BREAK.
                        }
                    }
                }
                set stage_end_mass to stage_mass - stage_fuel_mass_consumed.
                set stage_isp to stage_thrust / stage_fuel_flow.
                set stage_min_acc to stage_thrust / stage_mass.
                set stage_max_acc to stage_thrust / stage_end_mass.
                set stage_dv to stage_isp * g * ln(stage_mass/stage_end_mass).
            }
        }
        set stages[stg]:STAGE to stg.
        set stages[stg]:MASS to stage_mass.
        set stages[stg]:END_MASS to stage_end_mass.
        set stages[stg]:BURN_DUR to stage_burntime.
        set stages[stg]:THRUST to stage_thrust.
        set stages[stg]:ISP to stage_isp.
        set stages[stg]:DV to stage_dv.
        set stages[stg]:ACC_MIN to stage_min_acc.
        set stages[stg]:ACC_MAX to stage_max_acc.
    }
    return stages.
}