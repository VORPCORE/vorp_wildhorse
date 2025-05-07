local Core = exports.vorp_core:GetCore()
local horsesBroken = {}

-- save horses broken for security
RegisterServerEvent("vorp_sellhorse:brokeHorse", function(netid)
    local _source = source

    local entity = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(entity) then
        if not horsesBroken[netid] then
            horsesBroken[netid] = _source
        end
    end
end)

RegisterServerEvent("vorp_sellhorse:giveReward", function(data)
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end

    local character = user.getUsedCharacter
    local job = character.job
    local netid = data.netid
    local sourcePed = GetPlayerPed(_source)
    local sourceCoords = GetEntityCoords(sourcePed)

    -- must be close to the seller to sell it
    local distance = #(data.coords - sourceCoords)
    if distance > 5 then
        Core.AddWebhook("Possible Cheater", Config.WebhookCheatLog,
            "player with steam: " ..
            character.identifier ..
            " server id: " ..
            _source .. " coords: " .. json.encode(data.coords) .. " distance is too far from the trainer")
        return
    end

    if Config.joblocked then
        if not Config.trainers[data.index].trainerjob[job] then
            --! job is not found , means is different ffrom the statebag used on the client
            Core.AddWebhook("Possible Cheater", Config.WebhookCheatLog,
                "player with steam: " ..
                character.identifier ..
                " server id: " .. _source .. " coords: " .. json.encode(data.coords) .. " job doesnt match statebag")
            return
        end
    end

    -- must exist
    local entity = NetworkGetEntityFromNetworkId(netid)
    if not DoesEntityExist(entity) then
        return print("horse not found with netid: " .. netid)
    end

    -- must have been broken by this source
    if not horsesBroken[netid] or horsesBroken[netid] ~= _source then
        return print("horse not broken with netid: " .. netid)
    end

    local skills = character.skills
    if not skills then
        return error("update vorp core")
    end

    local skill = skills[Config.SkillName]
    if not skill then
        error("skill not found in vorp core config")
    end

    local model = Config.Animals[data.model]
    if not model then
        return print("model not found in config")
    end


    local skillLevel = skill.Level
    local skillMaxLevel = skill.MaxLevel
    -- if skill level is in the config or the skill level is maxed
    if Config.SkillsLevel[skillLevel] or #Config.SkillsLevel >= skillMaxLevel then
        local info = Config.SkillsLevel[skillLevel]
        local percentage = 0
        if not info then
            percentage = Config.SkillsLevel[#Config.SkillsLevel].percentage
        else
            percentage = Config.SkillsLevel[skillLevel].percentage
        end
        model.money = model.money + (model.money * percentage)
        model.gold = model.gold + (model.gold * percentage)
        model.rolPoints = model.rolPoints + (model.rolPoints * percentage)
    end

    if model.money ~= 0 then
        character.addCurrency(0, model.money) -- add money
    end

    if model.gold ~= 0 then
        character.addCurrency(1, model.gold) -- add gold
    end

    if model.rolPoints ~= 0 then
        character.addCurrency(2, model.rolPoints) -- add rolPoints
    end

    -- add xp to skill
    character.setSkills(Config.SkillName, model.xp)
    Core.NotifyRightTip(_source, Config.Language.AnimalSold .. " skills Gained: " .. model.xp .. " xp", 4000)
    --! add webhook
    Core.AddWebhook("Animal Sold", Config.WebhookAnimalSold,
        "player with steam: " .. character.identifier .. " server id: " .. _source ..
        " sold an animal : " ..
        model.name ..
        " for $" .. model.money .. " money, " .. model.gold .. " gold, " .. model.rolPoints .. " rolPoints")

    SetTimeout(4000, function()
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        horsesBroken[netid] = nil
    end)
end)

--on player disconnect
AddEventHandler("playerDropped", function()
    local _source = source

    for k, v in pairs(horsesBroken) do
        if v == _source then
            horsesBroken[k] = nil
        end
    end
end)
