--WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * AI-Uveso: offset aiarchetype-managerloader.lua' )

local Buff = import('/lua/sim/Buff.lua')
local HighestThread = {}

function EcoManagerThread(aiBrain)
    while GetGameTimeSeconds() < 15 + aiBrain:GetArmyIndex() do
        coroutine.yield(10)
    end
    local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
    local CheatMultOption = tonumber(ScenarioInfo.Options.CheatMult)
    local BuildMultOption = tonumber(ScenarioInfo.Options.BuildMult)
    local CheatMult = CheatMultOption
    local BuildMult = BuildMultOption
    if CheatMultOption ~= BuildMultOption then
        CheatMultOption = math.max(CheatMultOption,BuildMultOption)
        BuildMultOption = math.max(CheatMultOption,BuildMultOption)
        ScenarioInfo.Options.CheatMult = tostring(CheatMultOption)
        ScenarioInfo.Options.BuildMult = tostring(BuildMultOption)
    end
    LOG('* AI-Uveso: Function EcoManagerThread() started! CheatFactor:('..repr(CheatMultOption)..') - BuildFactor:('..repr(BuildMultOption)..') ['..aiBrain.Nickname..']')
    local Engineers = {}
    local paragons = {}
    local Factories = {}
    local lastCall = 0
    local ParaComplete
    local allyScore
    local enemyScore
    local MyArmyRatio
    local bussy
    while aiBrain.Result ~= "defeat" do
        --LOG('* AI-Uveso: Function EcoManagerThread() beat. ['..aiBrain.Nickname..']')
        coroutine.yield(5)
        Engineers = aiBrain:GetListOfUnits(categories.ENGINEER - categories.STATIONASSISTPOD - categories.COMMAND - categories.SUBCOMMANDER, false, false) -- also gets unbuilded units (planed to build)
        StationPods = aiBrain:GetListOfUnits(categories.STATIONASSISTPOD, false, false) -- also gets unbuilded units (planed to build)
        paragons = aiBrain:GetListOfUnits(categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC * categories.ENERGYPRODUCTION * categories.MASSPRODUCTION, false, false)
        Factories = aiBrain:GetListOfUnits(categories.STRUCTURE * categories.FACTORY, false, false)
        ParaComplete = 0
        bussy = false
        for unitNum, unit in paragons do
            if unit:GetFractionComplete() >= 1 then
                ParaComplete = ParaComplete + 1
            end
        end
        if ParaComplete >= 1 then
            aiBrain.HasParagon = true
        else
            aiBrain.HasParagon = false
        end
        -- Cheatbuffs
        if personality == 'sorianeditadaptive' then
            -- Check every 30 seconds for new armyStats to change ECO
            if (GetGameTimeSeconds() > 1 * 1) and lastCall+10 < GetGameTimeSeconds() then
                lastCall = GetGameTimeSeconds()
                --score of all players (unitcount)
                allyScore = 0
                enemyScore = 0
                for k, brain in ArmyBrains do
                    if ArmyIsCivilian(brain:GetArmyIndex()) then
                        --NOOP
                    elseif IsAlly( aiBrain:GetArmyIndex(), brain:GetArmyIndex() ) then
                        --allyScore = allyScore + table.getn(brain:GetListOfUnits( (categories.MOBILE + categories.DEFENSE) - categories.MASSEXTRACTION - categories.ENGINEER - categories.SCOUT, false, false))
                        allyScore = allyScore + table.getn(brain:GetListOfUnits( categories.MOBILE - categories.MASSEXTRACTION - categories.ENGINEER - categories.SCOUT, false, false))
                    elseif IsEnemy( aiBrain:GetArmyIndex(), brain:GetArmyIndex() ) then
                        --enemyScore = enemyScore + table.getn(brain:GetListOfUnits( (categories.MOBILE + categories.DEFENSE) - categories.MASSEXTRACTION - categories.ENGINEER - categories.SCOUT, false, false))
                        enemyScore = enemyScore + table.getn(brain:GetListOfUnits( categories.MOBILE - categories.MASSEXTRACTION - categories.ENGINEER - categories.SCOUT, false, false))
                    end
                end
                if enemyScore ~= 0 then
                    if allyScore == 0 then
                        allyScore = 1
                    end
                    MyArmyRatio = 100/enemyScore*allyScore
                else
                    MyArmyRatio = 100
                end

                -- Increase cheatfactor to +1.5 after 1 hour gametime
                if GetGameTimeSeconds() > 1 * 1 then
                    CheatMult = CheatMult + 0.1
                    BuildMult = BuildMult + 0.1
                    if CheatMult < tonumber(CheatMultOption) then CheatMult = tonumber(CheatMultOption) end
                    if BuildMult < tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    if CheatMult > tonumber(CheatMultOption) + 1.5 then CheatMult = tonumber(CheatMultOption) + 1.5 end
                    if BuildMult > tonumber(BuildMultOption) + 1.5 then BuildMult = tonumber(BuildMultOption) + 1.5 end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                -- Increase cheatfactor to +0.6 after 1 hour gametime
                elseif GetGameTimeSeconds() > 5 * 35 then
                    CheatMult = CheatMult + 0.1
                    BuildMult = BuildMult + 0.1
                    if CheatMult < tonumber(CheatMultOption) then CheatMult = tonumber(CheatMultOption) end
                    if BuildMult < tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    if CheatMult > tonumber(CheatMultOption) + 0.6 then CheatMult = tonumber(CheatMultOption) + 0.6 end
                    if BuildMult > tonumber(BuildMultOption) + 0.6 then BuildMult = tonumber(BuildMultOption) + 0.6 end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                -- Increase ECO if we have less than 40% of the enemy units
                elseif MyArmyRatio < 35 then
                    CheatMult = CheatMult + 0.4
                    BuildMult = BuildMult + 0.1
                    if CheatMult > tonumber(CheatMultOption) + 8 then CheatMult = tonumber(CheatMultOption) + 8 end
                    if BuildMult > tonumber(BuildMultOption) + 8 then BuildMult = tonumber(BuildMultOption) + 8 end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                elseif MyArmyRatio < 55 then
                    CheatMult = CheatMult + 0.3
                    if CheatMult > tonumber(CheatMultOption) + 6 then CheatMult = tonumber(CheatMultOption) + 6 end
                    if BuildMult ~= tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                -- Increase ECO if we have less than 85% of the enemy units
                elseif MyArmyRatio < 75 then
                    CheatMult = CheatMult + 0.2
                    if CheatMult > tonumber(CheatMultOption) + 4 then CheatMult = tonumber(CheatMultOption) + 4 end
                    if BuildMult ~= tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                -- Decrease ECO if we have to much units
                elseif MyArmyRatio < 95 then
                    CheatMult = CheatMult + 0.1
                    if CheatMult > tonumber(CheatMultOption) + 3 then CheatMult = tonumber(CheatMultOption) + 3 end
                    if BuildMult ~= tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                -- Decrease ECO if we have to much units
                elseif MyArmyRatio > 125 then
                    CheatMult = CheatMult - 0.5
                    BuildMult = BuildMult - 0.1
                    if CheatMult < 0.9 then CheatMult = 0.9 end
                    if BuildMult < 0.9 then BuildMult = 0.9 end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                elseif MyArmyRatio > 105 then
                    CheatMult = CheatMult - 0.1
                    if CheatMult < 1.0 then CheatMult = 1.0 end
                    if BuildMult ~= tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                -- Normal ECO
                else -- MyArmyRatio > 85  MyArmyRatio <= 100
                    if CheatMult > CheatMultOption then
                        CheatMult = CheatMult - 0.1
                        if CheatMult < tonumber(CheatMultOption) then CheatMult = tonumber(CheatMultOption) end
                    elseif CheatMult < CheatMultOption then
                        CheatMult = CheatMult + 0.1
                        if CheatMult > tonumber(CheatMultOption) then CheatMult = tonumber(CheatMultOption) end
                    end
                    if BuildMult > BuildMultOption then
                        BuildMult = BuildMult - 0.1
                        if BuildMult < tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    elseif BuildMult < BuildMultOption then
                        BuildMult = BuildMult + 0.1
                        if BuildMult > tonumber(BuildMultOption) then BuildMult = tonumber(BuildMultOption) end
                    end
                    --LOG('* ECO + ally('..allyScore..') enemy('..enemyScore..') - ArmyRatio: '..math.floor(MyArmyRatio)..'% - Build/CheatMult old: '..math.floor(tonumber(ScenarioInfo.Options.BuildMult)*10)..' '..math.floor(tonumber(ScenarioInfo.Options.CheatMult)*10)..' - new: '..math.floor(BuildMult*10)..' '..math.floor(CheatMult*10)..'')
                    SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
                end
            end
        end


-- ECO for Assisting StationPods
        -- loop over assisting StationPods and manage pause / unpause
        for _, unit in StationPods do
            -- if the unit is dead, continue with the next unit
            if unit.Dead then continue end
            -- Do we have a Paragon like structure ?
            if aiBrain.HasParagon then
                if unit:IsPaused() then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            -- We have negative eco. Check if we can switch something off
            elseif aiBrain:GetEconomyTrend('MASS') < 0.0 or aiBrain:GetEconomyTrend('ENERGY') < 0.0 then
                -- if this unit is already paused, continue with the next unit
                if unit:IsPaused() then continue end
                -- Low eco, disable all pods
                if aiBrain:GetEconomyStoredRatio('MASS') < 0.35 or aiBrain:GetEconomyStoredRatio('ENERGY') < 0.90 then
                    unit:SetPaused( true )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            -- We have positive eco. Check if we can switch something on
            elseif aiBrain:GetEconomyTrend('MASS') >= 0.0 and aiBrain:GetEconomyTrend('ENERGY') >= 0.0 then
                -- if this unit is paused, continue with the next unit
                if not unit:IsPaused() then continue end
                if aiBrain:GetEconomyStoredRatio('MASS') >= 0.35 and aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.90 then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            end
        end
        if bussy then
            continue -- while true do
        end

-- ECO for Assisting engineers
        -- loop over assisting engineers and manage pause / unpause
        for _, unit in Engineers do
            -- if the unit is dead, continue with the next unit
            if unit.Dead then continue end
            -- Only Check units that are assisting
            if not unit.PlatoonHandle.PlatoonData.Assist.AssisteeType then continue end
            -- Only Check units that have UnitBeingAssist
            if not unit.UnitBeingAssist then continue end

            -- Do we have a Paragon like structure ?
            if aiBrain.HasParagon then
                if unit:IsPaused() then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            -- We have negative eco. Check if we can switch something off
            elseif aiBrain:GetEconomyTrend('MASS') < 0.0 or aiBrain:GetEconomyTrend('ENERGY') < 0.0 then
                -- if this unit is already paused, continue with the next unit
                if unit:IsPaused() then continue end
                -- Emergency low eco energy, prevent shield colaps: disable everything
                if aiBrain:GetEconomyStoredRatio('ENERGY') < 0.25 then
                    -- Pause Experimental assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Paragon assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Factory assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.FACTORY, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Energy assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    end
                    -- disband all other assist Platoons
                    unit.PlatoonHandle:Stop()
                    unit.PlatoonHandle:PlatoonDisband()
                    bussy = true
                    break
                -- Extreme low eco mass, disable everything exept energy
                elseif aiBrain:GetEconomyStoredRatio('MASS') < 0.05 or aiBrain:GetEconomyStoredRatio('ENERGY') < 0.50 then
                    -- Pause Experimental assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Paragon assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Factory assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.FACTORY, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Energy assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        -- noop
                    end
                    -- disband all other assist Platoons
                    unit.PlatoonHandle:Stop()
                    unit.PlatoonHandle:PlatoonDisband()
                    bussy = true
                    break
                -- Very low eco, disable everything but factory
                elseif aiBrain:GetEconomyStoredRatio('MASS') < 0.25 or aiBrain:GetEconomyStoredRatio('ENERGY') < 0.80 then
                    -- Pause Experimental assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Paragon assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Factory assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.FACTORY, unit.UnitBeingAssist) then
                        -- noop
                    -- Pause Energy assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        -- noop
                    end
                    -- disband all other assist Platoons
                    unit.PlatoonHandle:Stop()
                    unit.PlatoonHandle:PlatoonDisband()
                    bussy = true
                    break
                -- Low eco, disable only special buildings
                elseif aiBrain:GetEconomyStoredRatio('MASS') < 0.35 or aiBrain:GetEconomyStoredRatio('ENERGY') < 0.99 then
                    -- Pause Experimental assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( true )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- Pause Paragon assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC, unit.UnitBeingAssist) then
                        -- noop
                    -- Pause Factory assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.FACTORY, unit.UnitBeingAssist) then
                        -- noop
                    -- Pause Energy assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        -- noop
                    end
                    -- disband all other assist Platoons
                    unit.PlatoonHandle:Stop()
                    unit.PlatoonHandle:PlatoonDisband()
                    bussy = true
                    break
                end
            -- We have positive eco. Check if we can switch something on
            elseif aiBrain:GetEconomyTrend('MASS') >= 0.0 and aiBrain:GetEconomyTrend('ENERGY') >= 0.0 then
                -- if this unit is paused, continue with the next unit
                if not unit:IsPaused() then continue end
                if aiBrain:GetEconomyStoredRatio('MASS') >= 0.35 and aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.99 then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                elseif aiBrain:GetEconomyStoredRatio('MASS') >= 0.25 and aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.80 then
                    -- UnPause Experimental assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.EXPERIMENTAL - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( false )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- UnPause Factory assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.FACTORY, unit.UnitBeingAssist) then
                        unit:SetPaused( false )
                        bussy = true
                        break -- for _, unit in Engineers do
                    -- UnPause Energy assist
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( false )
                        bussy = true
                        break -- for _, unit in Engineers do
                    end
                elseif aiBrain:GetEconomyStoredRatio('MASS') >= 0.05 and aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.50 then
                    -- UnPause Factory assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.FACTORY, unit.UnitBeingAssist) then
                        unit:SetPaused( false )
                        bussy = true
                        break -- for _, unit in Engineers do
                    elseif EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( false )
                        bussy = true
                        break -- for _, unit in Engineers do
                    end
                elseif aiBrain:GetEconomyStoredRatio('ENERGY') > 0.25 then
                    -- UnPause Energy assist
                    if EntityCategoryContains(categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.ECONOMIC, unit.UnitBeingAssist) then
                        unit:SetPaused( false )
                        bussy = true
                        break -- for _, unit in Engineers do
                    end
                end
            end
        end
        if bussy then
            continue -- while true do
        end
-- ECO for Building engineers
        -- loop over building engineers and manage pause / unpause
        for _, unit in Engineers do
            -- if the unit is dead, continue with the next unit
            if unit.Dead then continue end
            if unit.PlatoonHandle.PlatoonData.Assist.AssisteeType then continue end
            -- Only Check units that are assisting
            if not unit.UnitBeingBuilt then continue end
            if aiBrain.HasParagon or unit.noPause then
                if unit:IsPaused() then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            -- We have negative eco. Check if we can switch something off
            elseif aiBrain:GetEconomyStoredRatio('ENERGY') < 0.01 then
                if unit:IsPaused() then continue end
                if not EntityCategoryContains( categories.ENERGYPRODUCTION + ((categories.MASSEXTRACTION + categories.FACTORY + categories.ENERGYSTORAGE) * categories.TECH1) , unit.UnitBeingBuilt) then
                    unit:SetPaused( true )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            elseif aiBrain:GetEconomyStoredRatio('MASS') < 0.01 then
                if unit:IsPaused() then continue end
                if not EntityCategoryContains( categories.MASSEXTRACTION + ((categories.ENERGYPRODUCTION + categories.FACTORY + categories.MASSSTORAGE) * categories.TECH1) , unit.UnitBeingBuilt) then
                    unit:SetPaused( true )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            -- We have positive eco. Check if we can switch something on
            elseif aiBrain:GetEconomyStoredRatio('MASS') >= 0.2 and aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.80 then
                if not unit:IsPaused() then continue end
                unit:SetPaused( false )
                bussy = true
                break -- for _, unit in Engineers do
            elseif aiBrain:GetEconomyStoredRatio('MASS') >= 0.01 and aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.80 then
                if not unit:IsPaused() then continue end
                if EntityCategoryContains((categories.ENERGYPRODUCTION + categories.MASSEXTRACTION) - categories.EXPERIMENTAL, unit.UnitBeingBuilt) then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            elseif aiBrain:GetEconomyStoredRatio('ENERGY') >= 1.00 then
                if not unit:IsPaused() then continue end
                if not EntityCategoryContains(categories.ENERGYPRODUCTION - categories.EXPERIMENTAL, unit.UnitBeingBuilt) then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            end
        end
        if bussy then
            continue -- while true do
        end
-- ECO for FACTORIES
        -- loop over Factories and manage pause / unpause
        for _, unit in Factories do
            -- if the unit is dead, continue with the next unit
            if unit.Dead then continue end
            if aiBrain.HasParagon then
                if unit:IsPaused() then
                    unit:SetPaused( false )
                    bussy = true
                    break -- for _, unit in Engineers do
                end
            -- We have negative eco. Check if we can switch something off
            elseif aiBrain:GetEconomyStoredRatio('MASS') < 0.01 or aiBrain:GetEconomyStoredRatio('ENERGY') < 0.75 then
                if unit:IsPaused() or not unit:IsUnitState('Building') then continue end
                if not unit.UnitBeingBuilt then continue end
                if EntityCategoryContains(categories.ENGINEER + categories.TECH1, unit.UnitBeingBuilt) then continue end
                if table.getn(Factories) == 1 then continue end
                unit:SetPaused( true )
                bussy = true
                break -- for _, unit in Engineers do
            else
                if not unit:IsPaused() then continue end
                unit:SetPaused( false )
                bussy = true
                break -- for _, unit in Engineers do
            end
        end
        if bussy then
            continue -- while true do
        end

-- ECO for STRUCTURES
        if aiBrain:GetEconomyTrend('ENERGY') < 0.0 and not aiBrain.HasParagon then
            -- Emergency Low Energy
            if aiBrain:GetEconomyStoredRatio('ENERGY') < 0.75 then
                -- Disable Nuke
                if DisableUnits(aiBrain, categories.STRUCTURE * categories.MASSFABRICATION, 'MassFab') then bussy = true
                -- Disable AntiNuke
                elseif DisableUnits(aiBrain, categories.STRUCTURE * categories.NUKE * (categories.TECH3 + categories.EXPERIMENTAL), 'Nuke') then bussy = true
                -- Disable Massfabricators
                elseif DisableUnits(aiBrain, categories.STRUCTURE * categories.ANTIMISSILE * categories.SILO * categories.TECH3, 'AntiNuke') then bussy = true
                -- Disable Intel
                elseif DisableUnits(aiBrain, categories.RADAR + categories.OMNI + categories.SONAR, 'Intel') then bussy = true
                -- Disable ExperimentalShields
                elseif DisableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD * categories.EXPERIMENTAL, 'ExperimentalShields') then bussy = true
                -- Disable NormalShields
                elseif DisableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD - categories.EXPERIMENTAL, 'NormalShields') then bussy = true
                end
            elseif aiBrain:GetEconomyStoredRatio('ENERGY') < 0.95 then
                if DisableUnits(aiBrain, categories.STRUCTURE * categories.MASSFABRICATION, 'MassFab') then bussy = true
                end
            end
        end

        if bussy then
            continue -- while true do
        end

        if aiBrain:GetEconomyTrend('MASS') < 0.0 and not aiBrain.HasParagon then
            -- Emergency Low Mass
            if aiBrain:GetEconomyStoredRatio('MASS') < 0.01 then
                -- Disable AntiNuke
                if DisableUnits(aiBrain, categories.STRUCTURE * categories.ANTIMISSILE * categories.SILO * categories.TECH3, 'AntiNuke') then bussy = true
                end
            elseif aiBrain:GetEconomyStoredRatio('MASS') < 0.50 then
                -- Disable Nuke
                if DisableUnits(aiBrain, categories.STRUCTURE * categories.NUKE * (categories.TECH3 + categories.EXPERIMENTAL), 'Nuke') then bussy = true
                end
            end
        elseif aiBrain:GetEconomyStoredRatio('ENERGY') > 0.95 then
            if aiBrain:GetEconomyStoredRatio('MASS') > 0.50 or aiBrain.HasParagon then
                -- Enable NormalShields
                if EnableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD - categories.EXPERIMENTAL, 'NormalShields') then bussy = true
                -- Enable ExperimentalShields
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD * categories.EXPERIMENTAL, 'ExperimentalShields') then bussy = true
                -- Enable Intel
                elseif EnableUnits(aiBrain, categories.RADAR + categories.OMNI + categories.SONAR, 'Intel') then bussy = true
                -- Enable AntiNuke
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.ANTIMISSILE * categories.SILO * categories.TECH3, 'AntiNuke') then bussy = true
                -- Enable massfabricators
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.MASSFABRICATION, 'MassFab') then bussy = true
                -- Enable Nuke
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.NUKE * (categories.TECH3 + categories.EXPERIMENTAL), 'Nuke') then bussy = true
                end
            elseif aiBrain:GetEconomyStoredRatio('MASS') > 0.25 or aiBrain.HasParagon then
                -- Enable NormalShields
                if EnableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD - categories.EXPERIMENTAL, 'NormalShields') then bussy = true
                -- Enable ExperimentalShields
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD * categories.EXPERIMENTAL, 'ExperimentalShields') then bussy = true
                -- Enable Intel
                elseif EnableUnits(aiBrain, categories.RADAR + categories.OMNI + categories.SONAR, 'Intel') then bussy = true
                -- Enable AntiNuke
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.ANTIMISSILE * categories.SILO * categories.TECH3, 'AntiNuke') then bussy = true
                -- Enable massfabricators
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.MASSFABRICATION, 'MassFab') then bussy = true
                end
            else
                -- Enable NormalShields
                if EnableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD - categories.EXPERIMENTAL, 'NormalShields') then bussy = true
                -- Enable ExperimentalShields
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.SHIELD * categories.EXPERIMENTAL, 'ExperimentalShields') then bussy = true
                -- Enable Intel
                elseif EnableUnits(aiBrain, categories.RADAR + categories.OMNI + categories.SONAR, 'Intel') then bussy = true
                -- Enable massfabricators
                elseif EnableUnits(aiBrain, categories.STRUCTURE * categories.MASSFABRICATION, 'MassFab') then bussy = true
                end
            end
        end

        if bussy then
            continue -- while true do
        end



   end
end


