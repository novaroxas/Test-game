local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("HandClash")
local Config = require(shared:WaitForChild("Config"))
local remotes = shared:WaitForChild("Remotes")
local action = remotes:WaitForChild("Action")
local state = remotes:WaitForChild("State")

local colors = {
    bg = Color3.fromRGB(12, 16, 31), panel = Color3.fromRGB(26, 32, 54),
    blue = Color3.fromRGB(66, 200, 255), pink = Color3.fromRGB(255, 101, 174),
    white = Color3.fromRGB(244, 247, 255), muted = Color3.fromRGB(161, 174, 203),
    gold = Color3.fromRGB(255, 210, 105), green = Color3.fromRGB(112, 244, 174),
}
local function create(class, props, parent)
    local instance = Instance.new(class)
    for key, value in pairs(props) do instance[key] = value end
    instance.Parent = parent
    return instance
end
local function round(frame, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 16) }, frame)
end
local function stroke(frame, color, transparency)
    return create("UIStroke", { Color = color, Thickness = 1.5, Transparency = transparency or 0.6 }, frame)
end
local function text(parent, value, size, position, fontSize, color, font)
    local label = create("TextLabel", {
        BackgroundTransparency = 1, Size = size, Position = position,
        Text = value, TextColor3 = color or colors.white,
        Font = font or Enum.Font.GothamBold, TextScaled = true, TextWrapped = true,
        ZIndex = parent.ZIndex + 1,
    }, parent)
    create("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = fontSize or 24 }, label)
    return label
end
local function tween(object, seconds, properties, style)
    local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end

local gui = create("ScreenGui", { Name = "HandClashUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local shell = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
local backdrop = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.bg, BorderSizePixel = 0 }, shell)
create("UIGradient", { Color = ColorSequence.new(colors.bg, Color3.fromRGB(35, 30, 66)), Rotation = 30 }, backdrop)
for i = 1, 16 do
    local dot = create("Frame", {
        Size = UDim2.fromOffset(i % 3 == 0 and 6 or 3, i % 3 == 0 and 6 or 3),
        Position = UDim2.fromScale(((i * 37) % 97) / 100, ((i * 23) % 93) / 100),
        BackgroundColor3 = i % 2 == 0 and colors.blue or colors.pink,
        BackgroundTransparency = 0.45, BorderSizePixel = 0,
    }, backdrop)
    round(dot, 10)
end

local lobby = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.9, 0.88), BackgroundColor3 = colors.panel, ZIndex = 2,
}, shell)
create("UISizeConstraint", { MaxSize = Vector2.new(680, 490) }, lobby)
round(lobby, 24)
stroke(lobby, colors.blue, 0.7)
text(lobby, "THE SMALLEST DUEL. THE BIGGEST ENERGY.", UDim2.fromScale(0.9, 0.06), UDim2.fromScale(0.05, 0.06), 13, colors.blue)
text(lobby, Config.Title, UDim2.fromScale(0.9, 0.16), UDim2.fromScale(0.05, 0.13), 54, colors.white, Enum.Font.GothamBlack)
text(lobby, "ROCK  •  PAPER  •  SCISSORS", UDim2.fromScale(0.9, 0.07), UDim2.fromScale(0.05, 0.3), 20, colors.pink)
text(lobby, "Two rivals. One choice. First to " .. Config.PointsToWin .. " points wins.", UDim2.fromScale(0.88, 0.08), UDim2.fromScale(0.06, 0.38), 16, colors.muted, Enum.Font.Gotham)

local current = { phase = "lobby" }
local controls
task.spawn(function()
    local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
    if module then
        controls = require(module):GetControls()
        if current.phase == "choosing" or current.phase == "reveal" or current.phase == "finished" then controls:Disable() end
    end
end)
local selected, lastSent = nil, -math.huge
local function request(kind, payload)
    local now = os.clock()
    if now - lastSent < 0.15 then return end
    lastSent = now
    action:FireServer(kind, payload)
end
local function button(parent, title, size, position, color, callback)
    local b = create("TextButton", {
        Size = size, Position = position, BackgroundColor3 = color,
        Text = title, Font = Enum.Font.GothamBlack, TextColor3 = colors.bg,
        TextScaled = true, AutoButtonColor = false, ZIndex = parent.ZIndex + 1,
    }, parent)
    round(b, 14)
    create("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 22 }, b)
    local scale = create("UIScale", { Scale = 1 }, b)
    b.MouseEnter:Connect(function() if b.Active then tween(scale, 0.12, { Scale = 1.025 }) end end)
    b.MouseLeave:Connect(function() tween(scale, 0.12, { Scale = 1 }) end)
    b.Activated:Connect(function()
        if not b.Active then return end
        tween(scale, 0.08, { Scale = 0.96 })
        task.delay(0.08, function() if b.Parent then tween(scale, 0.16, { Scale = 1 }) end end)
        callback()
    end)
    return b
end
local practice = button(lobby, "PRACTICE  /  VS ROBO", UDim2.fromScale(0.88, 0.15), UDim2.fromScale(0.06, 0.51), colors.blue, function() request("Practice") end)
local versus = button(lobby, "FIND A PLAYER", UDim2.fromScale(0.88, 0.15), UDim2.fromScale(0.06, 0.69), colors.pink, function() request("Queue") end)
local lobbyNote = text(lobby, "Rock beats scissors. Scissors beats paper. Paper beats rock.", UDim2.fromScale(0.88, 0.07), UDim2.fromScale(0.06, 0.89), 13, colors.muted, Enum.Font.Gotham)

local queuePanel = create("Frame", {
    Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.88, 0.58), BackgroundColor3 = colors.panel, ZIndex = 3,
}, shell)
create("UISizeConstraint", { MaxSize = Vector2.new(560, 320) }, queuePanel)
round(queuePanel, 24)
stroke(queuePanel, colors.pink)
local queueTitle = text(queuePanel, "FINDING YOUR RIVAL", UDim2.fromScale(0.9, 0.22), UDim2.fromScale(0.05, 0.1), 30)
text(queuePanel, "Keep this window open. A duel starts when another player joins the queue.", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.35), 17, colors.muted, Enum.Font.Gotham)
button(queuePanel, "CANCEL", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.68), colors.pink, function() request("Leave") end)

local duel = create("Frame", { Visible = false, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, shell)
local scoreboard = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12),
    Size = UDim2.new(0.94, 0, 0, 80), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.08,
}, duel)
create("UISizeConstraint", { MaxSize = Vector2.new(760, 80) }, scoreboard)
round(scoreboard, 20)
stroke(scoreboard, colors.white, 0.86)
local myName = text(scoreboard, "YOU", UDim2.fromScale(0.3, 0.34), UDim2.fromScale(0.03, 0.12), 16, colors.blue)
local theirName = text(scoreboard, "RIVAL", UDim2.fromScale(0.3, 0.34), UDim2.fromScale(0.67, 0.12), 16, colors.pink)
local myScore = text(scoreboard, "0", UDim2.fromScale(0.3, 0.45), UDim2.fromScale(0.03, 0.48), 30, colors.white, Enum.Font.GothamBlack)
local theirScore = text(scoreboard, "0", UDim2.fromScale(0.3, 0.45), UDim2.fromScale(0.67, 0.48), 30, colors.white, Enum.Font.GothamBlack)
local roundText = text(scoreboard, "ROUND 1", UDim2.fromScale(0.3, 0.35), UDim2.fromScale(0.35, 0.16), 16, colors.white)
text(scoreboard, "FIRST TO " .. Config.PointsToWin, UDim2.fromScale(0.3, 0.25), UDim2.fromScale(0.35, 0.58), 11, colors.muted)

local timerTrack = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 102),
    Size = UDim2.new(0.62, 0, 0, 6), BackgroundColor3 = colors.panel, ClipsDescendants = true,
}, duel)
round(timerTrack, 5)
local timerFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.blue, BorderSizePixel = 0 }, timerTrack)
round(timerFill, 5)
local timerLabel = text(duel, "7s", UDim2.new(0.2, 0, 0, 22), UDim2.new(0.4, 0, 0, 114), 15, colors.white)

local choicesPanel = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12),
    Size = UDim2.new(0.94, 0, 0, 174), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.07,
}, duel)
create("UISizeConstraint", { MaxSize = Vector2.new(760, 174) }, choicesPanel)
round(choicesPanel, 20)
stroke(choicesPanel, colors.white, 0.87)
local status = text(choicesPanel, "MAKE YOUR MOVE", UDim2.fromScale(0.94, 0.16), UDim2.fromScale(0.03, 0.04), 20)
local hint = text(choicesPanel, "Your choice stays secret until the reveal.", UDim2.fromScale(0.94, 0.12), UDim2.fromScale(0.03, 0.21), 12, colors.muted, Enum.Font.Gotham)
local choiceButtons = {}
local choiceLabels = {}
local keys = { Rock = "1", Paper = "2", Scissors = "3" }
local function choose(choice)
    if current.phase ~= "choosing" or current.myReady then return end
    selected = choice
    request("Choice", { choice = choice, round = current.round, matchId = current.matchId })
end
for i, choice in ipairs(Config.Choices) do
    local b = button(choicesPanel, "", UDim2.fromScale(0.29, 0.4), UDim2.fromScale(0.04 + (i - 1) * 0.315, 0.37), i == 1 and colors.blue or (i == 2 and colors.white or colors.pink), function() choose(choice) end)
    choiceLabels[choice] = text(b, choice:upper() .. "  [" .. keys[choice] .. "]", UDim2.fromScale(0.92, 0.33), UDim2.fromScale(0.04, 0.59), 16, colors.bg)
    local icon = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.29),
        Size = UDim2.fromScale(0.8, 0.46), BackgroundTransparency = 1,
    }, b)
    create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, icon)
    local function shape(size, position, rotation)
        return create("Frame", { Size = size, Position = position, Rotation = rotation or 0, BackgroundColor3 = colors.bg, BorderSizePixel = 0 }, icon)
    end
    if choice == "Rock" then
        local rock = shape(UDim2.fromScale(0.85, 0.75), UDim2.fromScale(0.075, 0.16), -12)
        round(rock, 8)
        for x = 0, 2 do
            local glint = create("Frame", { Size = UDim2.fromScale(0.04, 0.3), Position = UDim2.fromScale(0.3 + x * 0.2, 0.2), BackgroundColor3 = colors.blue, BorderSizePixel = 0 }, rock)
            round(glint, 2)
        end
    elseif choice == "Paper" then
        local card = shape(UDim2.fromScale(0.7, 0.95), UDim2.fromScale(0.15, 0.02), 8)
        round(card, 3)
        for y = 1, 3 do
            create("Frame", { Size = UDim2.fromScale(0.6, 0.05), Position = UDim2.fromScale(0.2, 0.1 + y * 0.2), BackgroundColor3 = colors.white, BorderSizePixel = 0 }, card)
        end
    else
        for _, rotation in ipairs({ -28, 28 }) do
            local blade = shape(UDim2.fromScale(0.11, 0.88), UDim2.fromScale(0.44, 0.02), rotation)
            round(blade, 3)
        end
        for _, x in ipairs({ 0.02, 0.58 }) do
            local handle = shape(UDim2.fromScale(0.39, 0.39), UDim2.fromScale(x, 0.61))
            round(handle, 50)
            local hole = create("Frame", { Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.25, 0.25), BackgroundColor3 = colors.pink, BorderSizePixel = 0 }, handle)
            round(hole, 50)
        end
    end
    choiceButtons[choice] = b
end
local leave = button(choicesPanel, "LEAVE", UDim2.fromScale(0.19, 0.13), UDim2.fromScale(0.77, 0.83), colors.panel, function() request("Leave") end)
leave.TextColor3 = colors.muted
text(choicesPanel, "CLICK, TAP, OR PRESS 1 / 2 / 3", UDim2.fromScale(0.69, 0.13), UDim2.fromScale(0.04, 0.83), 10, colors.muted, Enum.Font.Gotham)

local resultCard = create("Frame", {
    Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45),
    Size = UDim2.fromScale(0.75, 0.26), BackgroundColor3 = colors.bg, BackgroundTransparency = 0.1, ZIndex = 8,
}, duel)
create("UISizeConstraint", { MaxSize = Vector2.new(500, 150) }, resultCard)
round(resultCard, 22)
local resultStroke = stroke(resultCard, colors.gold, 0.2)
local resultTitle = text(resultCard, "YOU WIN!", UDim2.fromScale(0.9, 0.42), UDim2.fromScale(0.05, 0.15), 36, colors.gold, Enum.Font.GothamBlack)
local resultDetail = text(resultCard, "Rock beats scissors", UDim2.fromScale(0.9, 0.26), UDim2.fromScale(0.05, 0.62), 17, colors.white)
local resultScale = create("UIScale", { Scale = 1 }, resultCard)

local cameraTween, cameraCenter
local function setCamera(center)
    if cameraCenter == center then return end
    cameraCenter = center
    local camera = workspace.CurrentCamera
    if cameraTween then cameraTween:Cancel() end
    if center then
        camera.CameraType = Enum.CameraType.Scriptable
        local target = CFrame.lookAt(center + Vector3.new(0, 10, 24), center + Vector3.new(0, 3, 0))
        -- Set immediately on the first match to avoid traveling through other arenas.
        camera.CFrame = target
        cameraTween = tween(camera, 0.7, { CFrame = CFrame.lookAt(center + Vector3.new(0, 8, 21), center + Vector3.new(0, 3, 0)), FieldOfView = 55 })
    else
        camera.CameraType, camera.FieldOfView = Enum.CameraType.Custom, 70
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then camera.CameraSubject = humanoid end
    end
end

local effects = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 15 }, shell)
local function confetti()
    for i = 1, 34 do
        local chip = create("Frame", {
            Size = UDim2.fromOffset(7 + i % 4, 12), Position = UDim2.fromScale(0.5, 0.4),
            BackgroundColor3 = ({ colors.blue, colors.pink, colors.gold })[(i % 3) + 1],
            Rotation = i * 19, BorderSizePixel = 0,
        }, effects)
        tween(chip, 1.3 + (i % 4) * 0.1, {
            Position = UDim2.fromScale((i % 12) / 11, 1.15), Rotation = i * 53,
            BackgroundTransparency = 1,
        })
        task.delay(1.8, function() chip:Destroy() end)
    end
end

local function showResult(packet)
    local win = packet.result == "win"
    local tie = packet.result == "tie"
    local color = tie and colors.blue or (win and colors.gold or colors.pink)
    resultTitle.TextColor3, resultStroke.Color = color, color
    resultTitle.Text = packet.phase == "finished" and (tie and "MATCH DRAW!" or (win and "MATCH WON!" or "GOOD GAME!")) or (tie and "IT'S A TIE!" or (win and "YOU WIN!" or "RIVAL WINS!"))
    resultDetail.Text = packet.phase == "finished" and (packet.reason .. " Returning to lobby…") or (packet.myChoice .. "  vs  " .. packet.opponentChoice)
    resultCard.Visible, resultScale.Scale = true, 0.8
    tween(resultScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
    if win then confetti() end
end

state.OnClientEvent:Connect(function(packet)
    local newRound = packet.matchId ~= current.matchId or packet.round ~= current.round
    if newRound then selected = nil end
    current = packet
    local inDuel = packet.phase == "choosing" or packet.phase == "reveal" or packet.phase == "finished"
    lobby.Visible = packet.phase == "lobby"
    queuePanel.Visible = packet.phase == "queued"
    backdrop.Visible = not inDuel
    duel.Visible = inDuel
    if not inDuel then
        if controls then controls:Enable() end
        setCamera(nil)
        lobbyNote.Text = packet.message or "Rock beats scissors. Scissors beats paper. Paper beats rock."
        return
    end
    if controls then controls:Disable() end
    setCamera(packet.camera)
    myName.Text, theirName.Text = "YOU · " .. packet.me, packet.opponent
    local myX, theirX = packet.seat == 2 and 0.67 or 0.03, packet.seat == 2 and 0.03 or 0.67
    myName.Position, myScore.Position = UDim2.fromScale(myX, 0.12), UDim2.fromScale(myX, 0.48)
    theirName.Position, theirScore.Position = UDim2.fromScale(theirX, 0.12), UDim2.fromScale(theirX, 0.48)
    myName.TextColor3 = packet.seat == 2 and colors.pink or colors.blue
    theirName.TextColor3 = packet.seat == 2 and colors.blue or colors.pink
    myScore.Text, theirScore.Text = tostring(packet.myScore), tostring(packet.opponentScore)
    roundText.Text = "ROUND " .. packet.round
    timerTrack.Visible, timerLabel.Visible = packet.phase == "choosing", packet.phase == "choosing"
    resultCard.Visible = packet.phase == "reveal" or packet.phase == "finished"
    for choice, b in pairs(choiceButtons) do
        b.Active = packet.phase == "choosing" and not packet.myReady
        b.BackgroundTransparency = b.Active and 0 or 0.55
        choiceLabels[choice].Text = choice:upper() .. ((packet.myReady and selected == choice) and "  ✓" or "  [" .. keys[choice] .. "]")
    end
    if packet.phase == "choosing" then
        status.Text = packet.myReady and "CHOICE LOCKED" or "MAKE YOUR MOVE"
        status.TextColor3 = packet.myReady and colors.green or colors.white
        hint.Text = packet.opponentReady and "Your rival is ready. The reveal is coming…" or (packet.myReady and "Waiting for your rival…" or "Your choice stays secret until the reveal.")
    else
        status.Text = packet.phase == "finished" and "THANKS FOR PLAYING" or "THE REVEAL"
        status.TextColor3 = colors.white
        hint.Text = packet.phase == "finished" and "Another duel is one click away." or "Next round starts in a moment."
        showResult(packet)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    local choice = ({ [Enum.KeyCode.One] = "Rock", [Enum.KeyCode.Two] = "Paper", [Enum.KeyCode.Three] = "Scissors" })[input.KeyCode]
    if choice then choose(choice) end
end)

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
    elapsed = elapsed + dt
    if current.phase == "choosing" and current.deadline then
        local remaining = math.max(0, current.deadline - workspace:GetServerTimeNow())
        timerLabel.Text = string.format("%.1fs", remaining)
        timerFill.Size = UDim2.fromScale(math.clamp(remaining / Config.ChoiceSeconds, 0, 1), 1)
        timerFill.BackgroundColor3 = remaining < 2 and colors.pink or colors.blue
    elseif current.phase == "queued" then
        queueTitle.Text = "FINDING YOUR RIVAL" .. string.rep(".", math.floor(elapsed * 2) % 4)
    end
end)

-- Fit the controls around the arena on short mobile displays.
local function resize()
    local height = workspace.CurrentCamera.ViewportSize.Y
    local compact = height < 500
    scoreboard.Size = UDim2.new(0.94, 0, 0, compact and 62 or 80)
    timerTrack.Position = UDim2.new(0.5, 0, 0, compact and 82 or 102)
    timerLabel.Position = UDim2.new(0.4, 0, 0, compact and 92 or 114)
    choicesPanel.Size = UDim2.new(0.94, 0, 0, compact and 134 or 174)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
request("Sync")
