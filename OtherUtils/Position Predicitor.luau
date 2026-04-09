if not Game:IsLoaded() then Game.Loaded:Wait() end

--// Game - Services \\--
local Players = Game:GetService("Players")
local RunService = Game:GetService("RunService")
local Stats = Game:GetService("Stats")

--// Stats - Items \\--
local NetworkStats = Stats:FindFirstChild("Network", false) or Stats:WaitForChild("Network", 60)
local ServerStatsItem = NetworkStats:FindFirstChild("ServerStatsItem", false) or NetworkStats:WaitForChild("ServerStatsItem", 60)
local DataPing = ServerStatsItem:FindFirstChild("Data Ping", false) or ServerStatsItem:WaitForChild("Data Ping", 60)

--// Players - LocalPlayer \\-- 
local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalHumanoid = LocalCharacter:FindFirstChildWhichIsA("Humanoid", false) or LocalCharacter:WaitForChild("Humanoid", 60)
local LocalRootPart = LocalHumanoid and (LocalHumanoid.RootPart or LocalCharacter:WaitForChild("HumanoidRootPart", 60))
local LocalCharacterClone = nil

local PingDivisionFactor = 500 -- 500 for the server and 1000 for the client
local Connections = {}
local PoseHistory = {}

--// Creates A LocalCharacter Clone | CreateCharacterClone - Function \\--
local function CreateCharacterClone()
    if LocalCharacterClone then
        LocalCharacterClone:Destroy()
    end
    
    task.wait(1)
    
    LocalCharacter.Archivable = true
    LocalCharacterClone = LocalCharacter:Clone()
    LocalCharacterClone.Name = `{LocalCharacter.Name} Clone`
    LocalCharacterClone.Parent = LocalCharacter.Parent
    LocalCharacter.Archivable = false
    
    for _, Descendant in LocalCharacterClone:GetDescendants() do
        if Descendant:IsA("Motor6D") then
            Descendant.Enabled = false
        end
    end
end

--// Records LocalCharacter Body Part Positions | RecordPose - Function \\--
local function RecordPose(DeltaTime)
    if not LocalCharacter or not LocalRootPart then return end
    local CurrentTime = tick()
    local BodyPartsCFrames = {}
    
    for _, Descendant in LocalCharacter:GetDescendants() do
        if not Descendant:IsA("BasePart") or Descendant == LocalRootPart then continue end
        BodyPartsCFrames[Descendant.Name] = LocalRootPart.CFrame:ToObjectSpace(Descendant.CFrame)
    end
    
    table.insert(PoseHistory, {
        Time = CurrentTime,
        Pivot = LocalCharacter:GetPivot(),
        BodyPartsCFrames = BodyPartsCFrames
    })
    
    while #PoseHistory > 0 and (CurrentTime - PoseHistory[1].Time) > (1 / DeltaTime) do
        table.remove(PoseHistory, 1)
    end
end

--// Updates LocalCharacter Clone Position And Body Parts | UpdateClonePose - Function \\--
local function UpdateClonePose()
    if not (LocalCharacterClone and LocalCharacter) then return end
    
    local CurrentTime = tick()
    local PingDelay = math.clamp(DataPing:GetValue() / PingDivisionFactor, 0, math.huge)
    local TargetTime = CurrentTime - PingDelay
    local TargetPose = nil
    
    for Index = #PoseHistory, 1, -1 do
        if PoseHistory[Index].Time <= TargetTime then
            TargetPose = PoseHistory[Index]
            break
        end
    end
    
    if TargetPose then
        LocalCharacterClone:PivotTo(TargetPose.Pivot)
        
        for _, Child in LocalCharacterClone:GetChildren() do
            if not Child:IsA("BasePart") or Child == LocalCharacterClone.Humanoid.RootPart then continue end
            local RelativeCFrame = TargetPose.BodyPartsCFrames[Child.Name]
            if not RelativeCFrame then continue end
            Child.CFrame = LocalCharacterClone.Humanoid.RootPart.CFrame * RelativeCFrame
        end
    end
end

--// Predicts LocalPlayer Character Server Position | RunService - BindToRenderStep \\--
RunService:BindToRenderStep("Server Position Predictor", 1, function(DeltaTime)
    RecordPose(DeltaTime)
    UpdateClonePose()
    
    if LocalCharacterClone then
        LocalCharacterClone.Humanoid.DisplayDistanceType = "None"
        LocalCharacterClone.Humanoid.PlatformStand = true
        
        for _, Animation in LocalCharacterClone.Humanoid:GetPlayingAnimationTracks() do
            Animation:Stop()
        end
        
        for _, Descendant in LocalCharacterClone:GetDescendants() do
            if Descendant:IsA("BasePart") then
                Descendant.CanCollide = false
                Descendant.CanTouch = false
                Descendant.CanQuery = false
                Descendant.Anchored = false
                if Descendant.Transparency ~= 1 then Descendant.Transparency = 0.5 end
            elseif Descendant:IsA("Script") or Descendant:IsA("LocalScript") or Descendant:IsA("ForceField") then
                Descendant:Destroy()
            end
        end
    end
end)

--// LocalPlayer Respawn Handler | LocalPlayer - CharacterAdded \\--
LocalPlayer.CharacterAdded:Connect(function(Character)
    LocalCharacter = Character
    LocalHumanoid = LocalCharacter:FindFirstChildWhichIsA("Humanoid", false) or LocalCharacter:WaitForChild("Humanoid", 60)
    LocalRootPart = LocalHumanoid.RootPart or LocalCharacter:WaitForChild("HumanoidRootPart", 60)
    CreateCharacterClone()
end)

--// LocalPlayer Character Remover Handler | LocalPlayer - CharacterRemoving \\--
LocalPlayer.CharacterRemoving:Connect(function()
    LocalCharacter = nil
    LocalHumanoid = nil
    LocalRootPart = nil
    if LocalCharacterClone then
        LocalCharacterClone:Destroy()
        LocalCharacterClone = nil
    end
    PoseHistory = {}
end)

CreateCharacterClone()
