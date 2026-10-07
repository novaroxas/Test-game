local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("HandClash")
local Config = require(shared:WaitForChild("Config"))
local Presentation = require(shared:WaitForChild("Presentation"))
local presentation = Presentation.new(Config.RevealWindup)
local remotes = shared:WaitForChild("Remotes")
local action = remotes:WaitForChild("Action")
local state = remotes:WaitForChild("State")

local colors = {
    bg = Color3.fromRGB(16, 22, 35), panel = Color3.fromRGB(27, 35, 53),
    blue = Color3.fromRGB(118, 212, 240), pink = Color3.fromRGB(244, 158, 191),
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
        ZIndex = parent.ZIndex + 1, BorderSizePixel = 0,
    }, parent)
    create("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = fontSize or 24 }, label)
    return label
end
local runningTweens = setmetatable({}, { __mode = "k" })
local function tween(object, seconds, properties, style)
    if runningTweens[object] then runningTweens[object]:Cancel() end
    local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    runningTweens[object] = t
    t:Play()
    return t
end

local gui = create("ScreenGui", { Name = "HandClashUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local shell = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
local shown, homes = {}, {}
local function show(panel, visible)
    if shown[panel] == visible then return end
    shown[panel] = visible
    homes[panel] = homes[panel] or panel.Position
    local home = homes[panel]
    if visible then
        panel.Visible, panel.GroupTransparency = true, 1
        panel.Position = home + UDim2.fromOffset(0, 10)
        tween(panel, 0.3, { GroupTransparency = 0, Position = home }, Enum.EasingStyle.Quart)
    else
        local fade = tween(panel, 0.2, { GroupTransparency = 1, Position = home + UDim2.fromOffset(0, 8) })
        fade.Completed:Connect(function()
            if not shown[panel] then panel.Visible = false end
        end)
    end
end

local lobby = create("CanvasGroup", {
    Visible = false, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.fromOffset(360, 370), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.12, ZIndex = 3,
}, shell)
round(lobby, 24)
stroke(lobby, colors.white, 0.88)
text(lobby, "Welcome to the lounge", UDim2.fromScale(0.77, 0.06), UDim2.fromScale(0.06, 0.07), 13, colors.blue)
text(lobby, Config.Title, UDim2.fromScale(0.88, 0.15), UDim2.fromScale(0.06, 0.16), 38, colors.white, Enum.Font.GothamBlack)
text(lobby, "A little luck. A little strategy.", UDim2.fromScale(0.88, 0.07), UDim2.fromScale(0.06, 0.32), 16, colors.pink)
text(lobby, "First to " .. Config.PointsToWin .. " points. Ready when you are.", UDim2.fromScale(0.88, 0.07), UDim2.fromScale(0.06, 0.41), 14, colors.muted, Enum.Font.Gotham)

local current = { phase = "lobby" }
local menuOpen = true
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
    if now - lastSent < 0.15 then return false end
    lastSent = now
    action:FireServer(kind, payload)
    return true
end
local function button(parent, title, size, position, color, callback)
    local b = create("TextButton", {
        Size = size, Position = position, BackgroundColor3 = color,
        Text = title, Font = Enum.Font.GothamBold, TextColor3 = colors.bg,
        TextScaled = true, AutoButtonColor = false, ZIndex = parent.ZIndex + 1, BorderSizePixel = 0,
    }, parent)
    round(b, 14)
    create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(213, 221, 233)), Rotation = 90 }, b)
    create("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 18 }, b)
    local scale = create("UIScale", { Scale = 1 }, b)
    b.MouseEnter:Connect(function() if b.Active then tween(scale, 0.18, { Scale = 1.02 }, Enum.EasingStyle.Sine) end end)
    b.MouseLeave:Connect(function() tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Sine) end)
    b.Activated:Connect(function()
        if not b.Active then return end
        tween(scale, 0.09, { Scale = 0.97 })
        task.delay(0.09, function() if b.Parent then tween(scale, 0.24, { Scale = 1 }, Enum.EasingStyle.Quart) end end)
        callback()
    end)
    return b
end
button(lobby, "Practice with ROBO", UDim2.fromScale(0.88, 0.15), UDim2.fromScale(0.06, 0.52), colors.blue, function() request("Practice") end)
button(lobby, "Find a match", UDim2.fromScale(0.88, 0.15), UDim2.fromScale(0.06, 0.7), colors.pink, function() request("Queue") end)
local lobbyNote = text(lobby, "Rock beats scissors. Scissors beats paper. Paper beats rock.", UDim2.fromScale(0.88, 0.07), UDim2.fromScale(0.06, 0.89), 13, colors.muted, Enum.Font.Gotham)
button(lobby, "×", UDim2.fromScale(0.08, 0.08), UDim2.fromScale(0.86, 0.05), colors.panel, function()
    menuOpen = false
    show(lobby, false)
end).TextColor3 = colors.muted

local lobbyHud = create("CanvasGroup", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, shell)
local brand = create("Frame", { Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(230, 60), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.16, BorderSizePixel = 0 }, lobbyHud)
round(brand, 18)
text(brand, Config.Title, UDim2.fromScale(0.88, 0.48), UDim2.fromScale(0.06, 0.09), 24)
text(brand, "Rock. Paper. Scissors.", UDim2.fromScale(0.88, 0.26), UDim2.fromScale(0.06, 0.63), 12, colors.muted, Enum.Font.Gotham)
local menuToggle = button(lobbyHud, "Play", UDim2.new(0, 90, 0, 44), UDim2.new(1, -106, 0, 18), colors.blue, function()
    if current.phase == "queued" then return end
    menuOpen = not menuOpen
    show(lobby, menuOpen)
end)
local exploreHint = text(lobbyHud, "Explore the lounge, or visit a kiosk to play.", UDim2.new(0.66, 0, 0, 24), UDim2.new(0.17, 0, 1, -32), 13, colors.white, Enum.Font.Gotham)

local queuePanel = create("CanvasGroup", {
    Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 88),
    Size = UDim2.new(0.92, 0, 0, 96), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.1, ZIndex = 3,
}, shell)
create("UISizeConstraint", { MaxSize = Vector2.new(580, 96) }, queuePanel)
round(queuePanel, 18)
stroke(queuePanel, colors.pink, 0.7)
local queueTitle = text(queuePanel, "Finding an opponent", UDim2.fromScale(0.7, 0.25), UDim2.fromScale(0.04, 0.12), 18)
text(queuePanel, "You're in line. Explore the lounge while you wait.", UDim2.fromScale(0.7, 0.4), UDim2.fromScale(0.04, 0.44), 13, colors.muted, Enum.Font.Gotham)
button(queuePanel, "Cancel", UDim2.fromScale(0.18, 0.58), UDim2.fromScale(0.78, 0.2), colors.pink, function() request("Leave") end)

local duel = create("Frame", { Visible = false, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, shell)
local scoreboard = create("CanvasGroup", {
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
local roundText = text(scoreboard, "Round 1", UDim2.fromScale(0.3, 0.35), UDim2.fromScale(0.35, 0.16), 16, colors.white)
text(scoreboard, "First to " .. Config.PointsToWin, UDim2.fromScale(0.3, 0.25), UDim2.fromScale(0.35, 0.58), 11, colors.muted)
local scoreScales = { create("UIScale", { Scale = 1 }, myScore), create("UIScale", { Scale = 1 }, theirScore) }

local timerTrack = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 102),
    Size = UDim2.new(0.62, 0, 0, 6), BackgroundColor3 = colors.panel, ClipsDescendants = true,
}, duel)
round(timerTrack, 5)
local timerFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.blue, BorderSizePixel = 0 }, timerTrack)
round(timerFill, 5)
local timerLabel = text(duel, "7s", UDim2.new(0.2, 0, 0, 22), UDim2.new(0.4, 0, 0, 114), 15, colors.white)

local choicesPanel = create("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12),
    Size = UDim2.new(0.94, 0, 0, 174), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.07,
}, duel)
create("UISizeConstraint", { MaxSize = Vector2.new(760, 174) }, choicesPanel)
round(choicesPanel, 20)
stroke(choicesPanel, colors.white, 0.87)
local status = text(choicesPanel, "Choose your move", UDim2.fromScale(0.94, 0.16), UDim2.fromScale(0.03, 0.04), 20)
local hint = text(choicesPanel, "Your choice stays secret until the reveal.", UDim2.fromScale(0.94, 0.12), UDim2.fromScale(0.03, 0.21), 12, colors.muted, Enum.Font.Gotham)
local choiceButtons = {}
local choiceLabels = {}
local keys = { Rock = "1", Paper = "2", Scissors = "3" }
local function choose(choice)
    if current.phase ~= "choosing" or current.myReady then return end
    if request("Choice", { choice = choice, round = current.round, matchId = current.matchId }) then selected = choice end
end
for i, choice in ipairs(Config.Choices) do
    local b = button(choicesPanel, "", UDim2.fromScale(0.29, 0.4), UDim2.fromScale(0.04 + (i - 1) * 0.315, 0.37), i == 1 and colors.blue or (i == 2 and colors.white or colors.pink), function() choose(choice) end)
    choiceLabels[choice] = text(b, choice .. "  [" .. keys[choice] .. "]", UDim2.fromScale(0.92, 0.33), UDim2.fromScale(0.04, 0.59), 16, colors.bg)
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
local leave = button(choicesPanel, "Leave match", UDim2.fromScale(0.23, 0.15), UDim2.fromScale(0.73, 0.82), colors.panel, function() request("Leave") end)
leave.TextColor3 = colors.muted
text(choicesPanel, "Tap a card or press 1, 2, or 3", UDim2.fromScale(0.65, 0.13), UDim2.fromScale(0.04, 0.83), 11, colors.muted, Enum.Font.Gotham)

local resultCard = create("CanvasGroup", {
    Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 142),
    Size = UDim2.new(0.82, 0, 0, 80), BackgroundColor3 = colors.bg, BackgroundTransparency = 0.15, ZIndex = 8,
}, duel)
create("UISizeConstraint", { MaxSize = Vector2.new(460, 80) }, resultCard)
round(resultCard, 18)
local resultStroke = stroke(resultCard, colors.gold, 0.2)
local resultTitle = text(resultCard, "Nice move!", UDim2.fromScale(0.9, 0.37), UDim2.fromScale(0.05, 0.12), 26, colors.gold, Enum.Font.GothamBold)
local resultDetail = text(resultCard, "Rock beats scissors", UDim2.fromScale(0.9, 0.33), UDim2.fromScale(0.05, 0.56), 14, colors.white, Enum.Font.Gotham)
local resultScale = create("UIScale", { Scale = 1 }, resultCard)

local transitionVeil = create("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.bg,
    BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30,
}, shell)
local cameraTween, cameraCenter
local function setCamera(center)
    if cameraCenter == center then return end
    cameraCenter = center
    transitionVeil.BackgroundTransparency = 0
    tween(transitionVeil, 0.65, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
    local camera = workspace.CurrentCamera
    if cameraTween then cameraTween:Cancel() end
    if center then
        camera.CameraType = Enum.CameraType.Scriptable
        local target = CFrame.lookAt(center + Vector3.new(0, 10, 24), center + Vector3.new(0, 3, 0))
        -- Set immediately on the first match to avoid traveling through other arenas.
        camera.CFrame = target
        local portrait = camera.ViewportSize.X < camera.ViewportSize.Y
        local distance = portrait and 33 or 23
        cameraTween = tween(camera, 1.1, { CFrame = CFrame.lookAt(center + Vector3.new(0, 8, distance), center + Vector3.new(0, 3, 0)), FieldOfView = 55 }, Enum.EasingStyle.Sine)
    else
        camera.CameraType, camera.FieldOfView = Enum.CameraType.Custom, 70
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then camera.CameraSubject = humanoid end
    end
end

local effects = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 15 }, shell)
local function confetti(isMatch)
    for i = 1, isMatch and 32 or 14 do
        local chip = create("Frame", {
            Size = UDim2.fromOffset(5 + i % 4, 10), Position = UDim2.fromScale(0.25 + (i % 11) * 0.05, -0.02),
            BackgroundColor3 = ({ colors.blue, colors.pink, colors.gold })[(i % 3) + 1],
            Rotation = i * 19, BorderSizePixel = 0,
        }, effects)
        tween(chip, 1.8 + (i % 4) * 0.15, {
            Position = UDim2.fromScale((i % 12) / 11, 1.15), Rotation = i * 53,
            BackgroundTransparency = 1,
        })
        task.delay(2.5, function() chip:Destroy() end)
    end
end

local function showResult(packet)
    local win = packet.result == "win"
    local tie = packet.result == "tie"
    local color = tie and colors.blue or (win and colors.gold or colors.pink)
    resultTitle.TextColor3, resultStroke.Color = color, color
    resultTitle.Text = packet.phase == "finished" and (tie and "Match drawn" or (win and "You take the match!" or "Good game")) or (tie and "Same move. Go again!" or (win and "Nice move!" or "Their point. Next one's yours."))
    resultDetail.Text = packet.phase == "finished" and "Heading back to the lounge shortly." or (packet.myChoice .. "  ·  " .. packet.opponentChoice)
    resultScale.Scale = 0.96
    show(resultCard, true)
    tween(resultScale, 0.36, { Scale = 1 }, Enum.EasingStyle.Quart)
    if win then confetti(packet.phase == "finished") end
end

local function updateScores(packet)
    for i, item in ipairs({ { label = myScore, value = packet.myScore }, { label = theirScore, value = packet.opponentScore } }) do
        local value = tostring(item.value)
        if item.label.Text ~= value then
            item.label.Text = value
            scoreScales[i].Scale = 1.12
            tween(scoreScales[i], 0.38, { Scale = 1 }, Enum.EasingStyle.Quart)
        end
    end
end

local queuedAt = 0

state.OnClientEvent:Connect(function(packet)
    local newRound = packet.matchId ~= current.matchId or packet.round ~= current.round
    if newRound then selected = nil end
    local previous = current
    current = packet
    presentation:set(packet)
    local inDuel = packet.phase == "choosing" or packet.phase == "reveal" or packet.phase == "finished"
    if packet.phase == "queued" and previous.phase ~= "queued" then queuedAt = os.clock(); menuOpen = false end
    if packet.phase == "lobby" and previous.phase == "finished" then menuOpen = false end
    if packet.message then menuOpen = true end
    show(lobby, packet.phase == "lobby" and menuOpen)
    show(lobbyHud, not inDuel)
    show(queuePanel, packet.phase == "queued")
    menuToggle.Active = packet.phase ~= "queued"
    menuToggle.Text = packet.phase == "queued" and "In queue" or "Play"
    duel.Visible = inDuel
    if not inDuel then
        if controls then controls:Enable() end
        setCamera(nil)
        lobbyNote.Text = packet.message or "Rock beats scissors. Scissors beats paper. Paper beats rock."
        exploreHint.Text = packet.phase == "queued" and "Your match starts automatically when someone joins." or "Explore the lounge, or visit a kiosk to play."
        return
    end
    if controls then controls:Disable() end
    setCamera(packet.camera)
    if previous.matchId ~= packet.matchId then
        shown[scoreboard], shown[choicesPanel] = false, false
        show(scoreboard, true)
        show(choicesPanel, true)
    end
    myName.Text, theirName.Text = packet.me .. " (you)", packet.opponent
    local myX, theirX = packet.seat == 2 and 0.67 or 0.03, packet.seat == 2 and 0.03 or 0.67
    myName.Position, myScore.Position = UDim2.fromScale(myX, 0.12), UDim2.fromScale(myX, 0.48)
    theirName.Position, theirScore.Position = UDim2.fromScale(theirX, 0.12), UDim2.fromScale(theirX, 0.48)
    myName.TextColor3 = packet.seat == 2 and colors.pink or colors.blue
    theirName.TextColor3 = packet.seat == 2 and colors.blue or colors.pink
    if packet.phase ~= "reveal" then updateScores(packet) end
    roundText.Text = "Round " .. packet.round
    timerTrack.Visible, timerLabel.Visible = packet.phase == "choosing", packet.phase == "choosing"
    show(resultCard, false)
    for choice, b in pairs(choiceButtons) do
        b.Active = packet.phase == "choosing" and not packet.myReady
        if not b.Active then tween(b:FindFirstChildOfClass("UIScale"), 0.2, { Scale = 1 }) end
        tween(b, 0.22, { BackgroundTransparency = b.Active and 0 or ((selected == choice) and 0.08 or 0.6) })
        choiceLabels[choice].Text = choice .. ((packet.myReady and selected == choice) and "  ✓" or "  [" .. keys[choice] .. "]")
    end
    if packet.phase == "choosing" then
        status.Text = packet.myReady and ((selected or "Move") .. " locked in") or "Choose your move"
        status.TextColor3 = packet.myReady and colors.green or colors.white
        hint.Text = packet.opponentReady and "Your opponent is ready." or (packet.myReady and "All set. Waiting for your opponent." or "Pick one. Your opponent won't see it yet.")
    else
        status.Text = packet.phase == "finished" and "See you in the lounge" or "Rock… paper… scissors…"
        status.TextColor3 = colors.white
        hint.Text = packet.phase == "finished" and "Take a breather, then try another match." or "Here we go."
        if packet.phase == "finished" then
            showResult(packet)
        else
            local delay = math.max(0, Config.RevealWindup + 0.12 - (workspace:GetServerTimeNow() - packet.revealAt))
            task.delay(delay, function()
                if current.matchId == packet.matchId and current.round == packet.round and current.phase == "reveal" then
                    updateScores(packet)
                    status.Text, hint.Text = "Moves revealed", "Next round in a moment."
                    showResult(packet)
                end
            end)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    local choice = ({ [Enum.KeyCode.One] = "Rock", [Enum.KeyCode.Two] = "Paper", [Enum.KeyCode.Three] = "Scissors" })[input.KeyCode]
    if choice then choose(choice) end
end)

RunService.RenderStepped:Connect(function(dt)
    presentation:step(dt)
    if current.phase == "choosing" and current.deadline then
        local remaining = math.max(0, current.deadline - workspace:GetServerTimeNow())
        timerLabel.Text = string.format("%ds to choose", math.ceil(remaining))
        timerFill.Size = UDim2.fromScale(math.clamp(remaining / Config.ChoiceSeconds, 0, 1), 1)
        timerFill.BackgroundColor3 = colors.blue:Lerp(colors.pink, math.clamp((2 - remaining) / 2, 0, 1))
    elseif current.phase == "queued" then
        queueTitle.Text = string.format("Finding an opponent · %ds", math.floor(os.clock() - queuedAt))
    elseif current.phase == "reveal" then
        local revealTime = workspace:GetServerTimeNow() - current.revealAt
        if revealTime < Config.RevealWindup then
            local beat = math.clamp(math.floor(revealTime / Config.RevealWindup * 3) + 1, 1, 3)
            status.Text = ({ "Rock…", "Paper…", "Scissors!" })[beat]
        end
    end
end)

-- Fit the controls around the arena on short mobile displays.
local function resize()
    local viewport = workspace.CurrentCamera.ViewportSize
    local height, width = viewport.Y, viewport.X
    local compact = height < 500
    scoreboard.Size = UDim2.new(0.94, 0, 0, compact and 62 or 80)
    timerTrack.Position = UDim2.new(0.5, 0, 0, compact and 82 or 102)
    timerLabel.Position = UDim2.new(0.4, 0, 0, compact and 92 or 114)
    choicesPanel.Size = UDim2.new(0.94, 0, 0, compact and 134 or 174)
    resultCard.Position = UDim2.new(0.5, 0, 0, compact and 100 or 142)
    resultCard.Size = UDim2.new(0.82, 0, 0, compact and 65 or 80)
    local mobile = width < 700 or compact
    lobby.Size = UDim2.fromOffset(math.min(360, width - 28), math.min(compact and 250 or 370, height - 96))
    lobby.AnchorPoint = mobile and Vector2.new(0.5, 0) or Vector2.new(1, 1)
    lobby.Position = mobile and UDim2.new(0.5, 0, 0, 82) or UDim2.new(1, -18, 1, -18)
    homes[lobby], homes[resultCard] = lobby.Position, resultCard.Position
    brand.Size = UDim2.fromOffset(math.min(230, width - 142), 60)
    exploreHint.Visible = not compact
    if cameraCenter then
        local center = cameraCenter
        cameraCenter = nil
        setCamera(center)
    end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
request("Sync")
