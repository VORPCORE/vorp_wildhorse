local Core = exports.vorp_core:GetCore()

RegisterServerEvent("vorp_sellhorse:giveReward", function(data)
    local _source = source
    local Character = Core.getUser(_source)
    if not Character then
        return
    end
    local sourcePed = GetPlayerPed(_source)
    local sourceCoords = GetEntityCoords(sourcePed)
    local distance = #(data.coords - sourceCoords)
    if distance > 5 then
        print(_source, Character.identifier, " this is a cheater bann player ")
        Core.AddWebhook("Cheater", Config.WebhookCheatLog,
            "player with steam: " .. Character.identifier .. " server id: " .. _source .. " is cheating")
        return
    end

    Character = Character.getUsedCharacter
    local skills = Character.skills
    if not skills then return error("update vorp core") end
    if not skills[Config.SkillName] then error("skill not found in vorp core config") end

    local skill = skills[Config.SkillName]
    local skillLevel = skill.Level
    local skillMaxLevel = skill.MaxLevel
    -- if skill level is in the config or the skill level is maxed
    if Config.SkillsLevel[skillLevel] or #Config.SkillsLevel >= skillMaxLevel then
        local info = Config.SkillsLevel[skillLevel]
        local percentage = 0
        if not info then
            -- if maxed out choose last one
            percentage = Config.SkillsLevel[#Config.SkillsLevel].percentage
        else
            percentage = Config.SkillsLevel[skillLevel].percentage
        end
        data.money = data.money + (data.money * percentage)
        data.gold = data.gold + (data.gold * percentage)
        data.rolPoints = data.rolPoints + (data.rolPoints * percentage)
    end

    if type(data) == "table" then
        if data.money ~= 0 then
            Character.addCurrency(0, data.money)
        end

        if data.gold ~= 0 then
            Character.addCurrency(1, data.gold)
        end

        if data.rolPoints ~= 0 then
            Character.addCurrency(2, data.rolPoints)
        end
        -- add xp to skill
        Character.setSkills(Config.SkillName, data.xp)
    else
        print(_source, Character.identifier, " this is a cheater bann player ")
        Core.AddWebhook("Cheater", Config.WebhookCheatLog,
            "player with steam: " .. Character.identifier .. " server id: " .. _source .. " is cheating")
    end
end)

local function CheckJob(index, job)
    for i, value in ipairs(Config.trainers[index].trainerjob) do
        if value == job then
            return true
        end
    end
    return false
end

Core.Callback.Register('vorp_sellhorse:getjob', function(source, cb, args)
    local _source = source
    local index = args
    local Character = Core.getUser(_source).getUsedCharacter
    local job = Character.job
    if CheckJob(index, job) then
        return cb(true)
    end
    Core.NotifyObjective(_source, "you do not have the right job to sell this animal", 4000)
    return cb(false)
end)
