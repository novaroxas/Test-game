-- All visual motion runs locally at render frequency; scoring stays on the server.
local Presentation = {}
Presentation.__index = Presentation

function Presentation.new(windup)
    return setmetatable({ actors = {}, props = {}, windup = windup }, Presentation)
end

function Presentation:stop()
    for _, actor in pairs(self.actors) do
        if actor.root.Parent and actor.root.Anchored then actor.root.CFrame = actor.base end
        for _, shoulder in ipairs(actor.shoulders) do
            if shoulder.joint.Parent then shoulder.joint.C0 = shoulder.base end
        end
        if actor.animate and actor.animate.Parent then actor.animate.Disabled = actor.wasDisabled end
    end
    self.actors, self.props, self.packet = {}, {}, nil
end

function Presentation:set(packet)
    if packet.phase == "lobby" or packet.phase == "queued" then self:stop(); return end
    if self.packet and packet.matchId ~= self.packet.matchId then self:stop() end
    if not self.packet or packet.round ~= self.packet.round then self.props = {} end
    if not self.packet or packet.phase ~= self.packet.phase then self.phaseAt = workspace:GetServerTimeNow() end
    self.packet = packet
end

function Presentation:discover()
    local world = workspace:FindFirstChild("HandClashWorld")
    local arena = world and world:FindFirstChild("Duel_" .. self.packet.matchId)
    if not arena then return end
    for i = 1, 2 do
        if not self.actors[i] then
            local reference, pose = arena:FindFirstChild("Fighter" .. i), arena:FindFirstChild("Pose" .. i)
            local rig = reference and reference.Value
            local root = rig and rig:FindFirstChild("HumanoidRootPart")
            if root and pose then
                local actor = { root = root, base = pose.Value, shoulders = {} }
                for _, joint in ipairs(rig:GetDescendants()) do
                    if joint:IsA("Motor6D") then
                        local right = joint.Name == "RightShoulder" or joint.Name == "Right Shoulder"
                        local left = joint.Name == "LeftShoulder" or joint.Name == "Left Shoulder"
                        if right or left then table.insert(actor.shoulders, { joint = joint, base = joint.C0, right = right }) end
                    end
                end
                local animate = rig:FindFirstChild("Animate")
                if animate and animate:IsA("LocalScript") then
                    actor.animate, actor.wasDisabled = animate, animate.Disabled
                    animate.Disabled = true
                end
                self.actors[i] = actor
            end
        end
        if self.packet.phase == "reveal" and not self.props[i] then
            local model = arena:FindFirstChild("Choice" .. i)
            if model and model.PrimaryPart and model:GetAttribute("Round") == self.packet.round then
                self.props[i] = { model = model, base = model:GetPivot(), pieces = model:GetDescendants() }
            end
        end
    end
end

function Presentation:step(dt)
    local packet = self.packet
    if not packet then return end
    self:discover() -- References and props may replicate after their state packet.
    local now = workspace:GetServerTimeNow()
    local time = math.max(0, now - (packet.revealAt or self.phaseAt))
    local blend = 1 - math.exp(-14 * dt)
    local winner = packet.result == "tie" and 0 or (packet.result == "win" and packet.seat or 3 - packet.seat)
    for i, actor in pairs(self.actors) do
        if actor.root.Parent and actor.root.Anchored then
            local bob = math.sin(now * 2 + i) * 0.045
            local lean, arm = 0, 0
            if packet.phase == "reveal" then
                if time < self.windup then
                    local beat = math.sin(time / self.windup * math.pi * 6)
                    bob, arm = bob + beat * 0.07, -30 + beat * 16
                else
                    local reaction = time - self.windup
                    arm = i == winner and -72 or -35
                    if i == winner then
                        bob = bob + math.abs(math.sin(reaction * 5)) * math.exp(-reaction * 1.7) * 0.45
                        lean = math.sin(reaction * 4) * math.exp(-reaction * 1.7) * 5
                    end
                end
            elseif packet.phase == "finished" and i == winner then
                arm = -115
                bob = bob + math.sin(time * 4) * 0.12
            end
            actor.root.CFrame = actor.root.CFrame:Lerp(actor.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, math.rad(lean)), blend)
            for _, shoulder in ipairs(actor.shoulders) do
                local angle = shoulder.right and arm or (packet.phase == "finished" and i == winner and arm or 0)
                local target = shoulder.base * CFrame.Angles(math.rad(angle), 0, 0)
                shoulder.joint.C0 = shoulder.joint.C0:Lerp(target, blend)
            end
        end
    end
    if packet.phase == "reveal" then
        local progress = math.clamp((time - self.windup) / 0.32, 0, 1)
        local scale = math.max(0.01, 1 - (1 - progress) ^ 3)
        for _, prop in pairs(self.props) do
            if prop.model.Parent then
                prop.model:ScaleTo(scale)
                prop.model:PivotTo(prop.base * CFrame.new(0, math.sin(time * 2.4) * 0.13, 0) * CFrame.Angles(0, math.sin(time * 1.5) * 0.08, 0))
                for _, piece in ipairs(prop.pieces) do
                    if piece:IsA("BasePart") then piece.Transparency = progress > 0 and 0 or 1 end
                    if piece:IsA("BillboardGui") then piece.Enabled = progress >= 0.9 end
                end
            end
        end
    end
end

return Presentation
