local TweenService = game:GetService("TweenService")
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

function Arena.init()
    Lighting.ClockTime, Lighting.Brightness = 0, 2
    Lighting.Ambient = Color3.fromRGB(120, 125, 160)
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 90, 125)
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity, bloom.Size, bloom.Threshold = 0.35, 24, 1
    bloom.Parent = Lighting
    local world = Instance.new("Folder")
    world.Name, world.Parent = "HandClashWorld", workspace
    local floor = part(world, "Lobby", Vector3.new(70, 2, 70), CFrame.new(0, -1, 0), dark)
    floor.CanCollide = true
    local spawn = Instance.new("SpawnLocation")
    spawn.Size, spawn.CFrame = Vector3.new(8, 1, 8), CFrame.new(0, 0.5, 15)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
    spawn.Color, spawn.Material = blue, Enum.Material.Neon
    spawn.Parent = world
    sign(world, "HAND CLASH", CFrame.new(0, 9, -15), 30, blue)
    sign(world, "ROCK  /  PAPER  /  SCISSORS", CFrame.new(0, 5, -15), 30, pink)
    return world
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
    sign(model, "CHOOSE. REVEAL. WIN.", CFrame.new(center + Vector3.new(0, 7, -10)), 27, Color3.fromRGB(240, 244, 255))
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
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = root, p, root
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
    root.Anchored = true
    rig:PivotTo(arena.spots[index])
    arena.rigs[index] = rig
    local humanoid = rig:FindFirstChildOfClass("Humanoid")
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

function Arena.animate(arena, index, winner)
    local rig = arena.rigs[index]
    local root = rig and rig:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local base = arena.spots[index]
    TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 2, true), {
        CFrame = base * CFrame.new(0, winner and 1.4 or 0.4, 0) * CFrame.Angles(0, 0, math.rad(winner and -8 or 5)),
    }):Play()
    local shoulder = arena.shoulders[index]
    if shoulder then
        TweenService:Create(shoulder.joint, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 2, true), {
            C0 = shoulder.original * CFrame.Angles(math.rad(-70), 0, math.rad(20)),
        }):Play()
    end
end

function Arena.reveal(arena, choices, winner)
    Arena.clearProps(arena)
    for i = 1, 2 do
        local choice = choices[i]
        local color = i == 1 and blue or pink
        local cf = CFrame.new(arena.center + Vector3.new(i == 1 and -3 or 3, 5.5, 2))
        local model = Instance.new("Model")
        model.Name, model.Parent = "Choice", arena.model
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
        gui.Size, gui.StudsOffset, gui.AlwaysOnTop = UDim2.fromOffset(160, 38), Vector3.new(0, 2.2, 0), true
        gui.Adornee, gui.Parent = core, core
        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
        label.Text, label.TextColor3 = choice or "TIME OUT", color
        label.Font, label.TextScaled = Enum.Font.GothamBlack, true
        label.Parent = gui
        table.insert(arena.props, model)
        Arena.animate(arena, i, winner == i)
    end
end

function Arena.release(arena, index)
    local shoulder = arena.shoulders[index]
    if shoulder and shoulder.joint.Parent then shoulder.joint.C0 = shoulder.original end
    local rig = arena.rigs[index]
    local root = rig and rig:FindFirstChild("HumanoidRootPart")
    if root then
        root.Anchored = false
        rig:PivotTo(CFrame.new(index == 1 and -4 or 4, 4, 15))
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
