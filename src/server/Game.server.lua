local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("HandClash")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Arena = require(script.Parent:WaitForChild("Arena"))

local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "Remotes", Shared
local action = Instance.new("RemoteEvent")
action.Name, action.Parent = "Action", remotes
local state = Instance.new("RemoteEvent")
state.Name, state.Parent = "State", remotes

local world = Arena.init()
local random = Random.new()
local queue, queued, active, lastRequest = {}, {}, {}, {}
local serial = 0
local startRound, reveal, finish

local function send(player, packet)
    if player and player.Parent == Players then state:FireClient(player, packet) end
end

local function removeQueued(player)
    queued[player] = nil
    for i = #queue, 1, -1 do
        if queue[i] == player then table.remove(queue, i) end
    end
end

local function indexOf(match, player)
    return match.players[1] == player and 1 or 2
end

local function broadcast(match, phase, extra)
    for i = 1, 2 do
        local player = match.players[i]
        if player then
            local opponent = match.players[3 - i]
            local packet = {
                phase = phase, matchId = match.id, round = match.round, seat = i,
                me = player.DisplayName, opponent = opponent and opponent.DisplayName or Config.BotName,
                myScore = match.scores[i], opponentScore = match.scores[3 - i],
                goal = Config.PointsToWin, deadline = match.deadline, revealAt = match.revealAt,
                myReady = match.choices[i] ~= nil, opponentReady = match.choices[3 - i] ~= nil,
                camera = match.arena.center,
            }
            if extra then for key, value in pairs(extra(i)) do packet[key] = value end end
            send(player, packet)
        end
    end
end

local function cleanup(match)
    if not match.alive then return end
    match.alive = false
    for i = 1, 2 do
        local player = match.players[i]
        if player and active[player] == match then
            active[player] = nil
            Arena.release(match.arena, i)
            send(player, { phase = "lobby" })
        end
    end
    match.arena.model:Destroy()
end

finish = function(match, winner, reason)
    if not match.alive or match.phase == "finished" then return end
    match.phase = "finished"
    broadcast(match, "finished", function(i)
        return { result = winner == 0 and "tie" or (winner == i and "win" or "lose"), reason = reason or "Match complete!" }
    end)
    task.delay(Config.MatchEndSeconds, function() cleanup(match) end)
end

reveal = function(match)
    if not match.alive or match.phase ~= "choosing" then return end
    match.phase = "reveal"
    match.revealAt = workspace:GetServerTimeNow()
    local winner = Rules.winner(match.choices[1], match.choices[2])
    match.idleRounds = (not match.choices[1] and not match.choices[2]) and (match.idleRounds + 1) or 0
    if winner ~= 0 then match.scores[winner] = match.scores[winner] + 1 end
    Arena.reveal(match.arena, match.choices, match.round)
    broadcast(match, "reveal", function(i)
        return {
            myChoice = match.choices[i] or "Time out",
            opponentChoice = match.choices[3 - i] or "Time out",
            result = winner == 0 and "tie" or (winner == i and "win" or "lose"),
        }
    end)
    task.delay(Config.RevealSeconds, function()
        if not match.alive or match.phase ~= "reveal" then return end
        local matchWinner = Rules.matchWinner(match.scores, Config.PointsToWin)
        if matchWinner then
            finish(match, matchWinner)
        elseif match.idleRounds >= 3 then
            finish(match, 0, "No moves for three rounds.")
        else
            startRound(match)
        end
    end)
end

startRound = function(match)
    if not match.alive then return end
    match.round, match.phase, match.choices = match.round + 1, "choosing", {}
    match.revealAt = nil
    match.deadline = workspace:GetServerTimeNow() + Config.ChoiceSeconds
    Arena.clearProps(match.arena)
    broadcast(match, "choosing")
    local round = match.round
    if not match.players[2] then
        -- Choose independently before the player submits; never inspect their choice.
        local botChoice = Config.Choices[random:NextInteger(1, #Config.Choices)]
        task.delay(random:NextNumber(0.8, 1.8), function()
            if not match.alive or match.phase ~= "choosing" or match.round ~= round then return end
            match.choices[2] = botChoice
            if match.choices[1] then reveal(match) else broadcast(match, "choosing") end
        end)
    end
    task.delay(Config.ChoiceSeconds, function()
        if match.alive and match.round == round and match.phase == "choosing" then reveal(match) end
    end)
end

local function characterReady(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return character and character:FindFirstChild("HumanoidRootPart") and humanoid and humanoid.Health > 0
end

local function startMatch(first, second)
    if not characterReady(first) or (second and not characterReady(second)) then
        send(first, { phase = "lobby", message = "Your character is loading. Try again in a moment." })
        send(second, { phase = "lobby", message = "A character is loading. Please queue again." })
        return
    end
    serial = serial + 1
    local match = {
        id = serial, players = { first, second }, scores = { 0, 0 }, choices = {},
        round = 0, idleRounds = 0, alive = true, phase = "starting", arena = Arena.create(world, serial),
    }
    active[first] = match
    if second then active[second] = match end
    Arena.place(match.arena, first.Character, 1)
    Arena.place(match.arena, second and second.Character or Arena.bot(match.arena), 2)
    startRound(match)
end

local function handleAction(player, kind, payload)
    if type(kind) ~= "string" then return end
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < 0.1 then return end
    lastRequest[player] = now
    local match = active[player]
    if kind == "Sync" then
        if match then
            -- Sync is used once on UI startup; do not resend a reveal without its result.
            if match.phase == "choosing" then broadcast(match, "choosing") end
        else send(player, { phase = queued[player] and "queued" or "lobby" }) end
    elseif kind == "Choice" then
        if not match or match.phase ~= "choosing" or type(payload) ~= "table" then return end
        if payload.matchId ~= match.id or payload.round ~= match.round then return end
        if workspace:GetServerTimeNow() >= match.deadline or not Rules.isChoice(payload.choice) then return end
        local index = indexOf(match, player)
        if match.choices[index] then return end
        match.choices[index] = payload.choice
        if match.choices[1] and match.choices[2] then reveal(match) else broadcast(match, "choosing") end
    elseif kind == "Leave" then
        removeQueued(player)
        if match then
            finish(match, 3 - indexOf(match, player), "A player left the arena.")
        else send(player, { phase = "lobby" }) end
    elseif (kind == "Practice" or kind == "Queue") and not match then
        removeQueued(player)
        if kind == "Practice" then startMatch(player, nil); return end
        if not characterReady(player) then
            send(player, { phase = "lobby", message = "Wait for your character to load, then try again." })
            return
        end
        while #queue > 0 do
            local opponent = table.remove(queue, 1)
            local waiting = queued[opponent]
            queued[opponent] = nil
            if waiting and opponent.Parent == Players and not active[opponent] then
                startMatch(opponent, player)
                return
            end
        end
        queued[player] = true
        table.insert(queue, player)
        send(player, { phase = "queued" })
    end
end
action.OnServerEvent:Connect(handleAction)
Arena.bindLobby(world, handleAction)

local function abandon(player)
    removeQueued(player)
    local match = active[player]
    if match and match.alive then
        finish(match, 3 - indexOf(match, player), "Duel ended after a disconnect or character reset.")
    else
        send(player, { phase = "lobby" })
    end
end

local function bindPlayer(player)
    player.CharacterRemoving:Connect(function() abandon(player) end)
end
Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
    abandon(player)
    lastRequest[player] = nil
end)
