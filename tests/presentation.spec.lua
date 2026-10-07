-- Test the real presentation module with transform and instance doubles.
local cases, now, available = 0, 0, false
local function check(condition, message)
    assert(condition, message)
    cases = cases + 1
end
math.clamp = function(n, low, high) return math.min(high, math.max(low, n)) end
local frame = {}
frame.__index = frame
local fields = { "x", "y", "z", "rx", "ry", "rz" }
local function transform(x, y, z, rx, ry, rz)
    return setmetatable({ x = x or 0, y = y or 0, z = z or 0, rx = rx or 0, ry = ry or 0, rz = rz or 0 }, frame)
end
function frame.__mul(a, b)
    local result = transform()
    for _, field in ipairs(fields) do result[field] = a[field] + b[field] end
    return result
end
function frame:Lerp(target, alpha)
    local result = transform()
    for _, field in ipairs(fields) do result[field] = self[field] + (target[field] - self[field]) * alpha end
    return result
end
CFrame = { new = transform, Angles = function(x, y, z) return transform(0, 0, 0, x, y, z) end }
local function actor(x, disabled)
    local root = { Parent = true, Anchored = true, CFrame = transform(x, 3, 0) }
    local joint = { Name = "RightShoulder", Parent = true, C0 = transform(), IsA = function(_, class) return class == "Motor6D" end }
    local animate = { Parent = true, Disabled = disabled or false, IsA = function(_, class) return class == "LocalScript" end }
    local rig = {
        FindFirstChild = function(_, name) return name == "Animate" and animate or root end,
        GetDescendants = function() return { joint } end,
    }
    return { root = root, joint = joint, animate = animate, rig = rig, base = root.CFrame }
end
local function prop()
    local part = { Transparency = 1, IsA = function(_, class) return class == "BasePart" end }
    local label = { Enabled = false, IsA = function(_, class) return class == "BillboardGui" end }
    local model = { Parent = true, PrimaryPart = part, scale = 1, cf = transform(0, 5.5, 2), round = 1 }
    function model:GetAttribute() return self.round end
    function model:GetPivot() return self.cf end
    function model:GetDescendants() return { part, label } end
    function model:ScaleTo(scale) self.scale = scale end
    function model:PivotTo(cf) self.cf = cf end
    return { model = model, part = part, label = label }
end
local actors, props = { actor(-6), actor(6) }, { prop(), prop() }
local arena = { FindFirstChild = function(_, name)
    local index = tonumber(name:sub(-1))
    if name:sub(1, 7) == "Fighter" then return { Value = actors[index].rig } end
    if name:sub(1, 4) == "Pose" then return { Value = actors[index].base } end
    if name:sub(1, 6) == "Choice" then return props[index].model end
end }
local world = { FindFirstChild = function() return arena end }
workspace = {
    GetServerTimeNow = function() return now end,
    FindFirstChild = function() return available and world or nil end,
}
local Presentation = dofile("src/shared/Presentation.lua")
local config = dofile("src/shared/Config.lua")
local animation = Presentation.new(config.RevealWindup)
local function packet(phase, round, result, revealAt)
    return { phase = phase, round = round or 1, matchId = 1, seat = 1, result = result, revealAt = revealAt }
end
animation:set(packet("choosing"))
animation:step(1 / 60)
check(next(animation.actors) == nil, "state can arrive before arena replication")
available = true
animation:step(1 / 60)
check(animation.actors[1] ~= nil and animation.actors[2] ~= nil, "late replicated fighter references resolve")
check(actors[1].animate.Disabled and actors[2].animate.Disabled, "default animation paused during presentation")
check(math.abs(actors[1].root.CFrame.y - 3) < 0.1, "idle motion stays near base pose")
local originalActor = animation.actors[1]
animation:set(packet("choosing"))
check(animation.actors[1] == originalActor, "readiness messages preserve animation state")
animation:set(packet("reveal", 1, "win", 0))
now = config.RevealWindup / 2
animation:step(1 / 60)
check(props[1].part.Transparency == 1 and not props[1].label.Enabled, "props stay hidden during hand beats")
check(props[1].model.scale > 0, "model scale is never zero")
now = config.RevealWindup + 0.12
animation:step(1 / 60)
check(props[1].model.scale > 0 and props[1].model.scale < 1, "props ease into view")
check(props[1].part.Transparency == 0 and not props[1].label.Enabled, "choice label waits for prop entrance")
now = config.RevealWindup + 0.6
animation:step(1 / 60)
check(props[1].model.scale == 1 and props[1].label.Enabled, "revealed prop reaches full scale")
check(actors[1].joint.C0.rx < 0, "winner reacts with arm pose")
animation:set(packet("choosing", 2))
check(next(animation.props) == nil, "new round drops old prop references")
check(animation.actors[1] == originalActor, "new rounds retain original rest pose")
animation:set(packet("reveal", 2, "win", 0))
animation:step(1 / 60)
check(next(animation.props) == nil, "late previous-round props are ignored")
for _, choice in ipairs(props) do choice.model.round = 2 end
now = 5
animation:step(1 / 60)
check(props[1].model.scale == 1 and props[1].label.Enabled, "late reveal packet catches up to shared clock")
actors[1].root.Anchored = false
actors[1].root.CFrame = transform(0, 4, 22)
animation:set({ phase = "lobby" })
check(not actors[1].animate.Disabled, "walking animation restored in lobby")
check(actors[1].joint.C0.rx == 0, "shoulder rest pose restored")
check(actors[1].root.CFrame.z == 22, "cleanup preserves server lobby teleport")
check(next(animation.actors) == nil and animation.packet == nil, "cleanup releases presentation references")

local function sample(fps)
    now = 2
    actors, props = { actor(-6, true), actor(6) }, { prop(), prop() }
    local visual = Presentation.new(config.RevealWindup)
    visual:set(packet("choosing"))
    for _ = 1, fps do visual:step(1 / fps) end
    local y = actors[1].root.CFrame.y
    visual:stop()
    check(actors[1].animate.Disabled, "preserve pre-existing disabled animation")
    return y
end
check(math.abs(sample(30) - sample(120)) < 0.000001, "smoothing converges equally at 30 and 120 fps")
print("Presentation: " .. cases .. " assertions passed")
