local Lighting = game:GetService("Lighting")
local Arena = {}
local blue = Color3.fromRGB(66, 200, 255)
local pink = Color3.fromRGB(255, 101, 174)
local dark = Color3.fromRGB(20, 24, 45)

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
    p.Anchored, p.CanCollide = true, false
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function sign(parent, text, cf, width, color)
    local p = part(parent, "Sign", Vector3.new(width, 3, 0.2), cf, dark)
    local gui = Instance.new("SurfaceGui")
    gui.Face, gui.PixelsPerStud = Enum.NormalId.Back, 60
    gui.Parent = p
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.Text, label.TextColor3 = text, color
    label.Font, label.TextScaled = Enum.Font.GothamBlack, true
    label.Parent = gui
end

local function solid(parent, name, size, cf, color, material)
    local p = part(parent, name, size, cf, color, material)
    p.CanCollide = true
    return p
end

local function disk(parent, name, position, diameter, height, color, material)
    local p = part(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), color, material)
    p.Shape = Enum.PartType.Cylinder
    return p
end

local function planter(parent, x, z)
    solid(parent, "Planter", Vector3.new(7, 1.7, 7), CFrame.new(x, 0.85, z), Color3.fromRGB(49, 59, 78))
    part(parent, "Soil", Vector3.new(6.5, 0.2, 6.5), CFrame.new(x, 1.75, z), Color3.fromRGB(37, 47, 47))
    part(parent, "Trunk", Vector3.new(0.8, 4.4, 0.8), CFrame.new(x, 3.8, z), Color3.fromRGB(126, 103, 85), Enum.Material.Wood)
    for i, offset in ipairs({ Vector3.new(-1.4, 0, 0), Vector3.new(1.4, 0.3, 0), Vector3.new(0, 1.6, 0) }) do
        local crown = part(parent, "Foliage", Vector3.new(5, 4.5, 5), CFrame.new(Vector3.new(x, 6, z) + offset), i == 3 and Color3.fromRGB(101, 162, 139) or Color3.fromRGB(63, 120, 108))
        crown.Shape = Enum.PartType.Ball
    end
end

local function bench(parent, x, z, yaw)
    local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
    solid(parent, "BenchSeat", Vector3.new(7, 0.4, 2), cf * CFrame.new(0, 1.7, 0), Color3.fromRGB(164, 133, 113), Enum.Material.Wood)
    solid(parent, "BenchBack", Vector3.new(7, 1.6, 0.3), cf * CFrame.new(0, 2.5, -0.9), Color3.fromRGB(164, 133, 113), Enum.Material.Wood)
    for _, xOffset in ipairs({ -2.7, 2.7 }) do
        solid(parent, "BenchLeg", Vector3.new(0.4, 1.6, 1.8), cf * CFrame.new(xOffset, 0.8, 0), dark)
    end
    local seat = Instance.new("Seat")
    seat.Size, seat.CFrame = Vector3.new(3, 0.2, 1.6), cf * CFrame.new(0, 2, 0)
    seat.Anchored, seat.Transparency, seat.Parent = true, 1, parent
end

local function kiosk(parent, x, title, subtitle, color, actionName)
    local cf = CFrame.new(x, 0, -17)
    local plinth = disk(parent, "KioskPad", cf.Position + Vector3.new(0, 0.2, 0), 11, 0.4, color, Enum.Material.Neon)
    plinth.CanCollide = true
    solid(parent, "Kiosk", Vector3.new(7, 4.2, 2), cf * CFrame.new(0, 2.3, -1), dark)
    part(parent, "KioskTrim", Vector3.new(7.2, 0.15, 2.2), cf * CFrame.new(0, 4.5, -1), color, Enum.Material.Neon)
    sign(parent, title, cf * CFrame.new(0, 7.5, -1), 15, color)
    sign(parent, subtitle, cf * CFrame.new(0, 4.8, -0.7), 13, Color3.fromRGB(223, 230, 243))
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name, prompt.ActionText, prompt.ObjectText = actionName, title, subtitle
    prompt.KeyboardKeyCode, prompt.MaxActivationDistance = Enum.KeyCode.E, 10
    prompt.HoldDuration, prompt.RequiresLineOfSight = 0, false
    prompt.Parent = plinth
end

function Arena.init()
    Lighting.ClockTime, Lighting.Brightness = 17.7, 2
    Lighting.Ambient = Color3.fromRGB(122, 126, 157)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 109, 139)
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity, bloom.Size, bloom.Threshold = 0.18, 20, 1.2
    bloom.Parent = Lighting
    local world = Instance.new("Folder")
    world.Name, world.Parent = "HandClashWorld", workspace
    local lobby = Instance.new("Model")
    lobby.Name, lobby.Parent = "Lobby", world
    solid(lobby, "Courtyard", Vector3.new(84, 2, 68), CFrame.new(0, -1, 0), Color3.fromRGB(41, 48, 66), Enum.Material.Concrete)
    for _, x in ipairs({ -41, 41 }) do
        solid(lobby, "SideRail", Vector3.new(1, 3.5, 68), CFrame.new(x, 1.75, 0), dark)
        part(lobby, "RailLight", Vector3.new(0.15, 0.15, 65), CFrame.new(x, 3.6, 0), blue, Enum.Material.Neon)
    end
    solid(lobby, "RearWall", Vector3.new(84, 14, 1), CFrame.new(0, 7, -33), dark)
    solid(lobby, "FrontRail", Vector3.new(84, 3.5, 1), CFrame.new(0, 1.75, 33), dark)
    for z = -25, 25, 5 do
        part(lobby, "WalkwayTile", Vector3.new(12, 0.08, 4.75), CFrame.new(0, 0.05, z), Color3.fromRGB(63, 72, 92), Enum.Material.Concrete)
    end
    for x = -30, 30, 5 do
        part(lobby, "CrosswalkTile", Vector3.new(4.75, 0.07, 10), CFrame.new(x, 0.06, -3), Color3.fromRGB(63, 72, 92), Enum.Material.Concrete)
    end
    disk(lobby, "CenterLight", Vector3.new(0, 0.14, -3), 18, 0.1, blue, Enum.Material.Neon)
    local center = disk(lobby, "CenterPlatform", Vector3.new(0, 0.25, -3), 17, 0.3, dark)
    center.CanCollide = true
    solid(lobby, "SculptureBase", Vector3.new(4, 0.8, 4), CFrame.new(0, 0.8, -3), Color3.fromRGB(77, 89, 110))
    local sculpture = part(lobby, "ClashSculpture", Vector3.new(3.4, 3.4, 3.4), CFrame.new(0, 3.2, -3) * CFrame.Angles(math.rad(35), math.rad(45), math.rad(20)), Color3.fromRGB(161, 216, 226), Enum.Material.Glass)
    sculpture.Transparency = 0.15
    part(lobby, "SculptureAccent", Vector3.new(4, 0.12, 4), CFrame.new(0, 3.2, -3) * CFrame.Angles(math.rad(35), math.rad(45), math.rad(20)), pink, Enum.Material.Neon)
    for _, x in ipairs({ -32, 32 }) do
        for _, z in ipairs({ -25, 23 }) do planter(lobby, x, z) end
        bench(lobby, x * 0.78, 12, x < 0 and 90 or -90)
    end
    for _, x in ipairs({ -15, 15 }) do
        for _, z in ipairs({ -27, 25 }) do
            solid(lobby, "LampPost", Vector3.new(0.45, 7, 0.45), CFrame.new(x, 3.5, z), dark)
            local lamp = part(lobby, "Lamp", Vector3.new(1.4, 0.7, 1.4), CFrame.new(x, 7, z), Color3.fromRGB(255, 228, 179), Enum.Material.Neon)
            local light = Instance.new("PointLight")
            light.Color, light.Brightness, light.Range, light.Parent = lamp.Color, 1.5, 18, lamp
        end
    end
    local spawn = Instance.new("SpawnLocation")
    spawn.Size, spawn.CFrame = Vector3.new(8, 0.2, 6), CFrame.new(0, 0.2, 22)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
    spawn.Transparency, spawn.Parent = 1, lobby
    sign(lobby, "Hand Clash", CFrame.new(0, 10, -32.3), 29, Color3.fromRGB(237, 243, 255))
    sign(lobby, "Meet. Choose. Play.", CFrame.new(0, 6.5, -32.3), 24, blue)
    kiosk(lobby, -20, "Practice", "Warm up with ROBO", blue, "Practice")
    kiosk(lobby, 20, "Find a match", "Play another player", pink, "Queue")
    sign(lobby, "The lounge", CFrame.new(-27, 6, 19) * CFrame.Angles(0, math.rad(35), 0), 12, Color3.fromRGB(222, 224, 235))
    return world
end

function Arena.bindLobby(world, callback)
    for _, item in ipairs(world:GetDescendants()) do
        if item:IsA("ProximityPrompt") then
            item.Triggered:Connect(function(player) callback(player, item.Name) end)
        end
    end
end

function Arena.create(world, id)
    local model = Instance.new("Model")
    model.Name, model.Parent = "Duel_" .. id, world
    local center = Vector3.new(id * 120, 0, 0)
    local floor = part(model, "Stage", Vector3.new(32, 2, 22), CFrame.new(center - Vector3.new(0, 1, 0)), dark)
    floor.CanCollide = true
    for _, z in ipairs({ -11, 11 }) do
        part(model, "Glow", Vector3.new(32, 0.15, 0.25), CFrame.new(center + Vector3.new(0, 0.1, z)), blue, Enum.Material.Neon)
    end
    local spots = {}
    for i, x in ipairs({ -6, 6 }) do
        local p = center + Vector3.new(x, 3, 0)
        spots[i] = CFrame.lookAt(p, center + Vector3.new(-x, 3, 0))
        local pad = part(model, "PlayerPad", Vector3.new(6, 0.25, 6), CFrame.new(center + Vector3.new(x, 0.1, 0)), i == 1 and blue or pink, Enum.Material.Neon)
        pad.CanCollide = true
    end
    sign(model, "Make your move", CFrame.new(center + Vector3.new(0, 7, -10)), 27, Color3.fromRGB(240, 244, 255))
    return { model = model, center = center, spots = spots, props = {}, rigs = {}, shoulders = {}, movement = {} }
end

function Arena.bot(arena)
    local model = Instance.new("Model")
    model.Name, model.Parent = "ROBO", arena.model
    local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), arena.spots[2], pink)
    root.Transparency = 1
    local pieces = {
        { "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0), pink },
        { "Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0), Color3.fromRGB(240, 245, 255) },
        { "Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0), pink },
        { "Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0), pink },
        { "Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0), dark },
        { "Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0), dark },
    }
    for _, info in ipairs(pieces) do
        local p = part(model, info[1], info[2], root.CFrame * CFrame.new(info[3]), info[4])
        p.Anchored = false
        local joint = Instance.new("Motor6D")
        joint.Name = info[1] == "Right Arm" and "RightShoulder" or (info[1] == "Left Arm" and "LeftShoulder" or info[1])
        joint.Part0, joint.Part1, joint.C0, joint.Parent = root, p, CFrame.new(info[3]), root
    end
    model.PrimaryPart = root
    local face = Instance.new("BillboardGui")
    face.Size, face.StudsOffset = UDim2.fromOffset(120, 30), Vector3.new(0, 0, -0.6)
    face.Adornee, face.Parent = model.Head, model.Head
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.Text, label.TextColor3 = "•  ‿  •", dark
    label.TextScaled, label.Font = true, Enum.Font.GothamBold
    label.Parent = face
    return model
end

function Arena.place(arena, rig, index)
    local root = rig:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local seat = humanoid.SeatPart
        local weld = seat and seat:FindFirstChild("SeatWeld")
        if weld and weld.Part1 and weld.Part1:IsDescendantOf(rig) then weld:Destroy() end
        humanoid.Sit = false
    end
    root.Anchored = true
    rig:PivotTo(arena.spots[index])
    arena.rigs[index] = rig
    local reference = Instance.new("ObjectValue")
    reference.Name, reference.Value, reference.Parent = "Fighter" .. index, rig, arena.model
    local pose = Instance.new("CFrameValue")
    pose.Name, pose.Value, pose.Parent = "Pose" .. index, root.CFrame, arena.model
    if humanoid then
        arena.movement[index] = { speed = humanoid.WalkSpeed, jumpPower = humanoid.JumpPower, jumpHeight = humanoid.JumpHeight }
        humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = 0, 0, 0
        humanoid.AutoRotate = false
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do track:Stop(0.1) end
    end
    for _, joint in ipairs(rig:GetDescendants()) do
        if joint:IsA("Motor6D") and (joint.Name == "RightShoulder" or joint.Name == "Right Shoulder") then
            arena.shoulders[index] = { joint = joint, original = joint.C0 }
            break
        end
    end
    return true
end

function Arena.clearProps(arena)
    for _, p in ipairs(arena.props) do p:Destroy() end
    arena.props = {}
end

function Arena.reveal(arena, choices, round)
    Arena.clearProps(arena)
    for i = 1, 2 do
        local choice = choices[i]
        local color = i == 1 and blue or pink
        local cf = CFrame.new(arena.center + Vector3.new(i == 1 and -3 or 3, 5.5, 2))
        local model = Instance.new("Model")
        model.Name, model.Parent = "Choice" .. i, arena.model
        model:SetAttribute("Round", round)
        local core
        if choice == "Rock" then
            core = part(model, "Rock", Vector3.new(2, 2, 2), cf, color, Enum.Material.Slate)
            core.Shape = Enum.PartType.Ball
        elseif choice == "Paper" then
            core = part(model, "Paper", Vector3.new(2, 2.6, 0.15), cf * CFrame.Angles(0, 0, math.rad(-12)), Color3.fromRGB(245, 247, 255))
            for line = 1, 3 do
                part(model, "Ink", Vector3.new(1.3, 0.07, 0.04), core.CFrame * CFrame.new(0, 0.7 - line * 0.4, 0.1), color)
            end
        elseif choice == "Scissors" then
            core = part(model, "Blade", Vector3.new(0.25, 2.8, 0.25), cf * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(220, 230, 245), Enum.Material.Metal)
            part(model, "Blade", Vector3.new(0.25, 2.8, 0.25), cf * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(220, 230, 245), Enum.Material.Metal)
            for _, x in ipairs({ -0.65, 0.65 }) do
                local handle = part(model, "Handle", Vector3.new(0.7, 0.7, 0.35), cf * CFrame.new(x, -1.4, 0), color, Enum.Material.Neon)
                handle.Shape = Enum.PartType.Ball
            end
        else
            core = part(model, "NoChoice", Vector3.new(1, 1, 1), cf, dark)
        end
        local gui = Instance.new("BillboardGui")
        gui.Size, gui.StudsOffset, gui.AlwaysOnTop = UDim2.fromOffset(160, 32), Vector3.new(0, 1.7, 0), true
        gui.Enabled = false
        gui.Adornee, gui.Parent = core, core
        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
        label.Text, label.TextColor3 = choice or "No move", color
        label.Font, label.TextScaled = Enum.Font.GothamBlack, true
        label.Parent = gui
        model.PrimaryPart = core
        for _, piece in ipairs(model:GetDescendants()) do
            if piece:IsA("BasePart") then piece.Transparency = 1 end
        end
        table.insert(arena.props, model)
    end
end

function Arena.release(arena, index)
    local shoulder = arena.shoulders[index]
    if shoulder and shoulder.joint.Parent then shoulder.joint.C0 = shoulder.original end
    local rig = arena.rigs[index]
    local root = rig and rig:FindFirstChild("HumanoidRootPart")
    if root then
        root.Anchored = false
        rig:PivotTo(CFrame.new(index == 1 and -4 or 4, 4, 22))
    end
    local humanoid = rig and rig:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = true
        local movement = arena.movement[index]
        if movement then
            humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = movement.speed, movement.jumpPower, movement.jumpHeight
        end
    end
end

return Arena
