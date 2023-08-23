RUNONCEPATH("0://util/utils.ks").
RUNONCEPATH("0://util/dbg.ks").
function build_fuel_clusters{
    PARAMETER engs is LIST().
    local prts is 0.
    local allres is LEX().
    local resspec is LEX().
    local clusters is LIST().
    local eng2cluster is LEX().
    for ares in SHIP:RESOURCES{
        allres:add(ares:name, 0).
    }
    FUNCTION traverse{
        PARAMETER part, cid, clusters, eng2cluster.
        local old_cid is cid.
        set prts to prts + 1.
        for r in part:resources{
            set clusters[cid][r:name] to clusters[cid][r:name] + r:AMOUNT.
        }
        if part:ISTYPE("Engine"){
            local eng_stage is part:stage.
            set eng2cluster[part] to clusters[cid].
        }
        if not part:FUELCROSSFEED{
            clusters:add(allres:copy()).
            set cid to clusters:length-1.
        }
        for ch in part:children{
            traverse(ch, cid, clusters, eng2cluster).
        }
    }
    LOCAL root is ship:ROOTPART.
    clusters:add(allres:copy()).
    traverse(root, 0, clusters, eng2cluster).
    RETURN eng2cluster.
}
function get_stages{
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
    }
    for eng in engineList{
        stage_engines[eng:STAGE]:add(eng).
    }
    local root is ship:parts[0].
    local clusters is build_fuel_clusters(root).
    for part in ship:parts{
        local stg is part:separatedin + 1.
        if part:istype("Decoupler"){
            set stg to stg + 1.
        }
        set stage_masses[stg] to stage_masses[stg] + part:drymass.
        if not part:RESOURCES:empty{
            for res in part:resources{
                set stage_fuels[stg][res:name] to stage_fuels[stg][res:name] + res:amount.
            }
        }
    }
    // Need to calc:
    //  - mass
    //  - thrust
    //  - isp
    //  - dv
    //  - burntime
    //  - 
    //  - 
    local active_eng is UniqueSet().
    local current_mass is SHIP:MASS.
    from {local stg is stage_engines:length-1.} until stg < 0 step {set stg to stg -1.} do {
        local engs is stage_engines[stg].


        for e in engs{
            active_eng:add(e).
        }
        local to_be_deleted is LIST().
        for e in active_eng{
            for res in e:CONSUMEDRESOURCES:VALUES{
                if res:MAXFUELFLOW > 0 and clusters[e][res:name] = 1{
                    // an engine requires a resource which is missing.
                    // remove such engine from active_engines
                    to_be_deleted:add(e).
                }
            }
        }
        for e in to_be_deleted{
            active_eng:remove(e).
        }
        local next_separation_stage is -1.
        local engines_before_next_stage is 0.
        local cluster_config is LEX().
        for e in active_eng{
            local cluster is clusters[e].
            if e:SEPARATEDIN > next_separation_stage{ set next_separation_stage to e:SEPARATEDIN. set engines_before_next_stage to 0.}
            if e:SEPARATEDIN = next_separation_stage{ set engines_before_next_stage to engines_before_next_stage + 1.}
            if not cluster_config:haskey(cluster) {
                local conf is LEX().
                set conf:engs to UNIQUESET(e).
                set cluster_config[cluster] to conf.
            }else{
                cluster_config[cluster]:engs:add(e).
            }
        }
        until engines_before_next_stage = 0 {local stage_mass is current_mass.
            local stage_end_mass is stage_mass.
            local stage_fuel_mass_total is 0.
            local stage_thrust is 0.
            local stage_fuel_flow is 0.
            local stage_burntime is 0.
            local stage_min_acc is 0.
            local stage_max_acc is 0.
            local stage_isp is 0.
            local stage_dv is 0.
            local stage_fuel_mass_consumed is 0.
            local stage_burntime is 9999999999.
            for cluster in cluster_config:keys{
                local cfg is cluster_config[cluster].
                local consumption is allres:copy().
                set cfg:consumption to consumption.
                for eng in cfg:engs{
                    set stage_thrust to stage_thrust + eng:POSSIBLETHRUSTAT(0).
                    set stage_fuel_flow to stage_fuel_flow + eng:POSSIBLETHRUSTAT(0)/eng:visp.
                    for res in eng:CONSUMEDRESOURCES:VALUES{
                        set consumption[res:name] to consumption[res:name] + res:MAXFUELFLOW.
                    }
                }
                set cluster_burntime to 9999999999.
                for res in cluster:keys{
                    dbg("cluster[res] : " + cluster[res]).
                    set stage_fuel_mass_total to stage_fuel_mass_total + cluster[res] * resspec[res]:DENSITY.
                    if consumption[res] > 0{
                        set cluster_burntime to MIN(cluster_burntime, cluster[res]/consumption[res]).
                    }

                }
                dbg("cluster_burntime : " + cluster_burntime).
                if cluster_burntime = 9999999999
                    set cluster_burntime to 0.
                set cfg:burntime to cluster_burntime.
                set stage_burntime to min(stage_burntime, cluster_burntime).
            }
            for cluster in cluster_config:keys{
                local cfg is cluster_config[cluster].
                for res in cluster:keys{
                    // I do min here cause due to precision loss, res amt may get a bit bigger than cluster[res]
                    // And thus after subtraction, cluster[res] will be a very small negative number.
                    local res_amt is min(cfg:consumption[res]*stage_burntime, cluster[res]).
                    set cluster[res] to cluster[res] - res_amt.
                    set stage_fuel_mass_consumed to stage_fuel_mass_consumed + res_amt * resspec[res]:DENSITY.
                }
                to_be_deleted:clear().
                for eng in cfg:engs{
                    for res in eng:CONSUMEDRESOURCES:VALUES{
                        if cluster[res:name] = 0 and res:MAXFUELFLOW > 0{
                            to_be_deleted:add(eng).
                            BREAK.
                        }
                    }
                }
                
                for eng in to_be_deleted{
                    cfg:engs:remove(eng).
                    active_eng:remove(eng).
                    if eng:SEPARATEDIN = next_separation_stage{   
                        set engines_before_next_stage to engines_before_next_stage - 1.
                    }
                }
            }
            set current_mass to current_mass - stage_fuel_mass_consumed.
            set stage_end_mass to current_mass.
            set stage_isp to stage_thrust / stage_fuel_flow.
            set stage_min_acc to stage_thrust / stage_mass.
            set stage_max_acc to stage_thrust / stage_end_mass.
            set stage_dv to stage_isp * g * ln(stage_mass/stage_end_mass).
            local stage_segment is LEX().
            set stage_segment:STAGE to stg.
            set stage_segment:MASS to stage_mass.
            set stage_segment:END_MASS to stage_end_mass.
            set stage_segment:BURN_DUR to stage_burntime.
            set stage_segment:THRUST to stage_thrust.
            set stage_segment:ISP to stage_isp.
            set stage_segment:DV to stage_dv.
            set stage_segment:ACC_MIN to stage_min_acc.
            set stage_segment:ACC_MAX to stage_max_acc.
            stages:add(stage_segment).
        }
        set current_mass to current_mass - stage_masses[stg].
    }
    return stages.
}