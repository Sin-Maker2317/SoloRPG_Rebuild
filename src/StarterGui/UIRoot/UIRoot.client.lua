-- UIRoot.client.lua
-- Simple, robust UI state manager and layer controller
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local function Log(...) print("[UIRoot]", ...) end

-- load style if present
local style = { CornerRadius = UDim.new(0,6), StrokeThickness = 1 }
pcall(function()
    local s = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIStyle")
    style = require(s)
end)

local function ensureScreenGui(parent, name, displayOrder, enabled)
    local sg = parent:FindFirstChild(name)
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = name
        sg.ResetOnSpawn = false
        sg.Parent = parent
    end
    pcall(function() sg.DisplayOrder = displayOrder end)
    if enabled ~= nil then pcall(function() sg.Enabled = enabled end) end
    sg.ResetOnSpawn = false
    return sg
end

local function applyOverlay(screenGui)
    if not screenGui then return end
    local overlay = screenGui:FindFirstChild("__ModalOverlay")
    if overlay then return overlay end
    overlay = Instance.new("Frame")
    overlay.Name = "__ModalOverlay"
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    overlay.BackgroundTransparency = 0.55
    overlay.ZIndex = 1
    overlay.Parent = screenGui
    local corner = Instance.new("UICorner") corner.CornerRadius = style.CornerRadius corner.Parent = overlay
    local stroke = Instance.new("UIStroke") stroke.Thickness = style.StrokeThickness stroke.Parent = overlay
    return overlay
end

local function blockInput() return Enum.ContextActionResult.Sink end

local function setGuiVisibleByName(playerGui, name, visible)
    if not playerGui then return end
    local obj = playerGui:FindFirstChild(name, true)
    if not obj then return end
    if obj:IsA("ScreenGui") then pcall(function() obj.Enabled = visible end) end
    if obj:IsA("GuiObject") then pcall(function() obj.Visible = visible end) end
end

local function moveDescendantsIntoLayer(playerGui, sourceName, layerGui)
    local src = playerGui:FindFirstChild(sourceName)
    if not src then return end
    -- if it's a ScreenGui already, move it
    if src:IsA("ScreenGui") then
        pcall(function() src.Parent = layerGui; src.DisplayOrder = layerGui.DisplayOrder; src.ResetOnSpawn = false end)
        return
    end
    -- if it's a Folder, move any ScreenGui or GuiObject descendants
    if src:IsA("Folder") then
        for _, d in ipairs(src:GetDescendants()) do
            if d:IsA("ScreenGui") or d:IsA("GuiObject") then
                pcall(function() d.Parent = layerGui end)
            end
        end
        -- watch for future additions
        src.DescendantAdded:Connect(function(d)
            if d:IsA("ScreenGui") or d:IsA("GuiObject") then
                pcall(function() d.Parent = layerGui end)
            end
        end)
    end
end

local function init()
    local playerGui = player:WaitForChild("PlayerGui")

    -- layers
    local UI_HUD = ensureScreenGui(playerGui, "UI_HUD", 10, false)
    local UI_Modals = ensureScreenGui(playerGui, "UI_Modals", 100, false)
    local UI_Dev = ensureScreenGui(playerGui, "UI_Dev", 200, false)
    applyOverlay(UI_Modals)

    -- state values/events
    local stateVal = playerGui:FindFirstChild("UIState")
    if not stateVal then
        stateVal = Instance.new("StringValue") stateVal.Name = "UIState" stateVal.Value = "CHOOSE_PATH" stateVal.Parent = playerGui
    end
    local stateEvent = playerGui:FindFirstChild("UIStateChanged")
    if not stateEvent then stateEvent = Instance.new("BindableEvent") stateEvent.Name = "UIStateChanged" stateEvent.Parent = playerGui end
    local requestEvent = playerGui:FindFirstChild("UIRequestStateChange")
    if not requestEvent then requestEvent = Instance.new("BindableEvent") requestEvent.Name = "UIRequestStateChange" requestEvent.Parent = playerGui end
    local devEnabled = playerGui:FindFirstChild("DevEnabled")
    if not devEnabled then devEnabled = Instance.new("BoolValue") devEnabled.Name = "DevEnabled" devEnabled.Value = false devEnabled.Parent = playerGui end

    local function setState(newState)
        if not newState then return end
        if stateVal.Value == newState then return end
        stateVal.Value = newState
        pcall(function() stateEvent:Fire(newState) end)
        Log("State ->", newState)

        -- hide everything in hard list first
        local hardHide = { "DevTestPanel", "DevUILoader", "DebugUI", "QuestHUD", "SkillBar", "StatsPanel", "InventoryView", "EquipmentPanel", "TerminalInteract", "TargetFrame", "HUD", "SystemAwakening" }
        for _, n in ipairs(hardHide) do setGuiVisibleByName(playerGui, n, false) end

        -- default layers off
        UI_Modals.Enabled = false UI_HUD.Enabled = false UI_Dev.Enabled = false devEnabled.Value = false

        if newState == "CHOOSE_PATH" then
            setGuiVisibleByName(playerGui, "HospitalChoice", true)
            setGuiVisibleByName(playerGui, "GuildChoice", true)
            UI_Modals.Enabled = true
        elseif newState == "GUILD_PICK" then
            setGuiVisibleByName(playerGui, "GuildChoice", true)
            UI_Modals.Enabled = true
        elseif newState == "TUTORIAL_MOVEMENT" then
            setGuiVisibleByName(playerGui, "SystemAwakening", true)
            -- minimal HUD optional: keep HUD disabled
        elseif newState == "TUTORIAL_COMBAT" then
            setGuiVisibleByName(playerGui, "SystemAwakening", true)
            setGuiVisibleByName(playerGui, "SkillBar", true)
        elseif newState == "CITY" then
            UI_HUD.Enabled = true
            local enableList = { "HUD", "QuestHUD", "SkillBar", "TargetFrame", "StatsPanel", "InventoryView", "EquipmentPanel", "TerminalInteract", "SystemMessages", "EnemyUI" }
            for _, n in ipairs(enableList) do setGuiVisibleByName(playerGui, n, true) end
        end
    end

    requestEvent.Event:Connect(function(req)
        setState(req)
    end)

    -- Move known StarterGui folders into layers
    local MODALS = { "HospitalChoice", "GuildChoice", "SystemAwakening" }
    local HUDS = { "HUD", "QuestHUD", "SkillBar", "StatsPanel", "InventoryView", "EquipmentPanel", "TerminalInteract", "TargetFrame", "LockOn", "CombatFeel", "SystemMessages", "EnemyUI", "SfxHooks" }
    local DEVS = { "DebugUI", "DevTestPanel", "DevUILoader" }

    for _, n in ipairs(MODALS) do moveDescendantsIntoLayer(playerGui, n, UI_Modals) end
    for _, n in ipairs(HUDS) do moveDescendantsIntoLayer(playerGui, n, UI_HUD) end
    for _, n in ipairs(DEVS) do moveDescendantsIntoLayer(playerGui, n, UI_Dev) end

    -- monitor modal ScreenGuis to enforce overlay and input block
    UI_Modals.DescendantAdded:Connect(function(d)
        if d:IsA("ScreenGui") then
            d:GetPropertyChangedSignal("Enabled"):Connect(function()
                if d.Enabled then
                    UI_Modals.Enabled = true UI_HUD.Enabled = false
                    ContextActionService:BindAction("ModalBlock", function() return Enum.ContextActionResult.Sink end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.Touch, Enum.KeyCode.Escape)
                    Log("Modal ON:", d.Name)
                else
                    UI_Modals.Enabled = false UI_HUD.Enabled = true
                    ContextActionService:UnbindAction("ModalBlock")
                    Log("Modal OFF:", d.Name)
                end
            end)
        end
    end)

    -- Dev toggle (F8) with allowlist
    local allowedDevs = { Azathiell = true, Marietto_Crg = true }
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F8 then
            local can = RunService:IsStudio() or allowedDevs[player.Name]
            if not can then Log("Dev toggle blocked for user", player.Name); return end
            UI_Dev.Enabled = not UI_Dev.Enabled
            devEnabled.Value = UI_Dev.Enabled
            Log("DevToggle ->", UI_Dev.Enabled and "ON" or "OFF")
        end
    end)

    -- initialize
    setState("CHOOSE_PATH")
    Log("Layers ready")
end

local ok, err = pcall(init)
if not ok then warn("[UIRoot] init failed:", err) end
-- UIRoot.client.lua
-- Central UI layer controller: creates UI_HUD, UI_Modals, UI_Dev and applies visibility policies
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local function Log(...)
    print("[UIRoot]", ...)
end

local style = {}
local ok
ok, style = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIStyle"))
end)
if not ok then
    style = {
        Font = Enum.Font.SourceSans,
        PanelColor = Color3.fromRGB(20,20,20),
        TextColor = Color3.fromRGB(255,255,255),
        CornerRadius = UDim.new(0,8),
        StrokeThickness = 1,
        Padding = UDim.new(0,8)
    }
end

local function ensureScreenGui(parent, name, props)
    local sg = parent:FindFirstChild(name)
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = name
        sg.ResetOnSpawn = false
        sg.Parent = parent
    end
    if props then
        if props.DisplayOrder then pcall(function() sg.DisplayOrder = props.DisplayOrder end) end
        if props.Enabled ~= nil then pcall(function() sg.Enabled = props.Enabled end) end
        sg.ResetOnSpawn = false
    end
    return sg
end

local function applyCornerStroke(instance)
    if not instance then return end
    local corner = Instance.new("UICorner")
    corner.CornerRadius = style.CornerRadius
    corner.Parent = instance
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = style.StrokeThickness
    stroke.Color = Color3.new(0,0,0)
    stroke.Parent = instance
end

local function blockAction(name, inputState, inputObject)
    return Enum.ContextActionResult.Sink
end

local function main()
    local playerGui = player:WaitForChild("PlayerGui")

    -- Create layer ScreenGuis
    local UI_HUD = ensureScreenGui(playerGui, "UI_HUD", { DisplayOrder = 10, Enabled = false })
    local UI_Modals = ensureScreenGui(playerGui, "UI_Modals", { DisplayOrder = 100, Enabled = false })
    local UI_Dev = ensureScreenGui(playerGui, "UI_Dev", { DisplayOrder = 200, Enabled = false })

    -- State helpers on PlayerGui
    local stateVal = playerGui:FindFirstChild("UIState")
    if not stateVal then
        stateVal = Instance.new("StringValue")
        stateVal.Name = "UIState"
        stateVal.Value = "CHOOSE_PATH"
        stateVal.Parent = playerGui
    end
    local stateEvent = playerGui:FindFirstChild("UIStateChanged")
    if not stateEvent then
        stateEvent = Instance.new("BindableEvent")
        stateEvent.Name = "UIStateChanged"
        stateEvent.Parent = playerGui
    end
    local devEnabled = playerGui:FindFirstChild("DevEnabled")
    if not devEnabled then
        devEnabled = Instance.new("BoolValue")
        devEnabled.Name = "DevEnabled"
        devEnabled.Value = false
        devEnabled.Parent = playerGui
    end

    local UIStateModule = nil
    pcall(function() UIStateModule = require(script.Parent:WaitForChild("UIState")) end)

    local function setState(newState)
        if not newState then return end
        if stateVal.Value == newState then return end
        stateVal.Value = newState
        pcall(function() stateEvent:Fire(newState) end)
        Log("State ->", newState)
        -- enforce visibility rules
        local function setGuiVisibleByName(name, visible)
            local obj = playerGui:FindFirstChild(name)
            if not obj then return end
            if obj:IsA("ScreenGui") then
                pcall(function() obj.Enabled = visible end)
            elseif obj:IsA("GuiObject") then
                pcall(function() obj.Visible = visible end)
            end
        end

        -- Hard-hide unsafe GUIs by default, then enable allowed ones per state
        local hardHide = { "DevTestPanel", "DevUILoader", "DebugUI", "QuestHUD", "SkillBar", "StatsPanel", "InventoryView", "EquipmentPanel", "TerminalInteract", "TargetFrame", "HUD", "SystemAwakening" }
        for _, n in ipairs(hardHide) do
            setGuiVisibleByName(n, false)
        end

        if newState == (UIStateModule and UIStateModule.STATES.CHOOSE_PATH or "CHOOSE_PATH") then
            -- show only choice modals: HospitalChoice / GuildChoice
            setGuiVisibleByName("HospitalChoice", true)
            setGuiVisibleByName("GuildChoice", true)
            UI_Modals.Enabled = true
            UI_HUD.Enabled = false
            devEnabled.Value = false
        elseif newState == (UIStateModule and UIStateModule.STATES.GUILD_PICK or "GUILD_PICK") then
            setGuiVisibleByName("GuildChoice", true)
            UI_Modals.Enabled = true
            UI_HUD.Enabled = false
            devEnabled.Value = false
        elseif newState == (UIStateModule and UIStateModule.STATES.TUTORIAL_MOVEMENT or "TUTORIAL_MOVEMENT") then
            setGuiVisibleByName("SystemAwakening", true)
            UI_Modals.Enabled = false
            UI_HUD.Enabled = false
            setGuiVisibleByName("SkillBar", false)
            devEnabled.Value = false
        elseif newState == (UIStateModule and UIStateModule.STATES.TUTORIAL_COMBAT or "TUTORIAL_COMBAT") then
            setGuiVisibleByName("SystemAwakening", true)
            UI_Modals.Enabled = false
            UI_HUD.Enabled = false
            setGuiVisibleByName("SkillBar", true)
            devEnabled.Value = false
        elseif newState == (UIStateModule and UIStateModule.STATES.CITY or "CITY") then
            UI_Modals.Enabled = false
            UI_HUD.Enabled = true
            -- enable HUD pieces
            local enableList = { "HUD", "QuestHUD", "SkillBar", "TargetFrame", "StatsPanel", "InventoryView", "EquipmentPanel", "TerminalInteract", "SystemMessages", "EnemyUI" }
            for _, n in ipairs(enableList) do setGuiVisibleByName(n, true) end
        end
    end

    -- expose a request listener: other local scripts may call this BindableEvent to request state changes
    local requestEvent = playerGui:FindFirstChild("UIRequestStateChange")
    if not requestEvent then
        requestEvent = Instance.new("BindableEvent")
        requestEvent.Name = "UIRequestStateChange"
        requestEvent.Parent = playerGui
    end
    requestEvent.Event:Connect(function(req)
        -- simple validation via UIStateModule
        setState(req)
    end)

    -- initialize to CHOOSE_PATH
    setState(UIStateModule and UIStateModule.STATES.CHOOSE_PATH or "CHOOSE_PATH")

    -- Modal overlay
    local overlay = UI_Modals:FindFirstChild("__ModalOverlay")
    if not overlay then
        overlay = Instance.new("Frame")
        overlay.Name = "__ModalOverlay"
        overlay.Size = UDim2.new(1,0,1,0)
        overlay.Position = UDim2.new(0,0,0,0)
        overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
        overlay.BackgroundTransparency = 0.55
        overlay.ZIndex = 1
        overlay.Parent = UI_Modals
        applyCornerStroke(overlay)
    end

    -- mappings
    local MODALS = { "HospitalChoice", "GuildChoice", "SystemAwakening" }
    local HUDS = { "HUD", "QuestHUD", "SkillBar", "StatsPanel", "InventoryView", "EquipmentPanel", "TerminalInteract", "TargetFrame", "LockOn", "CombatFeel", "SystemMessages", "EnemyUI", "SfxHooks" }
    local DEVS = { "DebugUI", "DevTestPanel", "DevUILoader" }

    local function watchModalEnabled(obj, name)
        if not obj then return end
        if not obj:GetPropertyChangedSignal then return end
        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if obj.Enabled then
                UI_Modals.Enabled = true
                UI_HUD.Enabled = false
                ContextActionService:BindAction("ModalBlock", blockAction, false,
                    Enum.UserInputType.MouseButton1,
                    Enum.UserInputType.MouseButton2,
                    Enum.UserInputType.Touch,
                    Enum.KeyCode.E,
                    Enum.KeyCode.R,
                    Enum.KeyCode.F,
                    Enum.KeyCode.Escape)
                Log("Modal ON:", name)
            else
                UI_Modals.Enabled = false
                UI_HUD.Enabled = true
                ContextActionService:UnbindAction("ModalBlock")
                Log("Modal OFF:", name)
            end
        end)
        if obj.Enabled then
            UI_Modals.Enabled = true
            UI_HUD.Enabled = false
            ContextActionService:BindAction("ModalBlock", blockAction, false,
                Enum.UserInputType.MouseButton1,
                Enum.UserInputType.MouseButton2,
                Enum.UserInputType.Touch,
                Enum.KeyCode.E,
                Enum.KeyCode.R,
                Enum.KeyCode.F,
                Enum.KeyCode.Escape)
            Log("Modal ON at init:", name)
        end
    end

    local function handleCandidate(candidate, layerScreenGui, name)
        if not candidate or not candidate.Parent then return end
        if candidate:IsA("ScreenGui") then
            pcall(function()
                candidate.Parent = layerScreenGui
                candidate.DisplayOrder = layerScreenGui.DisplayOrder
                candidate.ResetOnSpawn = false
                if layerScreenGui == UI_HUD then candidate.Enabled = true end
                if layerScreenGui == UI_Dev then candidate.Enabled = false end
            end)
            Log("Reparented:", name, "-> (ScreenGui) " .. layerScreenGui.Name)
            if layerScreenGui == UI_Modals then
                watchModalEnabled(candidate, name)
            end
            return true
        elseif candidate:IsA("GuiObject") then
            pcall(function()
                candidate.Parent = layerScreenGui
            end)
            Log("Reparented:", name, "->", layerScreenGui.Name)
            return true
        end
        return false
    end

    local function safeAssign(name, layerScreenGui)
        local obj = playerGui:FindFirstChild(name)
        if not obj then
            Log("Warning: GUI not found:", name)
            return
        end

        -- If it's a ScreenGui directly, handle immediately
        if obj:IsA("ScreenGui") or obj:IsA("GuiObject") then
            if handleCandidate(obj, layerScreenGui, name) then return end
        end

        -- If it's a Folder (common when StarterGui contains folders), look for ScreenGuis inside
        if obj:IsA("Folder") then
            -- handle existing descendants
            for _, desc in ipairs(obj:GetDescendants()) do
                if desc:IsA("ScreenGui") or desc:IsA("GuiObject") then
                    if handleCandidate(desc, layerScreenGui, name) then
                        -- continue scanning for others
                    end
                end
            end
            -- watch for future creations inside the folder
            obj.DescendantAdded:Connect(function(desc)
                if desc:IsA("ScreenGui") or desc:IsA("GuiObject") then
                    handleCandidate(desc, layerScreenGui, name)
                end
            end)
            return
        end

        -- Fallback
        Log("Skipping non-Gui object:", name, obj.ClassName)
    end

    for _, n in ipairs(MODALS) do safeAssign(n, UI_Modals) end
    for _, n in ipairs(HUDS) do safeAssign(n, UI_HUD) end
    for _, n in ipairs(DEVS) do safeAssign(n, UI_Dev) end

    -- Dev toggle (F8) with allowlist (Studio or named devs)
    local RunService = game:GetService("RunService")
    local allowedDevs = { Azathiell = true, Marietto_Crg = true }
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F8 then
            local can = RunService:IsStudio() or allowedDevs[player.Name]
            if not can then
                Log("Dev toggle blocked for user", player.Name)
                return
            end
            UI_Dev.Enabled = not UI_Dev.Enabled
            devEnabled.Value = UI_Dev.Enabled
            Log("DevToggle ->", UI_Dev.Enabled and "ON" or "OFF")
        end
    end)

    Log("Layers ready")
end

local ok, err = pcall(main)
if not ok then
    warn("[UIRoot] failed to initialize:", err)
end
