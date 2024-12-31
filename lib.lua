---@class Lib
local Lib = {}
function Lib.getConfig(conf)
    local ok, result = pcall(Kristal.getLibConfig, "gasterscoolsocialnetwork", conf)
    if not ok then return (Kristal.Config["plugins/gcsn"][conf] or ({
        ["domain"] = "serveo.net",
        ["chat_format"] = "%s: ",
        ["port"] = 25574
    })[conf]) end
    return result
end
Game.socket = require("socket")

Game.client = assert(
    Game.socket.connect(
        Lib.getConfig("domain"),
        Lib.getConfig("port")
    )
)

local socket = Game.socket
local json = JSON

local function sendToServer(client, message)
    local encodedMessage = json.encode(message)
    -- print("[OUT] "..Utils.dump(encodedMessage))
    client:send(encodedMessage .. "\n")
end

function Game:sendToServer(client, message) --do not say a word
    sendToServer(client, message)
end

function Lib:receiveFromServer(client)
    local response, err, partial = client:receive()
    if partial then
        self.partial = self.partial .. partial
    elseif response then
        local decodedResponse = json.decode(self.partial .. response)
        self.partial = ""
        return decodedResponse
    elseif err ~= "timeout" then
        print("Error: ", err)
    end
end

local client = Game.client
client:settimeout(0)

-- Throttle interval (in seconds)
local THROTTLE_INTERVAL = 0.05
local HEARTBEAT_INTERVAL = 10.0
local lastHearbeatTime = love.timer.getTime()
local lastUpdateTime = 0
local lastPlayerListTime = 0
function Lib:init()
    ---@type ChatInputBox
    self.chat_box = ChatInputBox()
    self.partial = ""
    Utils.hook(World, 'update', function (orig, wld, ...)
        orig(wld,...)
        self:updateWorld()
    end)
    Utils.hook(Game, "update", function (orig, ...)
        orig(...)
        self:update()
    end)
    Utils.hook(Battle, "update", function (orig, batl, ...)
        orig(batl, ...)
        self:updateBattle(batl)
    end)
    Utils.hook(BattleUI, "drawState", function (orig, batl_ui, ...)
        if Game.battle.state == "PARTYSELECT" then
            local full_party = self:partyTable()

            local page = math.ceil(Game.battle.current_menu_y / 3) - 1
            local max_page = math.ceil(#full_party / 3) - 1
            local page_offset = page * 3

            local party = full_party[Game.battle.current_selecting].chara
            if party.soul_color then
                Draw.setColor(party.soul_color)
            else
                Draw.setColor(Game.battle.encounter:getSoulColor())
            end
            local heart_sprite = batl_ui.heart_sprite
            if party.heart_sprite then
                heart_sprite = Assets.getTexture(party.heart_sprite)
            end
            Draw.draw(heart_sprite, 55, 30 + ((Game.battle.current_menu_y - page_offset) * 30))

            local font = Assets.getFont("main")
            love.graphics.setFont(font)

            for index = page_offset+1, math.min(page_offset+3, #full_party) do
                Draw.setColor(1, 1, 1, 1)

                --if not full_party[index].chara then
                --    love.graphics.print(full_party[index].name, 80, 50 + ((index - page_offset - 1) * 30))
                --else
                    love.graphics.print(full_party[index].chara:getName(), 80, 50 + ((index - page_offset - 1) * 30))
                --end
                
                local mhp_perc = full_party[index].chara:getStat("health") / full_party[index].chara:getStat("health_def")
                if mhp_perc <= 0 then
                    Draw.setColor(1, 0, 0, 1)
                    love.graphics.print("(Fallen)", 400, 50 + ((index - page_offset - 1) * 30))
                else
                    Draw.setColor(COLORS.dkgray)
                    love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), 101, 16)

                    Draw.setColor(PALETTE["action_health_bg"])
                    love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), math.ceil(mhp_perc * 101), 16)

                    local percentage = full_party[index].chara:getHealth() / full_party[index].chara:getStat("health")
                    Draw.setColor(PALETTE["action_health"])
                    love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), math.ceil(percentage * (math.ceil(mhp_perc * 101))), 16)
                end
            end

            Draw.setColor(1, 1, 1, 1)
            if page < max_page then
                Draw.draw(batl_ui.arrow_sprite, 20, 120 + (math.sin(Kristal.getTime()*6) * 2))
            end
            if page > 0 then
                Draw.draw(batl_ui.arrow_sprite, 20, 70 - (math.sin(Kristal.getTime()*6) * 2), 0, 1, -1)
            end
            return
        end
        
        orig(batl_ui, ...)
    end)
    Utils.hook(Battle, "onKeyPressed", function (orig, batl, key, ...)
        if batl.state == "PARTYSELECT" then
            local bus = self:partyTable()

            if not bus[batl.current_menu_y] then
                batl.current_menu_y = 1
                return
            end

            if Input.isConfirm(key) then
                if batl.encounter:onPartySelect(batl.state_reason, batl.current_menu_y) then return end
                if Kristal.callEvent(KRISTAL_EVENT.onBattlePartySelect, batl.state_reason, batl.current_menu_y) then return end
                batl.ui_select:stop()
                batl.ui_select:play()
                if batl.state_reason == "SPELL" then
                    batl:pushAction("SPELL", bus[batl.current_menu_y], batl.selected_spell)
                elseif batl.state_reason == "ITEM" then
                    batl:pushAction("ITEM", bus[batl.current_menu_y], batl.selected_item)
                end
                return
            end
            if Input.is("up", key) then
                batl.ui_move:stop()
                batl.ui_move:play()
                batl.current_menu_y = batl.current_menu_y - 1
                if batl.current_menu_y < 1 then
                    batl.current_menu_y = #bus
                end
                return
            elseif Input.is("down", key) then
                batl.ui_move:stop()
                batl.ui_move:play()
                batl.current_menu_y = batl.current_menu_y + 1
                if batl.current_menu_y > #bus then
                    batl.current_menu_y = 1
                end
                return
            end
        end
        orig(batl, key, ...)
    end)
end
function Lib:partyTable()
    local full_party = {}
    for i, party in ipairs(Game.battle.party) do
        table.insert(full_party, party)
    end
    for i, party in pairs(self.other_battlers) do
        table.insert(full_party, party)
    end
    
    return full_party
end
function Lib:postInit()
    Game.stage:addChild(self.chat_box)
    self.name = self.getConfig("username") or Game.save_name
    self.other_players = nil
    self.other_players = {}  -- Store other players

    self.other_battlers = nil
    self.other_battlers = {}  -- Store other players
    -- Register player with username and actor
    local registerMessage = {
        command = "register",
        uuid = Game:getFlag("GCSN_UUID"), -- server will generate this if it's nil
        username = self.name,
        actor = Game.party[1].actor.id or "kris"  -- Include actor
    }
    sendToServer(client, registerMessage)
end

function Lib:update()
    local currentTime = love.timer.getTime()
    if currentTime - lastHearbeatTime >= HEARTBEAT_INTERVAL then
        lastHearbeatTime = currentTime
        sendToServer(client, {
            command = "heartbeat",
            gamestate = Game.state
        })
    end
end

function Lib:unload()
    sendToServer(client, {command = "disconnect"})
    client:close()
end

function Lib:updateBattle(batl, ...)

    local currentTime = love.timer.getTime()

    local data = self:receiveFromServer(client)
    if data then
        if data.command == "battle_update" then
            for _, playerData in ipairs(data.players) do
                if playerData.uuid ~= self.uuid then
                    local other_battler = self.other_battlers[playerData.uuid]

                    if other_battler then
                        other_battler.name = playerData.username

                        if playerData.health then other_battler.health = playerData.health end
                        if other_battler.actor.id ~= playerData.actor then
                            local success, result = pcall(Other_Battler, playerData.actor, 0, 0, 0)
                            if success then
                                other_battler:setActor(playerData.actor)
                            else
                                other_battler:setActor("dummy")
                            end
                        end
                        if other_battler.sprite.sprite_options[1] ~= playerData.sprite then
                            other_battler:setSprite(playerData.sprite)
                        end

                        if playerData.location then
                            other_battler.x = playerData.location[1]
                            other_battler.y = playerData.location[2]
                        end

                        if playerData.party_number then
                            other_battler.party_number = playerData.party_number
                        end

                    else
                        local otherplr
                        local success, result = pcall(Other_Battler, playerData.actor, 200, 200, playerData.username, playerData.uuid)
                        if success then
                            otherplr = result
                        else
                            otherplr = Other_Battler("dummy", 200, 200, playerData.username, playerData.uuid)
                        end

                        if playerData.encounter == batl.encounter.id then
                            -- Create a new player if it doesn't exist while making sure It's on the right map
                            other_battler = otherplr
                            other_battler.layer = -100
                            other_battler.encounterID = playerData.encounter
                            Game.battle:addChild(other_battler)
                            self.other_battlers[playerData.uuid] = other_battler

                            if playerData.location then
                                other_battler.x = playerData.location[1]
                                other_battler.y = playerData.location[2]
                            end
                            if playerData.party_number then
                                other_battler.party_number = playerData.party_number
                                self:playerBattleLocation()
                            end
                        end
                    end
                end
                
            end
        elseif data.command == "enemy_update" then
            if data.subCommand == "mercy" then
                local enemy = Game.battle.enemies[data.index]
                if enemy then
                    enemy:addMercy(data.amount)
                else
                    print("no enemys?")
                end
            end
        elseif data.command == "heal" then
            if data.amount < 0 then
                batl.party[1]:hurt(-data.amount)
            else
                batl.party[1]:heal(data.amount)
            end
        elseif data.command == "remove_battlers" then
            for _, uuid in ipairs(data.battlers) do
                if self.other_battlers[uuid] then
                    self.other_battlers[uuid].fadingOut = true
                    self.other_battlers[uuid] = nil
                    self:playerBattleLocation()
                end
            end
        elseif data.command == "chat" then
            local sender = data.uuid == self.uuid and Game.world.player or self.other_players[data.uuid]
            self.chat_box:push({sender = data.username, content = data.message})
        elseif data.command == "set_party_number" then
            batl.party[1].party_number = data.party_number
            self:playerBattleLocation()
        end
    end

    -- Throttle player position update packets
    if currentTime - lastUpdateTime >= THROTTLE_INTERVAL and batl then
        local player = batl.party[1]
        local updateMessage = {
            command = "battle",
            subCommand = "update",
            actor = player.actor.id,
            username = self.name,
            sprite = player.sprite.sprite_options[1],
            encounter = batl.encounter.id,
            health = {player.chara.health, player.chara.stats.health},
            location = {player.x, player.y}
        }
        sendToServer(client, updateMessage)
        lastUpdateTime = currentTime
    end

    -- Throttle current players list packets
    if currentTime - lastPlayerListTime >= THROTTLE_INTERVAL then
        local playersList = {}
        for uuid, _ in pairs(self.other_battlers) do
            table.insert(playersList, uuid)
        end

        local currentPlayersMessage = {
            command = "battle",
            subCommand = "inParty",
            username = self.name,
            players = playersList
        }
        sendToServer(client, currentPlayersMessage)
        lastPlayerListTime = currentTime
    end

end

function Lib:updateWorld(...)
    local player = Game.world.player
    -- Update the current time
    local currentTime = love.timer.getTime()

    -- Receive data from the server (if any)
    local data = self:receiveFromServer(client)
    if data then
        -- print("[NET] "..Utils.dump(data))
        if data.command == "register" then
            self.uuid = data.uuid
            Game:setFlag("GCSN_UUID", self.uuid)
        elseif data.command == "update" then
            for _, playerData in ipairs(data.players) do
                if playerData.uuid ~= self.uuid then
                    local other_player = self.other_players[playerData.uuid]

                    if other_player then
                        -- Smoothly interpolate position update
                        other_player.targetX = playerData.x
                        other_player.targetY = playerData.y
                        other_player.name = playerData.username

                        if other_player.actor.id ~= playerData.actor then
                            
                            local success, result = pcall(Other_Player, playerData.actor, 0, 0, 0)
                            if success then
                                other_player:setActor(playerData.actor)
                            else
                                other_player:setActor("dummy")
                            end
                        end
                        
                        if other_player.sprite.sprite_options[1] ~= playerData.sprite then
                            other_player:setSprite(playerData.sprite)
                        end


                    else
                        local otherplr
                        local success, result = pcall(Other_Player, playerData.actor, playerData.x, playerData.y, playerData.username, playerData.uuid)
                        if success then
                            otherplr = result
                        else
                            otherplr = Other_Player("dummy", playerData.x, playerData.y, playerData.username, playerData.uuid)
                        end

                        if playerData.map == (Mod.info.id..":"..Game.world.map.id) then
                            -- Create a new player if it doesn't exist while making sure It's on the right map
                            other_player = otherplr
                            other_player.layer = Game.world.map.object_layer
                            other_player.mapID = playerData.map
                            Game.world:addChild(other_player)
                            self.other_players[playerData.uuid] = other_player
                        end
                    end
                end
            end
        elseif data.command == "chat" then
            local sender = data.uuid == self.uuid and Game.world.player or self.other_players[data.uuid]
            self.chat_box:push({sender = data.username, content = data.message})
            if sender == nil then return end
            local bubble = ChatBubble(sender.actor, data.message)
            bubble:setScale(0.25)
            sender:addChild(bubble)
        elseif data.command == "RemoveOtherPlayersFromMap" then
            for _, uuid in ipairs(data.players) do
                if self.other_players[uuid] then
                    self.other_players[uuid].fadingOut = true
                    self.other_players[uuid] = nil
                end
            end
        else
            Kristal.Console:warn("Unhandled command: " .. (data.command or "<nil>"))
            Kristal.Console:log(Utils.dump(data))
        end
    end

    -- Throttle player position update packets
    if currentTime - lastUpdateTime >= THROTTLE_INTERVAL then
        local updateMessage = {
            command = "world",
            subCommand = "update",
            username = self.name,
            x = player.x,
            y = player.y,
            map = (Mod.info.id..":"..Game.world.map.id) or "null",
            actor = player.actor.id,
            sprite = player.sprite.sprite_options[1]
        }
        sendToServer(client, updateMessage)
        lastUpdateTime = currentTime
    end

    -- Throttle current players list packets
    if currentTime - lastPlayerListTime >= THROTTLE_INTERVAL then
        local playersList = {}
        for uuid, _ in pairs(self.other_players) do
            table.insert(playersList, uuid)
        end

        local currentPlayersMessage = {
            command = "world",
            subCommand = "inMap",
            username = self.name,
            players = playersList
        }
        sendToServer(client, currentPlayersMessage)
        lastPlayerListTime = currentTime
    end
end

function Lib:onKeyPressed(key, is_repeat)
    if (
        not is_repeat
        and Input.is("gcsn_chat", key)
        and not self.chat_box.is_open
    ) then
        self.chat_box:open()
    end
end

function Lib:getPartyPosition(index, party_size)
    local x, y = 0, 0
    local battler = Game.battle.party[1]

    if party_size <= 3 then 
        if party_size == 1 then
            x = 80
            y = 140
        elseif party_size == 2 then
            x = 80
            y = 100 + (80 * (index - 1))
        elseif party_size == 3 then
            x = 80
            y = 50 + (80 * (index - 1))
        end
    
        local ox, oy = battler.chara:getBattleOffset()
        x = x + (battler.actor:getWidth()/2 + ox) * 2
        y = y + (battler.actor:getHeight()  + oy) * 2
        return x, y
    end
    
    local column = 0
    local reset = 0
    local middle = 0
    local classic = (Kristal.getLibConfig("moreparty", "classic_mode") and 3 or 4)
    if #Game.battle.party > classic then
        if index <= classic then
            column = 80
        else
            reset = classic
            middle = (classic * 2 - party_size) * ((Kristal.getLibConfig("moreparty", "classic_mode") and 40 or 35))
        end
    end
    x = 80 + column
    y = (((not Kristal.getLibConfig("moreparty", "classic_mode") and party_size <= 4) and 120 or 50) / classic) + ((SCREEN_HEIGHT * 0.5) / classic) * (index - 1 - reset) + middle

    local ox, oy = battler.chara:getBattleOffset()
    x = x + (battler.actor:getWidth()/2 + ox) * 2
    y = y + (battler.actor:getHeight()  + oy) * 2
    return x, y
end

function Lib:playerBattleLocation()
    if not Game.battle then return end

    local battle = Game.battle
    local player = Game.battle.party[1]

    local numbers = {}
    table.insert(numbers, player.party_number)
    for i, party in pairs(self.other_battlers) do
        table.insert(numbers, party.party_number)
    end
    table.sort(numbers)

    local index
    for i, num in ipairs(numbers) do
        if num == player.party_number then
            index = i
            break
        end
    end
    player.x, player.y = self:getPartyPosition(index, #numbers)

end

Utils.hook(EnemyBattler, "addMercy", function (orig, enemy, amount, ...)
    local amount = amount
    local index = Utils.getIndex(Game.battle.enemies_index, self)
    local msg = {
        command = "battle",
        subCommand = "enemy",
        subSubC = "dmercy",
        index = index,
        mercy = amount 
    }
    sendToServer(client, msg)

    orig(enemy, amount, ...)
end)

return Lib
