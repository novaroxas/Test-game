-- Execute the real server script against a deterministic Roblox service double.
-- Studio is still needed to check engine behavior and visual presentation.
local cases, now, timers, created, sent = 0, 0, {}, {}, {}
local function check(condition, message)
    assert(condition, message)
    cases = cases + 1
end
local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback) table.insert(callbacks, callback) end,
        Fire = function(_, ...) for _, callback in ipairs(callbacks) do callback(...) end end,
    }
end
local function advance(seconds)
    local target = now + seconds
    while true do
        table.sort(timers, function(a, b) return a.time < b.time end)
        if not timers[1] or timers[1].time > target then break end
        local timer = table.remove(timers, 1)
        now = timer.time
        timer.callback()
    end
    now = target
end
local function node(name)
    return { Name = name, WaitForChild = function(_, child) return node(child) end }
end
local players = { list = {}, PlayerAdded = signal(), PlayerRemoving = signal() }
function players:GetPlayers() return self.list end
local arenaState = { placed = 0, released = 0, destroyed = 0, reveals = 0 }
local arena = {
    init = function() return {} end,
    create = function()
        return { center = {}, model = { Destroy = function() arenaState.destroyed = arenaState.destroyed + 1 end } }
    end,
    place = function() arenaState.placed = arenaState.placed + 1 end,
    bot = function() return {} end,
    release = function() arenaState.released = arenaState.released + 1 end,
    bindLobby = function(_, callback) arenaState.lobbyAction = callback end,
    clearProps = function() end,
    reveal = function() arenaState.reveals = arenaState.reveals + 1 end,
}
local config = dofile("src/shared/Config.lua")
local rules = dofile("src/shared/Rules.lua")
game = { GetService = function(_, name)
    if name == "Players" then return players end
    if name == "ReplicatedStorage" then return node(name) end
    error("Unexpected service " .. name)
end }
script = { Parent = node("ServerScriptService") }
workspace = { GetServerTimeNow = function() return now end }
Random = { new = function() return { NextInteger = function() return 1 end, NextNumber = function() return 1 end } end }
task = { delay = function(seconds, callback) table.insert(timers, { time = now + seconds, callback = callback }) end }
Instance = { new = function(class)
    local instance = { ClassName = class }
    if class == "RemoteEvent" then
        instance.OnServerEvent = signal()
        instance.FireClient = function(_, player, packet)
            sent[player] = sent[player] or {}
            table.insert(sent[player], packet)
        end
    end
    table.insert(created, instance)
    return instance
end }
require = function(module)
    if module.Name == "Config" then return config end
    if module.Name == "Rules" then return rules end
    if module.Name == "Arena" then return arena end
    error("Unexpected require")
end
os.clock = function() return now end
dofile("src/server/Game.server.lua")
local remote
for _, instance in ipairs(created) do if instance.Name == "Action" then remote = instance end end
check(remote ~= nil, "action remote registered")
local function player(name)
    local p = { DisplayName = name, Parent = players, CharacterRemoving = signal() }
    p.Character = {
        FindFirstChild = function() return {} end,
        FindFirstChildOfClass = function() return { Health = 100 } end,
    }
    table.insert(players.list, p)
    players.PlayerAdded:Fire(p)
    return p
end
local function latest(p) return sent[p][#sent[p]] end
local function fire(p, kind, payload)
    advance(0.2)
    remote.OnServerEvent:Fire(p, kind, payload)
end
local function choose(p, choice, overrides)
    local packet = latest(p)
    local payload = { choice = choice, matchId = packet.matchId, round = packet.round }
    for key, value in pairs(overrides or {}) do payload[key] = value end
    fire(p, "Choice", payload)
end
local a, b = player("Alpha"), player("Beta")
fire(a, "Sync")
check(latest(a).phase == "lobby", "initial sync")
local initialCount = #sent[a]
remote.OnServerEvent:Fire(a, "Queue")
check(#sent[a] == initialCount, "rate limit rejects immediate repeated requests")
fire(a, "Queue")
check(latest(a).phase == "queued", "first player waits")
fire(b, "Queue")
check(latest(a).phase == "choosing" and latest(b).phase == "choosing", "second joins duel")
check(latest(a).seat == 1 and latest(b).seat == 2, "consistent arena seats")
check(latest(a).myScore == 0 and latest(a).opponentScore == 0, "fresh scores")
local before = #sent[a]
fire(a, "Choice", "Rock")
check(#sent[a] == before, "malformed payload rejected")
choose(a, "Lizard")
check(#sent[a] == before, "invalid choice rejected")
choose(a, "Rock", { round = 99 })
check(#sent[a] == before, "stale round rejected")
choose(a, "Rock", { matchId = 99 })
check(#sent[a] == before, "wrong match rejected")
choose(a, "Rock")
check(latest(a).myReady and latest(b).opponentReady, "choice locks")
check(latest(b).myChoice == nil and latest(b).opponentChoice == nil, "choice remains private")
before = #sent[a]
choose(a, "Paper")
check(#sent[a] == before, "cannot change locked choice")
choose(b, "Scissors")
check(latest(a).phase == "reveal" and latest(a).result == "win", "winning reveal")
check(latest(a).myChoice == "Rock" and latest(b).opponentChoice == "Rock", "reveal publishes choices")
check(type(latest(a).revealAt) == "number" and latest(a).revealAt == latest(b).revealAt, "shared reveal clock")
check(latest(a).myScore == 1 and latest(b).opponentScore == 1, "perspective scores")
advance(config.RevealSeconds)
check(latest(a).round == 2 and not latest(a).myReady, "next round resets lock")
check(latest(a).revealAt == nil, "reveal timestamp resets")
choose(a, "Paper")
choose(b, "Paper")
check(latest(a).result == "tie" and latest(a).myScore == 1, "ties do not add points")
advance(config.RevealSeconds)
choose(a, "Scissors")
advance(config.ChoiceSeconds)
check(latest(a).result == "win" and latest(a).myScore == 2, "timeout awards opponent a point")
check(latest(b).myChoice == "Time out", "timeout is explicit")
advance(config.RevealSeconds)
choose(a, "Paper")
choose(b, "Rock")
advance(config.RevealSeconds)
check(latest(a).phase == "finished" and latest(a).result == "win", "first to three finishes")
check(latest(b).result == "lose", "opponent sees match loss")
advance(config.MatchEndSeconds)
check(latest(a).phase == "lobby" and latest(b).phase == "lobby", "match returns players to lobby")
check(arenaState.released == 2 and arenaState.destroyed == 1, "match releases rigs and removes arena")
fire(a, "Practice")
check(latest(a).opponent == config.BotName, "practice opponent")
choose(a, "Paper")
advance(1)
check(latest(a).result == "win" and latest(a).opponentChoice == "Rock", "bot makes independent choice")
advance(config.RevealSeconds)
check(latest(a).round == 2, "old timeout did not interfere with new match")
fire(a, "Leave")
check(latest(a).phase == "finished", "leave ends active match")
advance(config.MatchEndSeconds)
fire(a, "Queue")
fire(a, "Leave")
check(latest(a).phase == "lobby", "queue cancellation")
fire(b, "Queue")
check(latest(b).phase == "queued", "cancelled player is not matched")
fire(a, "Queue")
players.PlayerRemoving:Fire(a)
a.Parent = nil
check(latest(b).phase == "finished" and latest(b).result == "win", "disconnect grants remaining player victory")
advance(config.MatchEndSeconds)
check(latest(b).phase == "lobby", "disconnect cleanup")
fire(b, "Practice")
b.CharacterRemoving:Fire()
check(latest(b).phase == "finished", "character reset terminates duel")
advance(config.MatchEndSeconds)
local c, d = player("Gamma"), player("Delta")
fire(c, "Queue")
fire(d, "Queue")
advance(config.ChoiceSeconds)
check(latest(c).result == "tie" and latest(c).myScore == 0, "double timeout ties")
advance(config.RevealSeconds + config.ChoiceSeconds)
advance(config.RevealSeconds + config.ChoiceSeconds)
advance(config.RevealSeconds)
check(latest(c).phase == "finished" and latest(c).result == "tie", "idle match ends after three timeouts")
advance(config.MatchEndSeconds)
check(latest(c).phase == "lobby" and latest(d).phase == "lobby", "idle arena cleaned up")
advance(0.2)
arenaState.lobbyAction(c, "Queue")
check(latest(c).phase == "queued", "physical matchmaking kiosk queues player")
c.CharacterRemoving:Fire()
check(latest(c).phase == "lobby", "queued reset clears waiting UI")
advance(0.2)
arenaState.lobbyAction(d, "Practice")
check(latest(d).phase == "choosing" and latest(d).opponent == config.BotName, "physical practice kiosk starts match")
local e = player("Loading")
e.Character = nil
fire(e, "Practice")
check(latest(e).phase == "lobby" and latest(e).message ~= nil, "loading character fails safely")
print("Server: " .. cases .. " assertions passed")
