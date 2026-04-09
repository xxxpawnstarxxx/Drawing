local getconnections = getconnections

if not getconnections or identifyexecutor() == "Xeno" then
    return
elseif not game:IsLoaded() then
    game.Loaded:Wait()
end

local pcall = pcall
local task_wait = task.wait

local LocalPlayer = game:GetService("Players").LocalPlayer

while true do
    local Success, Result = pcall(function()
        for _, Connection in getconnections(LocalPlayer.Idled) do
            if Connection.ForeignState then
                Connection:Disconnect()
                return true
            end
        end

        return
    end)

    if Success and Result then
        break
    end

    task_wait()
end
