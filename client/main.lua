local Core = exports.vorp_core:GetCore()

local function spawnNpc()
    for i, v in ipairs(Config.trainers) do
        if Config.aiTrainerped then
            local hashModel = (v.npcmodel)
            if not IsModelValid(hashModel) then
                print("Model not valid", hashModel)
                return
            end

            if not HasModelLoaded(hashModel) then
                RequestModel(hashModel, false)
                while not HasModelLoaded(hashModel) do
                    Wait(100)
                end
            end

            local npc = CreatePed(joaat(hashModel), v.coords.x, v.coords.y, v.coords.z, v.heading, false, false, false,
                false)
            repeat Wait(0) until DoesEntityExist(npc)
            SetRandomOutfitVariation(npc, true)
            SetEntityNoCollisionEntity(PlayerPedId(), npc, false)
            SetEntityCanBeDamaged(npc, false)
            SetEntityInvincible(npc, true)
            Wait(1000)
            FreezeEntityPosition(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            v.NpcHandle = npc
        end
    end
end

local function createBlip()
    for i, v in ipairs(Config.trainers) do
        local blip = BlipAddForCoords(1664425300, v.coords.x, v.coords.y, v.coords.z)
        SetBlipSprite(blip, v.blip, true)
        SetBlipName(blip, v.trainername)
        v.BlipHandle = blip
    end
end



RegisterNetEvent("vorp:SelectedCharacter", function()
    Wait(5000)
    spawnNpc()
    createBlip()
end)


local tamestate = 0
CreateThread(function() -- captures event when you break horse in
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        Wait(0)
        local size = GetNumberOfEvents(0)
        if size > 0 then
            for i = 0, size - 1 do
                local eventAtIndex = GetEventAtIndex(0, i)
                if eventAtIndex == GetHashKey("EVENT_HORSE_BROKEN") then
                    tamestate = 1
                end
            end
        end
    end
end)

local function sellAnimal(coords)         -- Selling horse function
    local horse = GetMount(PlayerPedId()) -- Gets mount
    local model = GetEntityModel(horse)
    if model ~= 0 then
        if tamestate > 0 then             -- checks to see if you recently broke the horse in
            if Config.Animals[model] then -- Paying for animals
                local animal = Config.Animals[model]

                local data = {
                    money = animal.money,
                    gold = animal.gold,
                    rolPoints = animal.rolPoints,
                    xp = animal.xp,
                    coords = coords
                }

                TriggerServerEvent("vorp_sellhorse:giveReward", data)
                Core.NotifyRightTip(Config.Language.AnimalSold, 4000) -- Sold notification
                DeletePed(horse)
                Wait(100)
                tamestate = 0
            else
                Core.NotifyRightTip(Config.Language.NotInTheTrainer, 4000) -- Notification when horse is not recognized
            end
        else
            Core.NotifyRightTip(Config.Language.NotBroken, 4000) -- Notification when you didn't break the horse
        end
    else
        Core.NotifyRightTip(Config.Language.NoMount, 4000) -- Notification when you don't have a mount
    end
end


local function createPrompt()
    local promptGroup = GetRandomIntInRange(0, 0x7FFFFFFF)
    local prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, 0xD9D0E1C0)
    local str = VarString(10, "LITERAL_STRING", Config.trainers[1].pressToSell)
    UiPromptSetText(prompt, str)
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetStandardMode(prompt, true)
    UiPromptSetGroup(prompt, promptGroup, 0)
    UiPromptRegisterEnd(prompt)
    return promptGroup, prompt
end

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    local group, prompt = createPrompt()
    while true do
        local sleep = 1000
        for index, v in ipairs(Config.trainers) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - v.coords)

            if distance < 80 then
                if not v.NpcHandle then
                    spawnNpc()
                end
            else
                if v.NpcHandle then
                    if DoesEntityExist(v.NpcHandle) then
                        DeleteEntity(v.NpcHandle)
                    end
                    v.NpcHandle = nil
                end
            end

            if distance <= v.radius then
                sleep = 0
                local label = VarString(10, "LITERAL_STRING", v.trainername)
                UiPromptSetActiveGroupThisFrame(group, label, 0, 0, 0, 0)

                if UiPromptHasStandardModeCompleted(prompt, 0) then -- need to add here player is in the locations
                    if Config.joblocked then
                        Core.Callback.TriggerAsync('vorp_sellhorse:getjob', function(result)
                            if result then
                                sellAnimal(v.coords)
                            else
                                Core.NotifyRightTip(Config.Language.notatrainer .. " : " .. v.trainerjob, 4000)
                            end
                        end, index)
                    else
                        sellAnimal(v.coords)
                    end
                    Wait(1000)
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for i, v in ipairs(Config.trainers) do
        if v.NpcHandle then
            if DoesEntityExist(v.NpcHandle) then
                DeleteEntity(v.NpcHandle)
            end
        end

        if v.BlipHandle then
            RemoveBlip(v.BlipHandle)
        end
    end
end)


-- DEV TOOLS --

--[[ RegisterCommand("horse", function() -- prints what entity model current mount is
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058, PlayerPedId())
    local model = GetEntityModel(horse)
    print("model", model)
end)

RegisterCommand("dh", function()                                          -- deletes horse
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058, PlayerPedId()) --
    DeletePed(horse)
end)
 ]]
