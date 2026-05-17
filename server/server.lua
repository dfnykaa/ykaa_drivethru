local ESX = nil
local QBCore = nil

CreateThread(function()
    local framework = Config.Framework

    if framework == "auto" then
        if GetResourceState('es_extended') == 'started' then
            framework = "esx"
        elseif GetResourceState('qb-core') == 'started' then
            framework = "qb"
        end
    end

    if framework == "esx" then
        ESX = exports['es_extended']:getSharedObject()
        Config.Framework = "esx"
    elseif framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()
        Config.Framework = "qb"
    end
end)

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

local lastPurchase = {}

local function CheckRateLimit(source)
    local curTime = GetGameTimer()
    if not lastPurchase[source] then
        lastPurchase[source] = { time = curTime, count = 1 }
        return true
    end

    local timeDiff = curTime - lastPurchase[source].time
    if timeDiff < Config.Cooldown then
        lastPurchase[source].count = lastPurchase[source].count + 1
        if lastPurchase[source].count > 5 then
            return false, Translate("rate_limit_bypass")
        end
    else
        lastPurchase[source].time = curTime
        lastPurchase[source].count = 1
    end
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    if lastPurchase[src] then
        lastPurchase[src] = nil
    end
end)

local function GetPlayerDetails(source)
    local license = "N/A"
    local discord = "N/A"
    local steam = "N/A"
    local ip = GetPlayerEndpoint(source) or "N/A"
    
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, "license:") then
            license = id
        elseif string.find(id, "discord:") then
            discord = id
        elseif string.find(id, "steam:") then
            steam = id
        end
    end
    return license, discord, steam, ip
end

local function SendToDiscord(title, description, color)
    if not Webhook or not Webhook.DriveThru or Webhook.DriveThru == "" or Webhook.DriveThru == "YOUR_WEBHOOK_HERE" then
        return
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = {
                ["text"] = Translate("discord_footer", os.date("%d.%m.%Y %H:%M:%S"))
            }
        }
    }

    PerformHttpRequest(Webhook.DriveThru, function(status, text, headers) end, 'POST', json.encode({
        username = Translate("discord_username"),
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

local function BanPlayer(source, reason)
    local name = GetPlayerName(source) or "Neznámý hráč"
    local license, discord, steam, ip = GetPlayerDetails(source)

    local alertMessage = Translate("discord_exploit_msg", name, source, reason, license, discord, steam, ip)

    SendToDiscord(Translate("discord_exploit_title"), alertMessage, 16711680)

    if Config.BanCheater then
        DropPlayer(source, Translate("ban_reason", reason))
    end
end

RegisterNetEvent('ykaa_drivethru:server:buyItem', function(shopIndex, itemIndex, quantity)
    local src = source

    local allowed, limitErr = CheckRateLimit(src)
    if not allowed then
        BanPlayer(src, limitErr)
        return
    end

    if type(shopIndex) ~= "number" or type(itemIndex) ~= "number" or type(quantity) ~= "number" then
        BanPlayer(src, Translate("payload_manipulation"))
        return
    end

    local shop = Config.Peds[shopIndex]
    if not shop then
        BanPlayer(src, Translate("invalid_shop_index", tostring(shopIndex)))
        return
    end

    local item = shop.items[itemIndex]
    if not item then
        BanPlayer(src, Translate("invalid_item_index", shop.name, tostring(itemIndex)))
        return
    end

    quantity = math.floor(quantity)
    if quantity <= 0 or quantity > 100 then
        BanPlayer(src, Translate("invalid_quantity_exploit", tostring(quantity)))
        return
    end

    local playerPed = GetPlayerPed(src)
    if not DoesEntityExist(playerPed) then
        BanPlayer(src, Translate("invalid_ped_exploit"))
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local shopCoords = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
    local distance = #(playerCoords - shopCoords)

    if distance > 15.0 then
        BanPlayer(src, Translate("invalid_distance_exploit", distance))
        return
    end

    local totalPrice = item.price * quantity
    local itemLabel = Translate(item.labelKey)

    if Config.Framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end

        local cash = xPlayer.getMoney()
        local bank = xPlayer.getAccount('bank').money
        local paymentMethod = nil

        if Config.PaymentType == "cash" then
            if cash >= totalPrice then paymentMethod = "cash" end
        elseif Config.PaymentType == "bank" then
            if bank >= totalPrice then paymentMethod = "bank" end
        else
            if cash >= totalPrice then
                paymentMethod = "cash"
            elseif bank >= totalPrice then
                paymentMethod = "bank"
            end
        end

        if not paymentMethod then
            TriggerClientEvent('ykaa_drivethru:client:notify', src, Translate("drivethru_title"), Translate("not_enough_money"), 'error')
            return
        end

        local canCarry = false
        if GetResourceState('ox_inventory') == 'started' then
            canCarry = exports.ox_inventory:CanCarryItem(src, item.name, quantity)
        else
            if xPlayer.canCarryItem then
                canCarry = xPlayer.canCarryItem(item.name, quantity)
            else
                canCarry = true
            end
        end

        if not canCarry then
            TriggerClientEvent('ykaa_drivethru:client:notify', src, Translate("drivethru_title"), Translate("inv_full"), 'error')
            return
        end

        if paymentMethod == "cash" then
            xPlayer.removeMoney(totalPrice)
        else
            xPlayer.removeAccountMoney('bank', totalPrice)
        end

        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:AddItem(src, item.name, quantity)
        else
            xPlayer.addInventoryItem(item.name, quantity)
        end

        TriggerClientEvent('ykaa_drivethru:client:notify', src, shop.name, Translate("buy_success", quantity, itemLabel, totalPrice), 'success')
        
        local paymentMethodLabel = paymentMethod == "cash" and Translate("cash_label") or Translate("bank_label")
        SendToDiscord(
            Translate("discord_buy_title", shop.name),
            Translate("discord_buy_msg", GetPlayerName(src), src, quantity, itemLabel, totalPrice, paymentMethodLabel),
            65280
        )

    elseif Config.Framework == "qb" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local cash = Player.Functions.GetMoney('cash')
        local bank = Player.Functions.GetMoney('bank')
        local paymentMethod = nil

        if Config.PaymentType == "cash" then
            if cash >= totalPrice then paymentMethod = "cash" end
        elseif Config.PaymentType == "bank" then
            if bank >= totalPrice then paymentMethod = "bank" end
        else
            if cash >= totalPrice then
                paymentMethod = "cash"
            elseif bank >= totalPrice then
                paymentMethod = "bank"
            end
        end

        if not paymentMethod then
            TriggerClientEvent('ykaa_drivethru:client:notify', src, Translate("drivethru_title"), Translate("not_enough_money"), 'error')
            return
        end

        if Player.Functions.AddItem(item.name, quantity) then
            Player.Functions.RemoveMoney(paymentMethod, totalPrice, "drivethru-purchase")
            
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], "add")
            TriggerClientEvent('ykaa_drivethru:client:notify', src, shop.name, Translate("buy_success", quantity, itemLabel, totalPrice), 'success')
            
            local paymentMethodLabel = paymentMethod == "cash" and Translate("cash_label") or Translate("bank_label")
            SendToDiscord(
                Translate("discord_buy_title", shop.name),
                Translate("discord_buy_msg", GetPlayerName(src), src, quantity, itemLabel, totalPrice, paymentMethodLabel),
                65280
            )
        else
            TriggerClientEvent('ykaa_drivethru:client:notify', src, Translate("drivethru_title"), Translate("inv_full"), 'error')
        end
    else
        TriggerClientEvent('ykaa_drivethru:client:notify', src, Translate("error_title"), Translate("framework_error"), 'error')
    end
end)
