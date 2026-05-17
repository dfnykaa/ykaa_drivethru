local spawnedPeds = {}
local OpenDriveThruMenu
local SelectItemQuantity

local lang = Config.Locale
local fileContent = LoadResourceFile(GetCurrentResourceName(), "locales/" .. lang .. ".lua")
if fileContent then
    local func, err = load(fileContent, "locales/" .. lang .. ".lua")
    if func then
        func()
    end
end

local function Translate(key, ...)
    local lang = Config.Locale or "cs"
    local translation = Locales and Locales[lang] and Locales[lang][key] or key
    return string.format(translation, ...)
end

CreateThread(function()
    for i, shop in ipairs(Config.Peds) do
        if shop.blip and shop.blip.enabled then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipColour(blip, shop.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.blip.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

local function AddTargetToPed(ped, index, labelKey, icon, shopName)
    local targetType = Config.Target
    if targetType == "auto" then
        if GetResourceState('ox_target') == 'started' then
            targetType = "ox"
        elseif GetResourceState('qb-target') == 'started' then
            targetType = "qb"
        elseif GetResourceState('qtarget') == 'started' then
            targetType = "qtarget"
        end
    end

    local label = Translate(labelKey or "order_target", shopName)

    if targetType == "ox" then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'ykaa_drivethru_' .. index,
                icon = icon or 'fas fa-hamburger',
                label = label,
                onSelect = function()
                    OpenDriveThruMenu(index)
                end,
                distance = 3.0
            }
        })
    elseif targetType == "qb" then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    icon = icon or 'fas fa-hamburger',
                    label = label,
                    action = function()
                        OpenDriveThruMenu(index)
                    end,
                }
            },
            distance = 3.0
        })
    elseif targetType == "qtarget" then
        exports.qtarget:AddTargetEntity(ped, {
            options = {
                {
                    icon = icon or 'fas fa-hamburger',
                    label = label,
                    action = function()
                        OpenDriveThruMenu(index)
                    end,
                }
            },
            distance = 3.0
        })
    end
end

local function RemoveTargetFromPed(ped, index)
    local targetType = Config.Target
    if targetType == "auto" then
        if GetResourceState('ox_target') == 'started' then
            targetType = "ox"
        elseif GetResourceState('qb-target') == 'started' then
            targetType = "qb"
        elseif GetResourceState('qtarget') == 'started' then
            targetType = "qtarget"
        end
    end

    if targetType == "ox" then
        exports.ox_target:removeLocalEntity(ped, 'ykaa_drivethru_' .. index)
    elseif targetType == "qb" then
        local currentShop = Config.Peds[index]
        if currentShop then
            local label = Translate(currentShop.targetLabelKey or "order_target", currentShop.name)
            exports['qb-target']:RemoveTargetEntity(ped, label)
        end
    elseif targetType == "qtarget" then
        local currentShop = Config.Peds[index]
        if currentShop then
            local label = Translate(currentShop.targetLabelKey or "order_target", currentShop.name)
            exports.qtarget:RemoveTargetEntity(ped, label)
        end
    end
end

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1500

        for i, shop in ipairs(Config.Peds) do
            local shopCoords = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
            local distance = #(playerCoords - shopCoords)

            if distance < 45.0 then
                sleep = 500
                if not spawnedPeds[i] then
                    local model = shop.pedModel
                    local hash = type(model) == "string" and GetHashKey(model) or model
                    
                    RequestModel(hash)
                    local timer = GetGameTimer()
                    while not HasModelLoaded(hash) do
                        Wait(0)
                        if GetGameTimer() - timer > 3000 then
                            break
                        end
                    end

                    if not HasModelLoaded(hash) then
                        model = "mp_m_shopkeep_01"
                        hash = GetHashKey(model)
                        RequestModel(hash)
                        timer = GetGameTimer()
                        while not HasModelLoaded(hash) do
                            Wait(0)
                            if GetGameTimer() - timer > 3000 then
                                break
                            end
                        end
                    end

                    if HasModelLoaded(hash) then
                        local heading = shop.coords.w or 0.0
                        local ped = CreatePed(4, hash, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, heading, false, false)
                        
                        if ped and ped ~= 0 then
                            SetEntityAsMissionEntity(ped, true, true)
                            SetPedHearingRange(ped, 0.0)
                            SetPedSeeingRange(ped, 0.0)
                            SetPedAlertness(ped, 0.0)
                            SetPedFleeAttributes(ped, 0, 0)
                            SetBlockingOfNonTemporaryEvents(ped, true)
                            SetEntityInvincible(ped, true)
                            FreezeEntityPosition(ped, true)
                            
                            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
                            
                            spawnedPeds[i] = ped
                            AddTargetToPed(ped, i, shop.targetLabelKey, shop.targetIcon, shop.name)
                        end
                        
                        SetModelAsNoLongerNeeded(hash)
                    end
                end
            else
                if spawnedPeds[i] then
                    RemoveTargetFromPed(spawnedPeds[i], i)
                    DeleteEntity(spawnedPeds[i])
                    spawnedPeds[i] = nil
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for index, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            RemoveTargetFromPed(ped, index)
            DeleteEntity(ped)
        end
    end
end)

OpenDriveThruMenu = function(index)
    local shop = Config.Peds[index]
    if not shop then return end

    local options = {}
    for i, item in ipairs(shop.items) do
        local localizedLabel = Translate(item.labelKey)
        local localizedDesc = Translate(item.descKey)
        local priceLabel = Translate("price_label")

        table.insert(options, {
            title = localizedLabel,
            description = string.format("%s\n%s: $%d", localizedDesc, priceLabel, item.price),
            icon = item.icon or "hamburger",
            arrow = true,
            onSelect = function()
                SelectItemQuantity(index, i)
            end
        })
    end

    lib.registerContext({
        id = 'ykaa_drivethru_menu_' .. index,
        title = Translate("menu_title", shop.name),
        options = options
    })
    lib.showContext('ykaa_drivethru_menu_' .. index)
end

SelectItemQuantity = function(shopIndex, itemIndex)
    local shop = Config.Peds[shopIndex]
    local item = shop.items[itemIndex]
    local itemLabel = Translate(item.labelKey)
    
    local input = lib.inputDialog(Translate("drivethru_title") .. " - " .. itemLabel, {
        {
            type = 'number',
            label = Translate("buy_quantity"),
            description = Translate("buy_desc", item.price),
            default = 1,
            min = 1,
            max = 100,
            required = true
        }
    })

    if not input or not input[1] then
        OpenDriveThruMenu(shopIndex)
        return
    end

    local quantity = math.floor(tonumber(input[1]))
    if not quantity or quantity <= 0 then
        lib.notify({
            title = Translate("error_title"),
            description = Translate("invalid_quantity"),
            type = 'error'
        })
        OpenDriveThruMenu(shopIndex)
        return
    end

    TriggerServerEvent('ykaa_drivethru:server:buyItem', shopIndex, itemIndex, quantity)
end

RegisterNetEvent('ykaa_drivethru:client:notify', function(title, text, type)
    lib.notify({
        title = title,
        description = text,
        type = type or 'info'
    })
end)
