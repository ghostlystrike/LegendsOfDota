local OptionManager = require('optionmanager')
local util = require('util')
local Timers = require('easytimers')

local noMulticast = {}
local noWitchcraft = {}

-- Function to work out if we can multicast with a given spell or not
local canMulticast = function(skillName)
    -- No banned multicast spells
    if noMulticast[skillName] then
        return false
    end

    -- Must be a valid spell
    return true
end

-- Multicast

local multicastChannel = {}
ListenToGameEvent('dota_ability_channel_finished', function(keys)
    for i=0,9 do
        -- Is this player channelling?
        local channel = multicastChannel[i]
        if channel and not channel.handled then
            -- Grab the ability
            local ab = channel.ab

            -- Is this the ability we were looking for?
            if IsValidEntity(ab) and ab:GetAbilityName() == keys.abilityname then
                GameRules:GetGameModeEntity():SetThink(function()
                    -- Is it the right ability, and has the ability stopped channelling?
                    if IsValidEntity(ab) and not ab:IsChanneling() then
                        -- This channel is handled
                        channel.handled = true

                        -- Cleanup multicast units
                        if #channel.units > 0 then
                            local unit = table.remove(channel.units, 1)

                            if IsValidEntity(unit) then
                                local ab2 = unit:FindAbilityByName(keys.abilityname)
                                if ab2 then
                                    ab2:EndChannel(keys.interrupted == 1)
                                end

                                GameRules:GetGameModeEntity():SetThink(function()
                                    UTIL_RemoveImmediate(unit)
                                end, 'channel'..DoUniqueString('channel'), 10, nil)
                            end

                            return 0.1
                        else
                            multicastChannel[i] = nil
                        end
                    end
                end, 'channel'..DoUniqueString('channel'), 0.1, nil)
            end
        end
    end
end, nil)

ListenToGameEvent('dota_player_used_ability', function(keys)
    local ply = EntIndexToHScript(keys.PlayerID or keys.player)
    if ply then
        local hero = ply:GetAssignedHero()
        if hero then
            -- Check for witchcraft
            if not noWitchcraft[keys.abilityname] then
                local mab
                if hero:HasAbility('death_prophet_witchcraft') then
                    mab = hero:FindAbilityByName('death_prophet_witchcraft')
                elseif hero:HasAbility('death_prophet_witchcraft_5') then
                    mab = hero:FindAbilityByName('death_prophet_witchcraft_5')
                elseif hero:HasAbility('death_prophet_witchcraft_10') then
                    mab = hero:FindAbilityByName('death_prophet_witchcraft_10')
                elseif hero:HasAbility('death_prophet_witchcraft_20') then
                    mab = hero:FindAbilityByName('death_prophet_witchcraft_20')
                elseif hero:HasAbility('death_prophet_witchcraft_d') then
                    mab = hero:FindAbilityByName('death_prophet_witchcraft_d')
                end

                if mab then
                    -- Grab the level of the ability
                    local lvl = mab:GetLevel()

                    if lvl > 0 then
                        local ab = hero:FindAbilityByName(keys.abilityname)

                        if ab then
                            local reduction = lvl * -1

                            -- Octarine Core fix
                            if GameRules:isSource1() then
                                if hero:HasModifier('modifier_item_octarine_core') then
                                    reduction = reduction * 0.75
                                end
                            end

                            local timeRemaining = ab:GetCooldownTimeRemaining()
                            local newCooldown = timeRemaining + reduction
                            if newCooldown < 1 then
                                newCooldown = 1
                            end

                            if newCooldown < timeRemaining then
                                ab:EndCooldown()
                                if newCooldown > 0 then
                                    ab:StartCooldown(newCooldown)
                                end
                            end
                        end
                    end
                end
            end

            -- Check if they have multicast
            local multicastMadness = OptionManager:GetOption('multicastMadness')
            if canMulticast(keys.abilityname) then
                local mab

                local doubleMode = false

                -- Grab the ability (PLEAE DEAR LORD, SOMEONE MAKE THIS NICER!)
                if hero:HasAbility('ogre_magi_multicast_lod') then
                    mab = hero:FindAbilityByName('ogre_magi_multicast_lod')
                elseif hero:HasAbility('ogre_magi_multicast_lod_d') then
                    mab = hero:FindAbilityByName('ogre_magi_multicast_lod_d')
                    doubleMode = true
                elseif hero:HasAbility('ogre_magi_multicast_lod_lvl1') then
                    mab = hero:FindAbilityByName('ogre_magi_multicast_lod_lvl1')
                elseif hero:HasAbility('ogre_magi_multicast_lod_d_lvl1') then
                    mab = hero:FindAbilityByName('ogre_magi_multicast_lod_d_lvl1')
                    doubleMode = true
                end

                if multicastMadness or mab then
                    -- Grab the level of the ability
                    local lvl

                    -- Change level based on madness mode
                    if multicastMadness then
                        lvl = 3
                    else
                        lvl = mab:GetLevel()
                    end

                    -- If they have no level in it, stop
                    if lvl == 0 then return end

                    -- How many times we will cast the spell
                    local mult = 0

                    -- Grab a random number
                    local r = RandomFloat(0, 1)

                    -- Calculate multiplyer
                    if doubleMode then
                        if lvl == 1 then
                            if r < 0.25 then
                                mult = 2
                            end
                        elseif lvl == 2 then
                            if r < 0.063 then
                                mult = 4
                            elseif r < 0.13 then
                                mult = 3
                            elseif r < 0.38 then
                                mult = 2
                            end
                        elseif lvl == 3 then
                            if r < 0.125 then
                                mult = 4
                            elseif r < 0.25 then
                                mult = 3
                            elseif r < 0.5 then
                                mult = 2
                            end
                        elseif lvl == 4 then
                            if r < 0.188 then
                                mult = 4
                            elseif r < 0.38 then
                                mult = 3
                            elseif r < 0.63 then
                                mult = 2
                            end
                        elseif lvl == 5 then
                            if r < 0.25 then
                                mult = 4
                            elseif r < 0.50 then
                                mult = 3
                            elseif r < 0.75 then
                                mult = 2
                            end
                        elseif lvl == 6 then
                            if r < 0.313 then
                                mult = 4
                            elseif r < 0.63 then
                                mult = 3
                            elseif r < 0.88 then
                                mult = 2
                            end
                        end
                    else
                        if lvl == 1 then
                            if r < 0.25 then
                                mult = 2
                            end
                        elseif lvl == 2 then
                            if r < 0.2 then
                                mult = 3
                            elseif r < 0.4 then
                                mult = 2
                            end
                        elseif lvl == 3 then
                            if r < 0.125 then
                                mult = 4
                            elseif r < 0.25 then
                                mult = 3
                            elseif r < 0.5 then
                                mult = 2
                            end
                        end
                    end

                    -- Guarantee the multicast
                    if multicastMadness and mult < 2 then
                        mult = 2
                    end

                    -- Are we doing any multiplying?
                    if mult > 0 then
                        local ab = hero:FindAbilityByName(keys.abilityname)

                        -- Is this an item based ability?
                        local isItemAb = false

                        -- If we failed to find it, it might hav e been an item
                        if not ab and (hero:HasModifier('modifier_item_ultimate_scepter') or multicastMadness) then
                            for i=0,5 do
                                -- Grab the slot item
                                local slotItem = hero:GetItemInSlot(i)

                                -- Was this the spell that was cast?
                                if slotItem and slotItem:GetClassname() == keys.abilityname then
                                    -- We found it
                                    ab = slotItem
                                    isItemAb = true
                                    break
                                end
                            end
                        end

                        if ab then
                            -- How long to delay each cast
                            local delay = 0.1--getMulticastDelay(keys.abilityname)

                            -- Grab playerID
                            local playerID = hero:GetPlayerID()

                            -- Handle channelled spells
                            if util:isChannelled(keys.abilityname) then
                                -- Cleanup
                                if multicastChannel[playerID] ~= nil then
                                    while #multicastChannel[playerID].units > 0 do
                                        local unit = table.remove(multicastChannel[playerID].units, 1)
                                        UTIL_RemoveImmediate(unit)
                                    end
                                end

                                -- Create new table
                                multicastChannel[playerID] = {
                                    ab = ab,
                                    units = {}
                                }

                                for multNum=1,mult-1 do
                                    -- Create and store the unit
                                    local multUnit = CreateUnitByName('npc_multicast', hero:GetOrigin(), false, hero, hero, hero:GetTeamNumber())
                                    table.insert(multicastChannel[playerID].units, multUnit)

                                    if multUnit then
                                        multUnit:AddAbility(keys.abilityname)
                                        local multAb = multUnit:FindAbilityByName(keys.abilityname)
                                        if multAb then
                                            -- Level the spell
                                            multAb:SetLevel(ab:GetLevel())

                                            -- Ensure it can't be killed
                                            local dummySpell = multUnit:FindAbilityByName('lod_dummy_unit')
                                            if dummySpell then
                                                dummySpell:SetLevel(1)
                                            end
                                            multUnit:AddNewModifier(multUnit, nil, 'modifier_invulnerable', {})

                                            -- Give it a scepter, if we have one
                                            if hero:HasModifier('modifier_item_ultimate_scepter') then
                                                multUnit:AddNewModifier(multUnit, nil, 'modifier_item_ultimate_scepter', {
                                                    bonus_all_stats = 0,
                                                    bonus_health = 0,
                                                    bonus_mana = 0
                                                })
                                            end

                                            local target = hero:GetCursorCastTarget()
                                            local targets
                                            local pos = hero:GetCursorPosition()

                                            if target then
                                                targets = FindUnitsInRadius(target:GetTeam(),
                                                    target:GetOrigin(),
                                                    nil,
                                                    256,
                                                    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                                    DOTA_UNIT_TARGET_ALL,
                                                    DOTA_UNIT_TARGET_FLAG_NONE,
                                                    FIND_ANY_ORDER,
                                                    false
                                                )
                                            end

                                            GameRules:GetGameModeEntity():SetThink(function()
                                                if IsValidEntity(ab) and ab:IsChanneling() and IsValidEntity(multUnit) then
                                                    if target then
                                                        local newTarget = target
                                                        while #targets > 0 do
                                                            newTarget = table.remove(targets, 1)
                                                            if newTarget ~= target then
                                                                break
                                                            end
                                                        end

                                                        multUnit:CastAbilityOnTarget(newTarget, multAb, -1)
                                                    elseif pos then
                                                        multUnit:CastAbilityOnPosition(pos, multAb, -1)
                                                    else
                                                        UTIL_RemoveImmediate(multUnit)
                                                    end
                                                else
                                                    UTIL_RemoveImmediate(multUnit)
                                                end
                                            end, 'channel'..DoUniqueString('channel'), 0.1 * multNum, nil)
                                        else
                                            UTIL_RemoveImmediate(multUnit)
                                        end
                                    end
                                end

                            else
                                -- Grab the position
                                local pos = hero:GetCursorPosition()
                                local target = hero:GetCursorCastTarget()
                                local isaTargetSpell = false

                                -- Table to store multi units
                                local multUnits

                                local targets
                                if target and util:isTargetSpell(keys.abilityname) then
                                    -- Target based spells dont work in source1, sue me
                                    if GameRules:isSource1() then
                                        -- Disable this experiment
                                        if 1==1 then return end

                                        -- Forget multicasting target based items for now
                                        if isItemAb then return end

                                        multUnits = {}

                                        -- Create dummy units to cast target spells
                                        for multNum=1,mult-1 do
                                            local multUnit = CreateUnitByName('npc_multicast', hero:GetOrigin(), false, hero, hero, hero:GetTeamNumber())

                                            if multUnit then
                                                multUnit:AddAbility(keys.abilityname)
                                                local multAb = multUnit:FindAbilityByName(keys.abilityname)
                                                if multAb then
                                                    -- Level the spell
                                                    multAb:SetLevel(ab:GetLevel())

                                                    -- Store unit
                                                    table.insert(multUnits, multUnit)

                                                    -- Add cleanup timer
                                                    Timers:CreateTimer(function()
                                                        -- Ensure it is still valid
                                                        if IsValidEntity(multUnit) then
                                                            -- Run the cleanup
                                                            UTIL_RemoveImmediate(multUnit)
                                                        end
                                                    end, DoUniqueString('cleanup'), 2)

                                                    -- Ensure it can't be killed
                                                    local dummySpell = multUnit:FindAbilityByName('lod_dummy_unit')
                                                    if dummySpell then
                                                        dummySpell:SetLevel(1)
                                                    end
                                                    multUnit:AddNewModifier(multUnit, nil, 'modifier_invulnerable', {})

                                                    -- Give it a scepter, if we have one
                                                    if hero:HasModifier('modifier_item_ultimate_scepter') then
                                                        multUnit:AddNewModifier(multUnit, nil, 'modifier_item_ultimate_scepter', {
                                                            bonus_all_stats = 0,
                                                            bonus_health = 0,
                                                            bonus_mana = 0
                                                        })
                                                    end
                                                else
                                                    -- Remove straight away
                                                    UTIL_RemoveImmediate(multUnit)
                                                end
                                            end
                                        end
                                    end

                                    isaTargetSpell = true

                                    targets = FindUnitsInRadius(target:GetTeam(),
                                        target:GetOrigin(),
                                        nil,
                                        256,
                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false
                                    )
                                end

                                Timers:CreateTimer(function()
                                    -- Ensure it still exists
                                    if IsValidEntity(ab) then
                                        -- Position cursor
                                        hero:SetCursorPosition(pos)

                                        local ourTarget = target

                                        -- If we have any targets to pick from, pick one
                                        local doneTarget = false
                                        if targets then
                                            -- While there is still possible targets
                                            while #targets > 0 do
                                                -- Pick a random target
                                                local index = math.random(#targets)
                                                local t = targets[index]

                                                -- Ensure it is valid and still alive
                                                if IsValidEntity(t) and t:GetHealth() > 0 and t ~= ourTarget then
                                                    -- Target is valid and alive, target it
                                                    ourTarget = t
                                                    doneTarget = true
                                                    break
                                                else
                                                    -- Invalid target, remove it and find another
                                                    table.remove(targets, index)
                                                end
                                            end
                                        end

                                        if isaTargetSpell then
                                            if IsValidEntity(ourTarget) and ourTarget:GetHealth() > 0 then
                                                if GameRules:isSource1() then
                                                    if #multUnits > 0 then
                                                        -- Do source1 casting, doh!
                                                        local multUnit = table.remove(multUnits)

                                                        if IsValidEntity(multUnit) then
                                                            local multAb = multUnit:FindAbilityByName(keys.abilityname)

                                                            if multAb then
                                                                multUnit:CastAbilityOnTarget(ourTarget, multAb, -1)
                                                            else
                                                                -- Remove straight away
                                                                UTIL_RemoveImmediate(multUnit)
                                                            end
                                                        end
                                                    end
                                                else
                                                    hero:SetCursorCastTarget(ourTarget)
                                                end
                                            else
                                                return
                                            end
                                        end

                                        -- Run the spell again
                                        if not GameRules:isSource1() or not isaTargetSpell then
                                            ab:OnSpellStart()
                                        end

                                        mult = mult-1
                                        if mult > 1 then
                                            return delay
                                        end
                                    end
                                end, DoUniqueString('multicast'), delay)
                            end

                            -- Create sexy particles
                            local prt = ParticleManager:CreateParticle('ogre_magi_multicast', PATTACH_OVERHEAD_FOLLOW, hero)
                            ParticleManager:SetParticleControl(prt, 1, Vector(mult, 0, 0))
                            ParticleManager:ReleaseParticleIndex(prt)

                            prt = ParticleManager:CreateParticle('ogre_magi_multicast_b', PATTACH_OVERHEAD_FOLLOW, hero:GetCursorCastTarget() or hero)
                            prt = ParticleManager:CreateParticle('ogre_magi_multicast_b', PATTACH_OVERHEAD_FOLLOW, hero)
                            ParticleManager:ReleaseParticleIndex(prt)

                            prt = ParticleManager:CreateParticle('ogre_magi_multicast_c', PATTACH_OVERHEAD_FOLLOW, hero:GetCursorCastTarget() or hero)
                            ParticleManager:SetParticleControl(prt, 1, Vector(mult, 0, 0))
                            ParticleManager:ReleaseParticleIndex(prt)

                            -- Play the sound
                            hero:EmitSound('Hero_OgreMagi.Fireblast.x'..(mult-1))
                        end
                    end
                end
            end
        end
    end
end, nil)

-- Abaddon ulty fix
ListenToGameEvent('entity_hurt', function(keys)
    -- Grab the entity that was hurt
    local ent = EntIndexToHScript(keys.entindex_killed)

    -- Ensure it is a valid hero
    if ent and ent:IsRealHero() then
        -- The min amount of hp
        local minHP = 400

        -- Ensure their health has dropped low enough
        if ent:GetHealth() <= minHP then
            local ab
            if ent:HasAbility('abaddon_borrowed_time') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time')
            elseif ent:HasAbility('abaddon_borrowed_time_5') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_5')
            elseif ent:HasAbility('abaddon_borrowed_time_10') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_10')
            elseif ent:HasAbility('abaddon_borrowed_time_20') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_20')
            elseif ent:HasAbility('abaddon_borrowed_time_d') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_d')
            elseif ent:HasAbility('abaddon_borrowed_time_lvl1') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_lvl1')
            elseif ent:HasAbility('abaddon_borrowed_time_5_lvl1') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_5_lvl1')
            elseif ent:HasAbility('abaddon_borrowed_time_10_lvl1') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_10_lvl1')
            elseif ent:HasAbility('abaddon_borrowed_time_20_lvl1') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_20_lvl1')
            elseif ent:HasAbility('abaddon_borrowed_time_d_lvl1') then
                ab = ent:FindAbilityByName('abaddon_borrowed_time_d_lvl1')
            end

            -- Do they even have the ability in question?
            if ab then
                -- Is the ability ready to use?
                if ab:IsCooldownReady() then
                    -- Grab the level
                    local lvl = ab:GetLevel()

                    -- Is the skill even skilled?
                    if lvl > 0 then
                        -- Fix their health
                        ent:SetHealth(2*minHP - ent:GetHealth())

                        -- Add the modifier
                        ent:AddNewModifier(ent, ab, 'modifier_abaddon_borrowed_time', {
                            duration = ab:GetSpecialValueFor('duration'),
                            duration_scepter = ab:GetSpecialValueFor('duration_scepter'),
                            redirect = ab:GetSpecialValueFor('redirect'),
                            redirect_range_tooltip_scepter = ab:GetSpecialValueFor('redirect_range_tooltip_scepter')
                        })

                        -- Apply the cooldown
                        if lvl == 1 then
                            ab:StartCooldown(60)
                        elseif lvl == 2 then
                            ab:StartCooldown(50)
                        else
                            ab:StartCooldown(40)
                        end
                    end
                end
            end
        end
    end
end, nil)

-- Allow stuff to be set externally
local SpellFixes = {}
function SpellFixes:SetNoCasting(mc, wc)
    noMulticast = mc
    noWitchcraft = wc
end

return SpellFixes