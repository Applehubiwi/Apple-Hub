

print("Mangz loaded")

------------------------------------------------------------------------
-- services
------------------------------------------------------------------------
local svc = {
    Players        = game:GetService("Players"),
    Run            = game:GetService("RunService"),
    Input          = game:GetService("UserInputService"),
    RS             = game:GetService("ReplicatedStorage"),
    WS             = game:GetService("Workspace"),
    TweenService   = game:GetService("TweenService"),
    TextChat       = game:GetService("TextChatService"),
    Http           = game:GetService("HttpService"),
}

local lp  = svc.Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui", 10)

------------------------------------------------------------------------
-- filesystem shims
------------------------------------------------------------------------
local fs = {
    hasFolder = isfolder     or function() return false end,
    makeFolder= makefolder   or function() end,
    write     = writefile    or function() end,
    hasFile   = isfile       or function() return false end,
    read      = readfile     or function() return "" end,
    asset     = getcustomasset or function(p) return p end,
}

------------------------------------------------------------------------
-- config
------------------------------------------------------------------------
local cfg = {}
do
    local DIR  = "Mangzhub"
    local FILE = DIR .. "/mangzhub"
    local function prep()
        if not fs.hasFolder(DIR) then fs.makeFolder(DIR) end
    end
    function cfg.load()
        prep()
        if not fs.hasFile(FILE) then return end
        local ok, t = pcall(svc.Http.JSONDecode, svc.Http, fs.read(FILE))
        if ok and type(t) == "table" then cfg._data = t end
    end
    function cfg.save()
        prep()
        local ok, s = pcall(svc.Http.JSONEncode, svc.Http, cfg._data)
        if ok then fs.write(FILE, s) end
    end
    function cfg.get(k, default)
        local v = cfg._data[k]
        return v ~= nil and v or default
    end
    function cfg.set(k, v)
        cfg._data[k] = v
        cfg.save()
    end
    cfg._data = {}
    cfg.load()
end

------------------------------------------------------------------------
-- WindUI
------------------------------------------------------------------------
local ui = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local win = ui:CreateWindow({
    Title          = "ᴹᵃⁿᵍᶻ ʰᵘᵇ | ᶠᵒʳˢᵃᵏᵉⁿ ᵛ¹.⁰",
    Icon           = "sparkles",
    Author         = "made By Mangz team v1.0",
    Folder         = "mangzhub",
    Size           = UDim2.fromOffset(350, 300),
    Transparent    = false,
    Theme          = "Dark",
    Resizable      = false,
    SideBarWidth   = 150,
    HideSearchBar  = true,
    ScrollBarEnabled = false,
})

win:SetToggleKey(Enum.KeyCode.L)
ui:SetFont("rbxasset://fonts/families/AccanthisADFStd.json")

win:EditOpenButton({
    Title = "Open Mangz hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("24e01d"), 
        Color3.fromHex("19f7f7")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

------------------------------------------------------------------------
-- helpers
------------------------------------------------------------------------
local function getTeamFolder(name)
    local root = svc.WS:FindFirstChild("Players")
    return root and root:FindFirstChild(name)
end
local function getIngame()
    local m = svc.WS:FindFirstChild("Map")
    return m and m:FindFirstChild("Ingame")
end
local function getMapContent()
    local ig = getIngame()
    return ig and ig:FindFirstChild("Map")
end

-- FIX: centralised Network require so path is corrected in one place
local _networkModule = nil
local function getNetwork()
    if _networkModule then return _networkModule end
    local ok, m = pcall(function()
        return require(svc.RS.Modules.Network.Network)
    end)
    if ok and m then _networkModule = m end
    return _networkModule
end

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: SETTINGS
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabSettings = win:Tab({ Title = "Setting", Icon = "settings" })
local secInterface = tabSettings:Section({ Title = "Interface", Opened = true })

local spoofActive = cfg.get("spoofActive", false)
local spoofText   = cfg.get("spoofText",   "mangz")
local spoofCache  = {}
local spoofConns  = {}

local function spoofApply(lbl)
    if not (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) then return end
    if lbl.Name ~= "Username" then return end
    if not spoofCache[lbl] then spoofCache[lbl] = lbl.Text end
    if spoofActive then lbl.Text = spoofText end
end
local function spoofRevert()
    for lbl, orig in pairs(spoofCache) do
        if lbl and lbl.Parent then lbl.Text = orig end
    end
    spoofCache = {}
end
local function spoofScan()
    local pg = lp:FindFirstChild("PlayerGui"); if not pg then return end
    task.defer(function()
        for _, root in ipairs({ pg:FindFirstChild("MainUI"), pg:FindFirstChild("TemporaryUI") }) do
            if root then for _, obj in ipairs(root:GetDescendants()) do spoofApply(obj) end end
        end
    end)
end
local function spoofWatch(root)
    if not root then return end
    table.insert(spoofConns, root.DescendantAdded:Connect(function(obj)
        if spoofActive then task.defer(spoofApply, obj) end
    end))
end
local function spoofStart()
    for _, c in ipairs(spoofConns) do if c.Connected then c:Disconnect() end end
    spoofConns = {}
    local pg = lp:FindFirstChild("PlayerGui"); if not pg then return end
    spoofScan()
    spoofWatch(pg:FindFirstChild("MainUI"))
    spoofWatch(pg:FindFirstChild("TemporaryUI"))
    table.insert(spoofConns, pg.ChildAdded:Connect(function(child)
        if (child.Name == "MainUI" or child.Name == "TemporaryUI") and spoofActive then
            task.delay(0.1, spoofScan); spoofWatch(child)
        end
    end))
end
local function spoofStop()
    for _, c in ipairs(spoofConns) do if c.Connected then c:Disconnect() end end
    spoofConns = {}; spoofRevert()
end

secInterface:Toggle({
    Title = "Spoof Usernames", Type = "Checkbox", Default = spoofActive,
    Callback = function(on) spoofActive = on; cfg.set("spoofActive", on); if on then spoofStart() else spoofStop() end end
})

local chatForceEnabled = cfg.get("chatForceEnabled", false)
local chatForceConn    = nil
local function enforceChatOn()
    if not chatForceEnabled then return end
    local cw = svc.TextChat:FindFirstChild("ChatWindowConfiguration")
    local ci = svc.TextChat:FindFirstChild("ChatInputBarConfiguration")
    if cw and not cw.Enabled then cw.Enabled = true end
    if ci and not ci.Enabled then ci.Enabled = true end
end
secInterface:Toggle({
    Title = "Show Chat Logs", Type = "Checkbox", Default = chatForceEnabled,
    Callback = function(on)
        chatForceEnabled = on; cfg.set("chatForceEnabled", on)
        if chatForceConn then chatForceConn:Disconnect(); chatForceConn = nil end
        if on then
            enforceChatOn()
            chatForceConn = svc.Run.Heartbeat:Connect(enforceChatOn)
            for _, key in ipairs({ "ChatWindowConfiguration", "ChatInputBarConfiguration" }) do
                local obj = svc.TextChat:FindFirstChild(key)
                if obj then obj:GetPropertyChangedSignal("Enabled"):Connect(enforceChatOn) end
            end
        end
    end
})

local timerSide = cfg.get("timerSide", "Middle")
local function applyTimerPos()
    local rt = lp.PlayerGui:FindFirstChild("RoundTimer")
    local m  = rt and rt:FindFirstChild("Main")
    if m then m.Position = UDim2.new(timerSide == "Middle" and 0.5 or 0.9, 0, m.Position.Y.Scale, m.Position.Y.Offset) end
end
applyTimerPos()
secInterface:Dropdown({
    Title = "Timer Position", Values = { "Middle", "Right" }, Value = timerSide,
    Callback = function(v) timerSide = v; cfg.set("timerSide", v); applyTimerPos() end
})
lp.CharacterAdded:Connect(function()
    task.delay(1, function() if spoofActive then spoofStart() end; applyTimerPos() end)
end)

local secPlatform = tabSettings:Section({ Title = "Platform Spoofer", Opened = true })
local platEnabled = cfg.get("platEnabled", false)
local platDevice  = cfg.get("platDevice",  "Console")
local platLoop    = nil
local platConn    = nil

-- FIX: use getNetwork() helper instead of bare require(svc.RS.Modules.Network)
local function platPush()
    if not platEnabled then return end
    local net = getNetwork()
    if net then pcall(function() net:FireServerConnection("SetDevice", "REMOTE_EVENT", platDevice) end) end
end
local function platStart()
    if platLoop then return end; platPush()
    if platConn then platConn:Disconnect() end
    platConn = svc.Input.LastInputTypeChanged:Connect(function() if platEnabled then platPush() end end)
    platLoop = task.spawn(function() while platEnabled do platPush(); task.wait(1) end; platLoop = nil end)
end
local function platStop()
    platEnabled = false
    if platLoop then task.cancel(platLoop); platLoop = nil end
    if platConn then platConn:Disconnect(); platConn = nil end
end
secPlatform:Toggle({ Title = "Enable Spoofer", Type = "Checkbox", Default = platEnabled,
    Callback = function(on) platEnabled = on; cfg.set("platEnabled", on); if on then platStart() else platStop() end end })
secPlatform:Dropdown({ Title = "Device", Values = { "PC", "Mobile", "Console" }, Value = platDevice,
    Callback = function(v) platDevice = v; cfg.set("platDevice", v); if platEnabled then platPush() end end })
lp.CharacterAdded:Connect(function() task.delay(1, function() if platEnabled then platPush() end end) end)

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: GLOBAL
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabGlobal  = win:Tab({ Title = "Global", Icon = "globe" })
local secStamina = tabGlobal:Section({ Title = "Stamina", Opened = true })

local stam = {
    on      = cfg.get("stamOn",      false),
    loss    = cfg.get("stamLoss",    10),
    gain    = cfg.get("stamGain",    20),
    max     = cfg.get("stamMax",     100),
    current = cfg.get("stamCurrent", 100),
    noLoss  = cfg.get("stamNoLoss",  false),
    thread  = nil,
}

-- FIX: corrected path — verify this in your explorer under ReplicatedStorage.Systems
local function stamModule()
    local ok, m = pcall(function() return require(svc.RS.Systems.Character.Game.Sprinting) end)
    return ok and m or nil
end
local function stamIsKiller()
    local ch = lp.Character; if not ch then return false end
    local kf = getTeamFolder("Killers")
    return kf and ch:IsDescendantOf(kf)
end
local function stamApply()
    local m = stamModule(); if not m then return end
    if not m.DefaultsSet then pcall(function() m.Init() end) end
    local forceNoLoss = stam.noLoss or stamIsKiller()
    m.StaminaLoss = stam.loss; m.StaminaGain = stam.gain
    local abilityCapActive = type(m.StaminaCap) == "number" and m.StaminaCap < (m.MaxStamina or math.huge)
    if not abilityCapActive then
        m.MaxStamina = stam.max
        if type(m.StaminaCap) == "number" then m.StaminaCap = stam.max end
    end
    m.StaminaLossDisabled = forceNoLoss
    if m.Stamina and m.Stamina > stam.max then m.Stamina = stam.current end
    pcall(function() if m.__staminaChangedEvent then m.__staminaChangedEvent:Fire() end end)
end
local function stamStart()
    if stam.thread then return end
    stam.thread = task.spawn(function()
        while stam.on do
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then stamApply() end
            task.wait(0.5)
        end; stam.thread = nil
    end)
end
local function stamStop()
    stam.on = false
    if stam.thread then task.cancel(stam.thread); stam.thread = nil end
end
secStamina:Toggle({ Title = "Custom Stamina 🏃", Type = "Checkbox", Default = stam.on,
    Callback = function(on) stam.on = on; cfg.set("stamOn", on); if on then stamStart() else stamStop() end end })
secStamina:Slider({ Title = "Loss Rate",     Step = 1, Value = { Min = 0,  Max = 50,  Default = stam.loss    }, Callback = function(v) stam.loss    = v; cfg.set("stamLoss",    v) end })
secStamina:Slider({ Title = "Gain Rate",     Step = 1, Value = { Min = 0,  Max = 200,  Default = stam.gain    }, Callback = function(v) stam.gain    = v; cfg.set("stamGain",    v) end })
secStamina:Slider({ Title = "Max Pool",      Step = 1, Value = { Min = 50, Max = 500, Default = stam.max     }, Callback = function(v) stam.max     = v; cfg.set("stamMax",     v) end })
secStamina:Slider({ Title = "Current Value", Step = 1, Value = { Min = 0,  Max = 500, Default = stam.current }, Callback = function(v) stam.current = v; cfg.set("stamCurrent", v) end })
secStamina:Toggle({ Title = "Infinite Stamina", Type = "Checkbox", Default = stam.noLoss,
    Callback = function(on)
        stam.noLoss = on; cfg.set("stamNoLoss", on); stamApply()
        if on and not stam.on then stam.on = true; stamStart() end
    end
})
if stam.on then stamStart() end
lp.CharacterAdded:Connect(function()
    task.delay(1.5, function()
        if stam.on then stamApply(); if not stam.thread then stamStart() end end
    end)
end)

local secStatus = tabGlobal:Section({ Title = "Status", Opened = true })
-- FIX: correct paths confirmed as Modules.Schematics.StatusEffects.*
-- Glitched is a LocalScript inside KillerExclusive.Glitched.Frame — handled separately
local statusGroups = {
    Slowness      = { on = false, paths = { "Modules.Schematics.StatusEffects.Slowness" } },
    Hallucination = { on = false, paths = { "Modules.Schematics.StatusEffects.KillerExclusive.Hallucination" } },
    Visual        = { on = false, paths = {
        "Modules.Schematics.StatusEffects.Blindness",
        "Modules.Schematics.StatusEffects.SurvivorExclusive.Subspaced",
        -- Glitched is a LocalScript inside a Frame, destroyed via parent folder instead
        "Modules.Schematics.StatusEffects.KillerExclusive.Glitched",
    }},
}
local statusBackup = {}
local function statusResolve(path)
    local node = svc.RS
    for seg in path:gmatch("[^%.]+") do node = node:FindFirstChild(seg); if not node then return nil end end
    return node
end
local function statusBlock(path)
    if statusBackup[path] then return end
    local mod = statusResolve(path)
    if not mod then return end
    -- Glitched is a Folder containing a Frame containing a LocalScript — destroy the folder
    if mod:IsA("Folder") then
        statusBackup[path] = { clone = mod:Clone(), isFolder = true, parentPath = path:match("^(.-)%.?[^%.]+$") }
        mod:Destroy()
    elseif mod:IsA("ModuleScript") or mod:IsA("LocalScript") then
        statusBackup[path] = { clone = mod:Clone(), src = mod.Source, isFolder = false }
        mod:Destroy()
    end
end
local function statusRestore(path)
    local saved = statusBackup[path]; if not saved then return end
    local existing = statusResolve(path); if existing then existing:Destroy() end
    local parentPath = saved.parentPath or path:match("^(.-)%.?[^%.]+$")
    local parent = statusResolve(parentPath)
    if parent then
        if not saved.isFolder then saved.clone.Source = saved.src end
        saved.clone.Parent = parent
    end
    statusBackup[path] = nil
end
local statusLoopThread = nil
local function statusTick()
    if statusLoopThread then return end
    statusLoopThread = task.spawn(function()
        while true do
            local any = false
            for _, g in pairs(statusGroups) do
                if g.on then any = true; for _, p in ipairs(g.paths) do local m = statusResolve(p); if m then m:Destroy() end end end
            end
            if not any then break end; task.wait(0.8)
        end; statusLoopThread = nil
    end)
end
local function statusToggle(name)
    local g = statusGroups[name]; if not g then return end; g.on = not g.on
    for _, p in ipairs(g.paths) do if g.on then statusBlock(p) else statusRestore(p) end end
    local any = false; for _, sg in pairs(statusGroups) do if sg.on then any = true; break end end
    if any then statusTick() elseif statusLoopThread then task.cancel(statusLoopThread); statusLoopThread = nil end
end
secStatus:Button({ Title = "Toggle: Slowness",       Callback = function() statusToggle("Slowness")      end })
secStatus:Button({ Title = "Toggle: Hallucination",  Callback = function() statusToggle("Hallucination") end })
secStatus:Button({ Title = "Toggle: Visual Effects", Callback = function() statusToggle("Visual")        end })
lp.CharacterAdded:Connect(function()
    statusBackup = {}; for _, g in pairs(statusGroups) do g.on = false end
    if statusLoopThread then task.cancel(statusLoopThread); statusLoopThread = nil end
end)

------------------------------------------------------------------------
-- HITBOX
-- FIX: get the RemoteEvent through the Network module instead of
--      trying to index it as a child of the Network ModuleScript
------------------------------------------------------------------------
local secHitbox = tabGlobal:Section({ Title = "Hitbox", Opened = true })
local hb = { on = cfg.get("hbOn", false), strength = cfg.get("hbStrength", 50), conn = nil, active = {} }
local hbAbilities = { Slash=1,Swing=1,Dagger=1,Charge=1,Punch=1,PlasmaBeam=1,Shoot=1,Behead=1,GashingWound=1,CorruptNature=1,WalkspeedOride=1,Stab=1,Nova=1,MassInfection=1,Entanglement=1,Axe=1 }

local function hbReadName(raw)
    if typeof(raw) == "buffer" then local s = buffer.tostring(raw); return s:match("[%a]+") or s:gsub("[^%w]","") end
    return tostring(raw):gsub("\"","")
end
local function hbPush(dist)
    local ch = lp.Character; if not ch then return end
    local r  = ch:FindFirstChild("HumanoidRootPart"); if not r then return end
    local was = r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity = was + r.CFrame.LookVector * dist
    svc.Run.RenderStepped:Wait()
    if ch and ch.Parent and r and r.Parent then r.AssemblyLinearVelocity = was end
end

-- FIX: direct path confirmed from checker: ReplicatedStorage.Modules.Network.Network.RemoteEvent
-- Do NOT use GetRemote() or WaitForChild — both block indefinitely if the remote isn't ready
local _hbRemote = nil
local function hbGetRemote()
    if _hbRemote and _hbRemote.Parent then return _hbRemote end
    local ok, re = pcall(function()
        return svc.RS.Modules.Network.Network:FindFirstChild("RemoteEvent")
    end)
    if ok and re then _hbRemote = re; return re end
    return nil
end

local function hbStart()
    if hb.conn then return end
    local remote = hbGetRemote()
    if not remote then
        warn("[v1prware] hbStart: could not find RemoteEvent for hitbox — feature disabled")
        return
    end
    hb.conn = remote.OnClientEvent:Connect(function(action, data)
        if not hb.on or action ~= "UseActorAbility" then return end
        if typeof(data) ~= "table" or not data[1] then return end
        local name = hbReadName(data[1])
        if not name or not hbAbilities[name] or hb.active[name] then return end
        hb.active[name] = true; local t0 = tick()
        local c; c = svc.Run.Heartbeat:Connect(function()
            if tick() - t0 >= 1 then c:Disconnect(); hb.active[name] = nil; return end
            if hb.on then hbPush(hb.strength) else c:Disconnect(); hb.active[name] = nil end
        end)
    end)
end
local function hbStop()
    if hb.conn then hb.conn:Disconnect(); hb.conn = nil end
    for k in pairs(hb.active) do hb.active[k] = nil end
end
secHitbox:Toggle({ Title = "Hitbox Expander🎯", Type = "Checkbox", Default = hb.on,
    Callback = function(on) hb.on = on; cfg.set("hbOn", on); if on then hbStart() else hbStop() end end })
secHitbox:Slider({ Title = "Strength", Step = 1, Value = { Min = 5, Max = 450, Default = hb.strength },
    Callback = function(v) hb.strength = v; cfg.set("hbStrength", v) end })
lp.CharacterAdded:Connect(function()
    for k in pairs(hb.active) do hb.active[k] = nil end
    task.delay(1, function() if hb.on then hbStop(); hbStart() end end)
end)
lp.CharacterRemoving:Connect(function() for k in pairs(hb.active) do hb.active[k] = nil end end)

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: GENERATOR
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabGen     = win:Tab({ Title = "Generator", Icon = "circuit-board" })
local secGenAuto = tabGen:Section({ Title = "Auto Solve", Opened = true })

local flow = { on = cfg.get("flowOn", false), nodeDelay = cfg.get("flowNodeDelay", 0.04), lineDelay = cfg.get("flowLineDelay", 0.60) }
local function flowKey(n) return n.row.."-"..n.col end
local function flowNeighbour(r1,c1,r2,c2)
    if r2==r1-1 and c2==c1 then return"up" end; if r2==r1+1 and c2==c1 then return"down" end
    if r2==r1 and c2==c1-1 then return"left" end; if r2==r1 and c2==c1+1 then return"right" end; return false
end
local function flowOrder(path, endpoints)
    if not path or #path == 0 then return path end
    local lookup = {}
    for _, n in ipairs(path) do lookup[flowKey(n)] = n end
    local start
    -- prefer starting from a known endpoint
    for _, ep in ipairs(endpoints or {}) do
        for _, n in ipairs(path) do
            if n.row == ep.row and n.col == ep.col then
                start = { row = ep.row, col = ep.col }
                break
            end
        end
        if start then break end
    end
    -- fall back to any dead-end node (only one neighbour in path)
    if not start then
        for _, n in ipairs(path) do
            local nb = 0
            for _, d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                if lookup[(n.row+d[1]).."-"..(n.col+d[2])] then nb += 1 end
            end
            if nb == 1 then start = { row = n.row, col = n.col }; break end
        end
    end
    if not start then start = { row = path[1].row, col = path[1].col } end
    local pool, ordered = {}, {}
    for _, n in ipairs(path) do pool[flowKey(n)] = { row = n.row, col = n.col } end
    local cur = start
    table.insert(ordered, { row = cur.row, col = cur.col })
    pool[flowKey(cur)] = nil
    while next(pool) do
        local moved = false
        for k, node in pairs(pool) do
            if flowNeighbour(cur.row, cur.col, node.row, node.col) then
                table.insert(ordered, { row = node.row, col = node.col })
                pool[k] = nil; cur = node; moved = true; break
            end
        end
        if not moved then break end
    end
    return ordered
end
local function flowSolve(puzzle)
    if not puzzle or not puzzle.Solution then return end
    -- shuffle solve order so it looks more natural
    local indices = {}
    for i = 1, #puzzle.Solution do indices[i] = i end
    for i = #indices, 2, -1 do
        local j = math.random(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    for _, ci in ipairs(indices) do
        local solution = puzzle.Solution[ci]
        if not solution then continue end
        -- order the path starting from one of the target endpoints
        local ordered = flowOrder(solution, puzzle.targetPairs[ci])
        if not ordered or #ordered == 0 then continue end
        -- reset this color's path then write nodes one by one
        puzzle.paths[ci] = {}
        for _, node in ipairs(ordered) do
            table.insert(puzzle.paths[ci], { row = node.row, col = node.col })
            -- updateGui rebuilds connections internally via getGrid() — no manual gridConnections needed
            puzzle:updateGui()
            task.wait(flow.nodeDelay)
        end
        task.wait(flow.lineDelay)
        puzzle:checkForWin()
    end
end

-- FIX: FlowGameManager is a Folder — FlowGame is the ModuleScript inside it
-- The module returns the u61 class table; hook u61.new to intercept new puzzle instances
do
    local modFolder  = svc.RS:FindFirstChild("Modules")
    local miniFolder = modFolder and modFolder:FindFirstChild("Minigames")
    local fgFolder   = miniFolder and miniFolder:FindFirstChild("FlowGameManager")
    local fgModule   = fgFolder and fgFolder:FindFirstChild("FlowGame")
    if fgModule then
        local ok, FG = pcall(require, fgModule)
        if ok and FG and FG.new then
            local orig = FG.new
            FG.new = function(...)
                local p = orig(...)
                if flow.on then
                    task.spawn(function()
                        task.wait(0.3) -- let Init() finish and GUI tween begin
                        flowSolve(p)
                    end)
                end
                return p
            end
        else
            warn("[v1prware] FlowGame: failed to require FlowGame module — auto-solve disabled")
        end
    else
        warn("[v1prware] FlowGame: Modules.Minigames.FlowGameManager.FlowGame not found — auto-solve disabled")
    end
end

secGenAuto:Toggle({ Title = "Auto Solve", Type = "Checkbox", Default = flow.on, Callback = function(on) flow.on = on; cfg.set("flowOn", on) end })
secGenAuto:Slider({ Title = "Node Speed", Step = 0.02, Value = { Min = 0.01, Max = 0.50, Default = flow.nodeDelay }, Callback = function(v) flow.nodeDelay = v; cfg.set("flowNodeDelay", v) end })
secGenAuto:Slider({ Title = "Line Pause", Step = 0.10, Value = { Min = 0.00, Max = 1.00, Default = flow.lineDelay }, Callback = function(v) flow.lineDelay = v; cfg.set("flowLineDelay", v) end })

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: KILLER
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabKiller = win:Tab({ Title = "Killer", Icon = "crosshair" })
local secAimbot = tabKiller:Section({ Title = "Aimbot", Opened = true })

local aim = {
    on=cfg.get("aimOn",false), cooldown=cfg.get("aimCooldown",0.3), lockTime=cfg.get("aimLockTime",0.4),
    maxDist=cfg.get("aimMaxDist",30), smooth=cfg.get("aimSmooth",0.35),
    targeting=false, target=nil, deathConn=nil, autoRotate=nil, lastFired=0,
    hum=nil, hrp=nil, cache={}, cacheTime=0, cacheLife=0.5,
}
local function aimAmIKiller() local ch=lp.Character; if not ch then return false end; local kf=getTeamFolder("Killers"); return kf and ch:IsDescendantOf(kf) end
local function aimRefreshChar(ch) aim.hum=ch:FindFirstChildOfClass("Humanoid"); aim.hrp=ch:FindFirstChild("HumanoidRootPart") end
local function aimRefreshTargets()
    local now=tick(); if now-aim.cacheTime<aim.cacheLife then return end; aim.cacheTime=now; aim.cache={}
    local sf=getTeamFolder("Survivors"); if not sf then return end
    for _,model in ipairs(sf:GetChildren()) do if model~=lp.Character and model:IsA("Model") then local h=model:FindFirstChildOfClass("Humanoid"); local r=model:FindFirstChild("HumanoidRootPart"); if h and r and h.Health>0 then table.insert(aim.cache,r) end end end
end
local function aimNearest()
    aimRefreshTargets(); if not aim.hrp or #aim.cache==0 then return nil end
    local best,bd=nil,math.huge; for _,r in ipairs(aim.cache) do local d=(r.Position-aim.hrp.Position).Magnitude; if d<bd and d<=aim.maxDist then bd=d; best=r end end; return best
end
local function aimUnlock()
    if not aim.targeting then return end
    if aim.deathConn then aim.deathConn:Disconnect(); aim.deathConn=nil end
    if aim.autoRotate~=nil and aim.hum then aim.hum.AutoRotate=aim.autoRotate end
    aim.targeting=false; aim.target=nil
end
local function aimLock(r)
    if not r or not r.Parent or not aim.hum or not aim.hrp then return end
    if aim.targeting and aim.target==r then return end
    aimUnlock(); aim.target=r; aim.targeting=true; aim.autoRotate=aim.hum.AutoRotate; aim.hum.AutoRotate=false
    local th=r.Parent:FindFirstChildOfClass("Humanoid"); if th then aim.deathConn=th.Died:Connect(aimUnlock) end
    task.delay(aim.lockTime, function() if aim.target==r then aimUnlock() end end)
end
svc.Run.RenderStepped:Connect(function()
    if not aim.on or not aim.targeting or not aim.hrp or not aim.target then return end
    if not aim.target.Parent then aimUnlock(); return end
    local th=aim.target.Parent:FindFirstChildOfClass("Humanoid"); if not th or th.Health<=0 then aimUnlock(); return end
    local flat=Vector3.new(aim.target.Position.X-aim.hrp.Position.X,0,aim.target.Position.Z-aim.hrp.Position.Z).Unit
    if flat.Magnitude>0 then aim.hrp.CFrame=aim.hrp.CFrame:Lerp(CFrame.new(aim.hrp.Position,aim.hrp.Position+flat),aim.smooth) end
end)

-- FIX: use getNetwork()/hbGetRemote() instead of WaitForChild on Network as a folder
task.spawn(function()
    local remote = hbGetRemote()
    if not remote then
        warn("[v1prware] Aimbot: could not find RemoteEvent — aimbot trigger disabled")
        return
    end
    remote.OnClientEvent:Connect(function(...)
        if not aim.on then return end
        local a={...}; if typeof(a[1])~="string" then return end; local n=a[1]
        if not (n:match("Ability") or n:match("[QER]") or n=="Slash" or n=="Dagger" or n=="Charge") then return end
        if tick()-aim.lastFired<aim.cooldown then return end; aim.lastFired=tick()
        if aimAmIKiller() then local t=aimNearest(); if t then aimLock(t) end end
    end)
end)

lp.CharacterAdded:Connect(function(ch) task.wait(0.5); aimRefreshChar(ch) end)
if lp.Character then aimRefreshChar(lp.Character) end

secAimbot:Toggle({ Title="Enable Aimbot",      Type="Checkbox", Default=aim.on,       Callback=function(on) aim.on=on;       cfg.set("aimOn",on);       if not on then aimUnlock() end end })
secAimbot:Slider({ Title="Cooldown (s)",        Step=0.05, Value={Min=0.1, Max=2.0, Default=aim.cooldown}, Callback=function(v) aim.cooldown=v; cfg.set("aimCooldown",v) end })
secAimbot:Slider({ Title="Lock Time (s)",       Step=0.1,  Value={Min=0.1, Max=3.0, Default=aim.lockTime}, Callback=function(v) aim.lockTime=v; cfg.set("aimLockTime",v)  end })
secAimbot:Slider({ Title="Max Distance",        Step=5,    Value={Min=5,   Max=100, Default=aim.maxDist},  Callback=function(v) aim.maxDist=v;  cfg.set("aimMaxDist",v)   end })
secAimbot:Slider({ Title="Rotation Smoothing",  Step=0.05, Value={Min=0.05,Max=1.0, Default=aim.smooth},  Callback=function(v) aim.smooth=v;   cfg.set("aimSmooth",v)    end })

local secABS = tabKiller:Section({ Title = "Anti-Backstab", Opened = true })
local abs = { on=cfg.get("absOn",false), range=cfg.get("absRange",40), duration=cfg.get("absDur",1.5), locked=false, soundConn=nil, scanThread=nil, rings={} }
local absTriggerSounds = { ["86710781315432"]=true, ["99820161736138"]=true }
local absScreenGui = nil
local function absGui()
    if absScreenGui and absScreenGui.Parent then return absScreenGui end
    local pg=lp:FindFirstChild("PlayerGui"); if not pg then return nil end
    absScreenGui=Instance.new("ScreenGui"); absScreenGui.Name="AbsGui"; absScreenGui.ResetOnSpawn=false; absScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; absScreenGui.Parent=pg; return absScreenGui
end
local function absShowLabel(show)
    local g=absGui(); if not g then return end; local lbl=g:FindFirstChild("AbsTaunt")
    if not lbl then lbl=Instance.new("TextLabel"); lbl.Name="AbsTaunt"; lbl.Size=UDim2.new(0,500,0,50); lbl.Position=UDim2.new(0.5,-250,0.38,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.new(1,1,1); lbl.TextStrokeTransparency=0.4; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.Text="At least they tried 😂"; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=36; lbl.TextTransparency=1; lbl.Parent=g end
    pcall(function() svc.TweenService:Create(lbl,TweenInfo.new(show and 0.15 or 0.5),{TextTransparency=show and 0 or 1}):Play() end)
end
local function absAddRing(model)
    local hrp=model:FindFirstChild("HumanoidRootPart"); if not hrp or abs.rings[model] then return end
    pcall(function()
        local ring=Instance.new("Part"); ring.Name="AbsRing"; ring.Shape=Enum.PartType.Cylinder; ring.Size=Vector3.new(0.1,abs.range*2,abs.range*2); ring.Color=Color3.fromRGB(220,50,50); ring.Material=Enum.Material.ForceField; ring.Transparency=0.5; ring.CanCollide=false; ring.CanTouch=false; ring.CFrame=hrp.CFrame*CFrame.Angles(0,0,math.rad(90)); ring.Parent=hrp
        local w=Instance.new("WeldConstraint"); w.Part0=hrp; w.Part1=ring; w.Parent=ring; abs.rings[model]=ring
    end)
end
local function absRemoveRing(model) local r=abs.rings[model]; if r then pcall(function()r:Destroy()end); abs.rings[model]=nil end end
local function absResizeRings() for _,r in pairs(abs.rings) do if r and r.Parent then r.Size=Vector3.new(0.1,abs.range*2,abs.range*2) end end end
local function absCleanRings() for m in pairs(abs.rings) do absRemoveRing(m) end end
local function absFindTwoTime() local players=svc.WS:FindFirstChild("Players"); if not players then return nil end; for _,folder in ipairs(players:GetChildren()) do local tt=folder:FindFirstChild("TwoTime"); if tt then return tt end end; return nil end
local function absTrigger()
    if abs.locked then return end; local ch=lp.Character; local myRoot=ch and ch:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    local ttModel=absFindTwoTime(); if not ttModel then return end; local ttRoot=ttModel:FindFirstChild("HumanoidRootPart"); if not ttRoot then return end
    if (myRoot.Position-ttRoot.Position).Magnitude>abs.range then return end
    abs.locked=true; absShowLabel(true)
    task.spawn(function()
        local deadline=tick()+abs.duration
        while tick()<deadline do if not abs.on then break end; local ch2=lp.Character; local r2=ch2 and ch2:FindFirstChild("HumanoidRootPart"); if not r2 or not ttRoot.Parent then break end; r2.CFrame=CFrame.lookAt(r2.Position,Vector3.new(ttRoot.Position.X,r2.Position.Y,ttRoot.Position.Z)); svc.Run.RenderStepped:Wait() end
        abs.locked=false; absShowLabel(false)
    end)
end
local function absHookSounds()
    if abs.soundConn then abs.soundConn:Disconnect(); abs.soundConn=nil end
    abs.soundConn=svc.WS.DescendantAdded:Connect(function(obj)
        if not abs.on or not obj:IsA("Sound") then return end; local id=obj.SoundId:match("%d+"); if id and absTriggerSounds[id] then absTrigger() end
    end)
end
local function absStartScan()
    if abs.scanThread then return end
    abs.scanThread=task.spawn(function()
        while abs.on do
            local players=svc.WS:FindFirstChild("Players")
            if players then for _,folder in ipairs(players:GetChildren()) do for _,model in ipairs(folder:GetChildren()) do if model.Name=="TwoTime" then absAddRing(model) end end end end
            for m in pairs(abs.rings) do if not m.Parent then absRemoveRing(m) end end; task.wait(1)
        end; abs.scanThread=nil
    end)
end
local function absStart() absHookSounds(); absStartScan() end
local function absStop() abs.on=false; if abs.soundConn then abs.soundConn:Disconnect(); abs.soundConn=nil end; if abs.scanThread then task.cancel(abs.scanThread); abs.scanThread=nil end; absCleanRings(); abs.locked=false; absShowLabel(false) end
lp.CharacterAdded:Connect(function() abs.locked=false; if abs.on then absStart() end end)
secABS:Toggle({ Title="Enable Anti-Backstab", Type="Checkbox", Default=abs.on, Callback=function(on) abs.on=on; cfg.set("absOn",on); if on then absStart() else absStop() end end })
secABS:Slider({ Title="Detection Range",   Step=5,  Value={Min=10,Max=120,Default=abs.range},    Callback=function(v) abs.range=v;    cfg.set("absRange",v); absResizeRings() end })
secABS:Slider({ Title="Look Duration (s)", Step=0.1,Value={Min=0.3,Max=5.0,Default=abs.duration}, Callback=function(v) abs.duration=v; cfg.set("absDur",v)                   end })

------------------------------------------------------------------------
-- KILLER ABILITY CONTROLS
------------------------------------------------------------------------

-- Sixer Air Strafe
local sixerStrafeOn = cfg.get("sixerStrafeOn", false)
local SIXER_BIND    = "LunawareSixerStrafe"
svc.Run:BindToRenderStep(SIXER_BIND, Enum.RenderPriority.Character.Value + 2, function()
    if not sixerStrafeOn then return end
    local char = lp.Character; if not char then return end
    if char:GetAttribute("PursuitState") ~= "Dashing" then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.FloorMaterial ~= Enum.Material.Air then return end
    local cam  = svc.WS.CurrentCamera
    local flat = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
    if flat.Magnitude < 0.01 then return end
    flat = flat.Unit
    local vel   = hrp.AssemblyLinearVelocity
    local hVel  = Vector3.new(vel.X, 0, vel.Z)
    local hSpeed= hVel.Magnitude
    if hSpeed < 0.1 then return end
    local newH = hVel:Lerp(flat * hSpeed, 1)
    hrp.AssemblyLinearVelocity = Vector3.new(newH.X, vel.Y, newH.Z)
end)

-- c00lkidd Dash Turn (WSO)
local coolkidWSOOn = cfg.get("coolkidWSOOn", false)
local function coolkidGetInputDir()
    local cf       = svc.WS.CurrentCamera.CFrame
    local camFwd   = Vector3.new(cf.LookVector.X,  0, cf.LookVector.Z)
    local camRight = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
    local x, z = 0, 0
    if svc.Input:IsKeyDown(Enum.KeyCode.W) or svc.Input:IsKeyDown(Enum.KeyCode.Up)    then z = z - 1 end
    if svc.Input:IsKeyDown(Enum.KeyCode.S) or svc.Input:IsKeyDown(Enum.KeyCode.Down)  then z = z + 1 end
    if svc.Input:IsKeyDown(Enum.KeyCode.A) or svc.Input:IsKeyDown(Enum.KeyCode.Left)  then x = x - 1 end
    if svc.Input:IsKeyDown(Enum.KeyCode.D) or svc.Input:IsKeyDown(Enum.KeyCode.Right) then x = x + 1 end
    local dir = camFwd * -z + camRight * x
    if dir.Magnitude > 0.01 then return dir.Unit end
    if camFwd.Magnitude > 0.01 then return camFwd.Unit end
    return Vector3.new(0, 0, -1)
end
svc.Run.RenderStepped:Connect(function(dt)
    if not coolkidWSOOn then return end
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return end
    if char:GetAttribute("FootstepsMuted") ~= true then return end
    local dir = coolkidGetInputDir()
    local lv  = hrp:FindFirstChildWhichIsA("LinearVelocity")
    if lv then lv.LineDirection = dir end
    if dir.Magnitude > 0.01 then
        local targetRot = CFrame.new(hrp.Position, hrp.Position + dir).Rotation
        hrp.CFrame = CFrame.new(hrp.Position) * hrp.CFrame.Rotation:Lerp(targetRot, math.min(dt * 16, 1))
    end
end)

-- Noli Void Rush
local noliVoidRushOn     = cfg.get("noliVoidRushOn", false)
local noliOverrideActive = false
local noliOrigWalkSpeed  = nil
local noliConn           = nil
local function noliStop()
    if not noliOverrideActive then return end
    noliOverrideActive = false
    local char = lp.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed=noliOrigWalkSpeed or 16; hum.AutoRotate=true; pcall(function() hum:Move(Vector3.new(0,0,0)) end) end
    noliOrigWalkSpeed = nil
    if noliConn then noliConn:Disconnect(); noliConn = nil end
end
local function noliStart()
    if noliOverrideActive then return end
    noliOverrideActive = true
    noliConn = svc.Run.RenderStepped:Connect(function()
        local char = lp.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if not noliOrigWalkSpeed then noliOrigWalkSpeed = hum.WalkSpeed end
        hum.WalkSpeed=60; hum.AutoRotate=false
        local horiz = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        if horiz.Magnitude > 0 then hum:Move(horiz.Unit) end
    end)
end
svc.Run.RenderStepped:Connect(function()
    if not noliVoidRushOn then if noliOverrideActive then noliStop() end; return end
    local char = lp.Character; if not char then return end
    if char:GetAttribute("VoidRushState") == "Dashing" then noliStart() else noliStop() end
end)
lp.CharacterAdded:Connect(function() noliStop(); noliOrigWalkSpeed = nil end)

-- Killer Ability UI
local secKillerAbilities = tabKiller:Section({ Title = "Killer Abilities", Opened = true })
secKillerAbilities:Toggle({ Title="Sixer — Air Strafe",       Type="Checkbox", Default=sixerStrafeOn, Callback=function(on) sixerStrafeOn=on; cfg.set("sixerStrafeOn",on) end })
secKillerAbilities:Toggle({ Title="c00lkidd — Dash Turn",     Type="Checkbox", Default=coolkidWSOOn,  Callback=function(on) coolkidWSOOn=on;  cfg.set("coolkidWSOOn",on)  end })
secKillerAbilities:Toggle({ Title="Noli — Void Rush Control", Type="Checkbox", Default=noliVoidRushOn,Callback=function(on) noliVoidRushOn=on; cfg.set("noliVoidRushOn",on); if not on then noliStop() end end })

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: VISUAL (ESP)
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabVisual = win:Tab({ Title = "Visual", Icon = "eye" })
local secESP    = tabVisual:Section({ Title = "ESP", Opened = true })

local esp = {
    killers    = cfg.get("espKillers",    false),
    survivors  = cfg.get("espSurvivors",  false),
    generators = cfg.get("espGenerators", false),
    items      = cfg.get("espItems",      false),
    buildings  = cfg.get("espBuildings",  false),
    killerFolder=nil, survivorFolder=nil, mapFolder=nil,
    playerConns={}, mapConns={}, healthConns={}, progConns={}, guardConns={}, ready=false,
}

local function espItemColor(name)
    local n = name:lower()
    if n:find("medkit")    then return Color3.fromRGB(0,  255, 200) end
    if n:find("bloxycola") then return Color3.fromRGB(0,  200, 255) end
    return Color3.fromRGB(0, 230, 230)
end

local function espItemHeld(obj)
    for _, plr in ipairs(svc.Players:GetPlayers()) do
        local ch = plr.Character
        if ch and obj:IsDescendantOf(ch) then return true end
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp and obj:IsDescendantOf(bp) then return true end
    end
    return false
end

local espAttach
local espDetach

espAttach = function(obj, tag, color, isChar)
    if not obj or not obj.Parent then return end
    if obj:FindFirstChild(tag) and obj:FindFirstChild(tag.."_bb") then return end
    if esp.guardConns[obj]  then pcall(function() esp.guardConns[obj]:Disconnect()  end); esp.guardConns[obj]  = nil end
    if esp.healthConns[obj] then pcall(function() esp.healthConns[obj]:Disconnect() end); esp.healthConns[obj] = nil end
    if esp.progConns[obj]   then pcall(function() esp.progConns[obj]:Disconnect()   end); esp.progConns[obj]   = nil end
    pcall(function()
        local h = obj:FindFirstChild(tag);        if h then h:Destroy() end
        local b = obj:FindFirstChild(tag.."_bb"); if b then b:Destroy() end
    end)
    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChild("Base") or obj:FindFirstChild("Main")
    if not root then for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then root=d; break end end end
    if not root and obj:IsA("BasePart") then root = obj end
    if not root then return end
    pcall(function()
        local hl = Instance.new("Highlight"); hl.Name=tag; hl.FillColor=color; hl.FillTransparency=0.8; hl.OutlineColor=color; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=obj; hl.Parent=obj
        local bb = Instance.new("BillboardGui"); bb.Name=tag.."_bb"; bb.Adornee=root; bb.Size=UDim2.new(0,100,0,20); bb.StudsOffset=Vector3.new(0,isChar and 3.5 or 3.8,0); bb.AlwaysOnTop=true; bb.MaxDistance=1000; bb.Parent=obj
        local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=color; lbl.TextStrokeTransparency=0.5; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.TextSize=15; lbl.FontFace=Font.new("rbxasset://fonts/families/AccanthisADFStd.json"); lbl.Parent=bb
        if isChar then
            local hum=obj:FindFirstChildOfClass("Humanoid")
            if hum then
                lbl.Text=obj.Name.." (100%)"
                local c=hum.HealthChanged:Connect(function() if lbl.Parent then lbl.Text=obj.Name.." ("..math.floor(hum.Health/hum.MaxHealth*100).."%)"; end end)
                esp.healthConns[obj]=c
            else lbl.Text=obj.Name end
        else
            local prog=obj:FindFirstChild("Progress")
            if prog and prog:IsA("NumberValue") then
                lbl.Text=math.floor(prog.Value).."%"
                local c=prog.Changed:Connect(function() if lbl.Parent then lbl.Text=math.floor(prog.Value).."%" end end)
                esp.progConns[obj]=c
            else lbl.Text=obj.Name end
        end
    end)
    if esp.guardConns[obj] then pcall(function() esp.guardConns[obj]:Disconnect() end) end
    esp.guardConns[obj] = obj.ChildRemoved:Connect(function(removed)
        if removed.Name~=tag and removed.Name~=(tag.."_bb") then return end
        task.defer(function()
            if not obj or not obj.Parent then return end
            if not isChar and espItemHeld(obj) then return end
            espAttach(obj,tag,color,isChar)
        end)
    end)
end

espDetach = function(obj, tag)
    if not obj then return end
    if esp.guardConns[obj] then pcall(function() esp.guardConns[obj]:Disconnect() end); esp.guardConns[obj]=nil end
    pcall(function()
        for _,name in ipairs({tag, tag.."_bb"}) do local c=obj:FindFirstChild(name); if c then c:Destroy() end end
        if esp.healthConns[obj] then esp.healthConns[obj]:Disconnect(); esp.healthConns[obj]=nil end
        if esp.progConns[obj]   then esp.progConns[obj]:Disconnect();   esp.progConns[obj]=nil   end
    end)
end

local function espDoKillers(on)
    if not esp.killerFolder then return end
    for _,k in ipairs(esp.killerFolder:GetChildren()) do if k:IsA("Model") then if on then espAttach(k,"esp_k",Color3.fromRGB(255,0,0),true) else espDetach(k,"esp_k") end end end
end
local function espDoSurvivors(on)
    if not esp.survivorFolder then return end
    for _,s in ipairs(esp.survivorFolder:GetChildren()) do if s:IsA("Model") then if on then espAttach(s,"esp_s",Color3.fromRGB(255,255,0),true) else espDetach(s,"esp_s") end end end
end
local function espDoGenerators(on)
    local map=getMapContent(); if not map then return end
    for _,obj in ipairs(map:GetChildren()) do if obj.Name=="Generator" then if on then espAttach(obj,"esp_g",Color3.fromRGB(255,105,180),false) else espDetach(obj,"esp_g") end end end
end
local function espDoItems(on)
    for _,obj in ipairs(svc.WS:GetDescendants()) do
        if obj.Name=="BloxyCola" or obj.Name=="Medkit" then
            if not espItemHeld(obj) then
                if on then espAttach(obj,"esp_i",espItemColor(obj.Name),false) else espDetach(obj,"esp_i") end
            end
        end
    end
end
local function espDoBuildings(on)
    local ig=getIngame(); if not ig then return end
    for _,obj in ipairs(ig:GetChildren()) do if obj.Name=="BuildermanSentry" or obj.Name=="SubspaceTripmine" or obj.Name=="BuildermanDispenser" then if on then espAttach(obj,"esp_b",Color3.fromRGB(255,80,0),false) else espDetach(obj,"esp_b") end end end
end

local function espBindPlayers()
    for _,c in pairs(esp.playerConns) do if c.Connected then c:Disconnect() end end; esp.playerConns={}
    if esp.killerFolder then
        table.insert(esp.playerConns, esp.killerFolder.ChildAdded:Connect(function(ch) task.wait(0.2); if esp.killers and ch and ch.Parent and ch:IsA("Model") then espAttach(ch,"esp_k",Color3.fromRGB(255,0,0),true) end end))
        table.insert(esp.playerConns, esp.killerFolder.ChildRemoved:Connect(function(ch) espDetach(ch,"esp_k") end))
    end
    if esp.survivorFolder then
        table.insert(esp.playerConns, esp.survivorFolder.ChildAdded:Connect(function(ch) task.wait(0.2); if esp.survivors and ch and ch.Parent and ch:IsA("Model") then espAttach(ch,"esp_s",Color3.fromRGB(255,255,0),true) end end))
        table.insert(esp.playerConns, esp.survivorFolder.ChildRemoved:Connect(function(ch) espDetach(ch,"esp_s") end))
    end
end
local function espBindWorld()
    for _,c in pairs(esp.mapConns) do if c.Connected then c:Disconnect() end end; esp.mapConns={}
    local ig=getIngame(); if not ig then return end
    table.insert(esp.mapConns, ig.ChildAdded:Connect(function(obj)
        task.wait(0.2)
        if esp.buildings and (obj.Name=="BuildermanSentry" or obj.Name=="SubspaceTripmine" or obj.Name=="BuildermanDispenser") then espAttach(obj,"esp_b",Color3.fromRGB(255,80,0),false) end
        if obj.Name=="Map" then
            task.wait(1); esp.mapFolder=obj
            obj.ChildAdded:Connect(function(child) task.wait(0.2); if esp.generators and child.Name=="Generator" then espAttach(child,"esp_g",Color3.fromRGB(255,105,180),false) end end)
            obj.ChildRemoved:Connect(function(child) if child.Name=="Generator" then espDetach(child,"esp_g") end end)
            if esp.generators then task.spawn(function() espDoGenerators(true) end) end
            if esp.items      then task.spawn(function() espDoItems(true) end)      end
        end
    end))
    table.insert(esp.mapConns, ig.ChildRemoved:Connect(function(obj)
        if obj.Name=="BuildermanSentry" or obj.Name=="SubspaceTripmine" then espDetach(obj,"esp_b") end
        if obj.Name=="Map" then esp.mapFolder=nil end
    end))
    table.insert(esp.mapConns, svc.WS.DescendantAdded:Connect(function(obj)
        if not esp.items then return end
        if obj.Name ~= "BloxyCola" and obj.Name ~= "Medkit" then return end
        task.wait(0.2); if obj and obj.Parent and not espItemHeld(obj) then espAttach(obj,"esp_i",espItemColor(obj.Name),false) end
    end))
    local existing=getMapContent(); if existing then esp.mapFolder=existing; task.spawn(function() task.wait(2); if esp.generators then espDoGenerators(true) end; if esp.items then espDoItems(true) end end) end
end

secESP:Toggle({ Title="Killers",    Type="Checkbox", Default=esp.killers,    Callback=function(on) esp.killers=on;    cfg.set("espKillers",on);    task.spawn(function() espDoKillers(on)    end) end })
secESP:Toggle({ Title="Survivors",  Type="Checkbox", Default=esp.survivors,  Callback=function(on) esp.survivors=on;  cfg.set("espSurvivors",on);  task.spawn(function() espDoSurvivors(on)  end) end })
secESP:Toggle({ Title="Generators", Type="Checkbox", Default=esp.generators, Callback=function(on) esp.generators=on; cfg.set("espGenerators",on); task.spawn(function() espDoGenerators(on) end) end })
secESP:Toggle({ Title="Items",      Type="Checkbox", Default=esp.items,      Callback=function(on) esp.items=on;      cfg.set("espItems",on);      task.spawn(function() espDoItems(on)      end) end })
secESP:Toggle({ Title="Buildings",  Type="Checkbox", Default=esp.buildings,  Callback=function(on) esp.buildings=on;  cfg.set("espBuildings",on);  task.spawn(function() espDoBuildings(on)  end) end })

------------------------------------------------------------------------
-- Minion + Puddle ESP
------------------------------------------------------------------------
local secMinion = tabVisual:Section({ Title = "Minion & Ability ESP", Opened = true })
local mset = { pizza=cfg.get("espPizza",false), zombie=cfg.get("espZombie",false), puddle=cfg.get("espPuddle",false), transparency=cfg.get("espMinionTrans",0.25) }
local tracked = { pizza={}, zombie={}, puddle={} }

local function isRealPlayer(obj)
    for _, plr in ipairs(svc.Players:GetPlayers()) do
        if plr.Character == obj then return true end
        if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
    end
    return false
end
local function addHighlight(obj, color, tag, label, offset)
    if not obj or tracked[tag][obj] then return end
    if isRealPlayer(obj) then return end
    tracked[tag][obj] = true
    local root = obj
    if obj:IsA("Model") then
        root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
        if not root then for _, child in ipairs(obj:GetChildren()) do if child:IsA("BasePart") then root=child; break end end end
    end
    local hl = Instance.new("Highlight")
    hl.Name=tag.."_HL"; hl.FillColor=color; hl.FillTransparency=mset.transparency; hl.OutlineColor=color; hl.OutlineTransparency=0.1; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=obj; hl.Parent=obj
    if root then
        local bb = Instance.new("BillboardGui"); bb.Name=tag.."_BB"; bb.Adornee=root; bb.Size=UDim2.new(0,130,0,24); bb.StudsOffset=Vector3.new(0,offset or 3,0); bb.AlwaysOnTop=true; bb.Parent=obj
        local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=color; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.TextStrokeTransparency=0.2; lbl.TextSize=12; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
    end
    local conn; conn = obj.AncestryChanged:Connect(function()
        if obj.Parent then return end; conn:Disconnect(); hl:Destroy()
        local bb=obj:FindFirstChild(tag.."_BB"); if bb then bb:Destroy() end
        tracked[tag][obj] = nil
    end)
end
local function updateTransparency()
    for tag, tbl in pairs(tracked) do for obj in pairs(tbl) do local hl=obj:FindFirstChild(tag.."_HL"); if hl then hl.FillTransparency=mset.transparency end end end
end
local function clearTag(tag)
    for obj in pairs(tracked[tag]) do
        local hl=obj:FindFirstChild(tag.."_HL"); if hl then hl:Destroy() end
        local bb=obj:FindFirstChild(tag.."_BB"); if bb then bb:Destroy() end
        if tag=="puddle" then local h=obj:FindFirstChild("PuddleHolder"); if h then h:Destroy() end end
    end
    tracked[tag]={}
end
local function addPuddleHighlight(part, color, tag, label)
    if not part or tracked[tag][part] then return end
    if isRealPlayer(part) then return end
    tracked[tag][part] = true
    local hl = Instance.new("Highlight")
    hl.Name=tag.."_HL"; hl.FillColor=color; hl.FillTransparency=mset.transparency; hl.OutlineColor=color; hl.OutlineTransparency=0.1; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=part; hl.Parent=part
    task.wait(0.05)
    local puddleSize=math.max(part.Size.X,part.Size.Z); local radius=math.max(puddleSize*0.5,3)
    local holder=Instance.new("Part"); holder.Name="PuddleHolder"; holder.Size=Vector3.new(1,0.1,1); holder.Transparency=1; holder.CanCollide=false; holder.Anchored=true; holder.Position=part.Position+Vector3.new(0,0.05,0); holder.Parent=part
    local blackCircle=Instance.new("CylinderHandleAdornment"); blackCircle.Name="PuddleBlack"; blackCircle.Adornee=holder; blackCircle.Color3=Color3.fromRGB(0,0,0); blackCircle.Transparency=0.2; blackCircle.Radius=radius; blackCircle.Height=0.02; blackCircle.CFrame=CFrame.Angles(math.rad(90),0,0); blackCircle.ZIndex=5; blackCircle.AlwaysOnTop=true; blackCircle.Parent=holder
    local redOutline=Instance.new("CylinderHandleAdornment"); redOutline.Name="PuddleRed"; redOutline.Adornee=holder; redOutline.Color3=Color3.fromRGB(255,0,0); redOutline.Transparency=0.4; redOutline.Radius=radius+0.8; redOutline.Height=0.02; redOutline.CFrame=CFrame.Angles(math.rad(90),0,0); redOutline.ZIndex=4; redOutline.AlwaysOnTop=true; redOutline.Parent=holder
    local bb=Instance.new("BillboardGui"); bb.Name=tag.."_BB"; bb.Adornee=holder; bb.Size=UDim2.new(0,140,0,20); bb.StudsOffset=Vector3.new(0,1.5,0); bb.AlwaysOnTop=true; bb.Parent=holder
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.TextStrokeColor3=Color3.fromRGB(255,0,0); lbl.TextStrokeTransparency=0.1; lbl.TextSize=11; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
    local sizeConn; sizeConn=part:GetPropertyChangedSignal("Size"):Connect(function()
        if not part.Parent then sizeConn:Disconnect(); return end
        local nr=math.max(math.max(part.Size.X,part.Size.Z)*0.5,3); blackCircle.Radius=nr; redOutline.Radius=nr+0.8
    end)
    local conn; conn=part.AncestryChanged:Connect(function()
        if part.Parent then return end; conn:Disconnect()
        pcall(function() sizeConn:Disconnect() end); pcall(function() hl:Destroy() end); pcall(function() holder:Destroy() end)
        tracked[tag][part]=nil
    end)
end
local function isJohnDoePuddle(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.Name ~= "Shadow" then return false end
    local parent = obj.Parent
    return parent and parent.Name:find("Shadows$") ~= nil
end
local function scanPizza()
    if not mset.pizza then return end
    for _,obj in ipairs(svc.WS:GetDescendants()) do if obj.Name=="PizzaDeliveryRig" and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.pizza[obj] then addHighlight(obj,Color3.fromRGB(255,100,0),"pizza","C00LKIDD PIZZA DELIVERY",3) end end
end
local function scanZombie()
    if not mset.zombie then return end
    for _,obj in ipairs(svc.WS:GetDescendants()) do if obj.Name=="1x1x1x1Zombie" and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.zombie[obj] then addHighlight(obj,Color3.fromRGB(80,255,120),"zombie","1X1X1X1 ZOMBIE",3) end end
end
local function scanPuddles()
    if not mset.puddle then return end
    for _,obj in ipairs(svc.WS:GetDescendants()) do if isJohnDoePuddle(obj) and not tracked.puddle[obj] then addPuddleHighlight(obj,Color3.fromRGB(255,50,50),"puddle","JOHN DOE PUDDLE") end end
end
local function setupMinionWatcher()
    svc.WS.DescendantAdded:Connect(function(obj)
        task.wait(0.1); if not obj or not obj.Parent then return end
        if mset.pizza  and obj.Name=="PizzaDeliveryRig"  and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.pizza[obj]  then addHighlight(obj,Color3.fromRGB(255,100,0),"pizza","C00LKIDD PIZZA DELIVERY",3) end
        if mset.zombie and obj.Name=="1x1x1x1Zombie"     and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.zombie[obj] then addHighlight(obj,Color3.fromRGB(80,255,120),"zombie","1X1X1X1 ZOMBIE",3) end
        if mset.puddle and isJohnDoePuddle(obj) and not tracked.puddle[obj] then task.wait(0.15); if obj.Parent then addPuddleHighlight(obj,Color3.fromRGB(255,50,50),"puddle","JOHN DOE PUDDLE") end end
    end)
end

task.spawn(function()
    while true do
        task.wait(3)
        if esp.killers    then task.spawn(function() espDoKillers(true)    end) end
        if esp.survivors  then task.spawn(function() espDoSurvivors(true)  end) end
        if esp.generators then task.spawn(function() espDoGenerators(true) end) end
        if esp.items      then task.spawn(function() espDoItems(true)      end) end
        if esp.buildings  then task.spawn(function() espDoBuildings(true)  end) end
        scanPizza(); scanZombie(); scanPuddles()
    end
end)

task.spawn(function()
    task.wait(3)
    local pf=svc.WS:FindFirstChild("Players")
    if pf then
        esp.killerFolder=pf:FindFirstChild("Killers"); esp.survivorFolder=pf:FindFirstChild("Survivors")
        espBindPlayers()
        if esp.killers   then task.spawn(function() espDoKillers(true)   end) end
        if esp.survivors then task.spawn(function() espDoSurvivors(true) end) end
    end
    espBindWorld()
    if esp.buildings then task.spawn(function() espDoBuildings(true) end) end
    setupMinionWatcher()
    if mset.pizza  then scanPizza()   end
    if mset.zombie then scanZombie()  end
    if mset.puddle then scanPuddles() end
    esp.ready=true
end)

lp.CharacterAdded:Connect(function()
    task.wait(4); espBindPlayers(); espBindWorld()
    if esp.killers    then task.spawn(function() espDoKillers(true)    end) end
    if esp.survivors  then task.spawn(function() espDoSurvivors(true)  end) end
    if esp.generators then task.spawn(function() espDoGenerators(true) end) end
    if esp.items      then task.spawn(function() espDoItems(true)      end) end
    if esp.buildings  then task.spawn(function() espDoBuildings(true)  end) end
    if mset.pizza  then scanPizza()   end
    if mset.zombie then scanZombie()  end
    if mset.puddle then scanPuddles() end
end)

secMinion:Toggle({ Title="c00lkidd Pizza Bots",   Desc="PizzaDeliveryRig — orange highlight", Type="Checkbox", Default=mset.pizza,  Callback=function(on) mset.pizza=on;  cfg.set("espPizza",on);  if on then scanPizza()   else clearTag("pizza")  end end })
secMinion:Toggle({ Title="1x1x1x1 Zombies",       Desc="1x1x1x1Zombie — green highlight",     Type="Checkbox", Default=mset.zombie, Callback=function(on) mset.zombie=on; cfg.set("espZombie",on); if on then scanZombie()  else clearTag("zombie") end end })
secMinion:Toggle({ Title="JD Digital Footprints", Desc="Black disc + red glow",               Type="Checkbox", Default=mset.puddle, Callback=function(on) mset.puddle=on; cfg.set("espPuddle",on); if on then scanPuddles() else clearTag("puddle") end end })
secMinion:Slider({ Title="Highlight Transparency", Step=0.05, Value={Min=0,Max=1,Default=mset.transparency}, Callback=function(v) mset.transparency=v; cfg.set("espMinionTrans",v); updateTransparency() end })
secMinion:Button({ Title="🔄 Force Rescan", Callback=function() clearTag("pizza"); clearTag("zombie"); clearTag("puddle"); task.wait(0.1); scanPizza(); scanZombie(); scanPuddles() end })

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: MUSIC (LMS replacer)
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabMusic = win:Tab({ Title = "Music", Icon = "music" })
local secLMS   = tabMusic:Section({ Title = "LMS Music", Opened = true })

local music = { on=cfg.get("musicOn",false), selected=cfg.get("musicSel","CondemnedLMS"), cached={}, origId=nil, thread=nil }
local musicDir = "GlovSakenScript/LMS_Songs"
if not fs.hasFolder("GlovSakenScript") then fs.makeFolder("GlovSakenScript") end
if not fs.hasFolder(musicDir) then fs.makeFolder(musicDir) end
local musicTracks = {
    ["AbberantLMS"]              = "https://files.catbox.moe/4bb0g9.mp3",
    ["OvertimeLMS"]              = "https://files.catbox.moe/puf7xu.mp3",
    ["PhotoshopLMS"]             = "https://files.catbox.moe/yui8km.mp3",
    ["JX1DX1LMS"]                = "https://files.catbox.moe/52p5yh.mp3",
    ["CondemnedLMS"]             = "https://files.catbox.moe/l470am.mp3",
    ["GeometryLMS"]              = "https://files.catbox.moe/bqzc7u.mp3",
    ["Milestone4LMS"]            = "https://files.catbox.moe/z68ns9.mp3",
    ["BluududLMS"]               = "https://files.catbox.moe/gemz4k.mp3",
    ["JohnDoeLMS"]               = "https://files.catbox.moe/p72236.mp3",
    ["ShedVS1xLMS"]              = "https://files.catbox.moe/0q5v9p.mp3",
    ["EternalIShallEndure"]      = "https://files.catbox.moe/c3ohcm.mp3",
    ["ChanceVSMafiosoLMS"]       = "https://files.catbox.moe/0hlm8m.mp3",
    ["JohnVsJaneLMS"]            = "https://files.catbox.moe/89eqfh.mp3",
    ["SceneSlasherLMS"]          = "https://files.catbox.moe/ap3x4x.mp3",
    ["SynonymsForEternity"]      = "https://files.catbox.moe/uj45ih.mp3",
    ["EternityEpicfied"]         = "https://files.catbox.moe/yrmpvx.mp3",
    ["EternalHopeEternalFight"]  = "https://files.catbox.moe/xdm5q8.mp3",
}
local musicList = {}; for k in pairs(musicTracks) do table.insert(musicList, k) end; table.sort(musicList)
local function musicFetch(name)
    if music.cached[name] then return music.cached[name] end
    local url=musicTracks[name]; if not url then return nil end
    local path=musicDir.."/"..name:gsub("[^%w]","_")..".mp3"
    if not fs.hasFile(path) then local ok,data=pcall(function() return game:HttpGet(url) end); if not ok or not data or #data==0 then return nil end; fs.write(path,data) end
    music.cached[name]=fs.asset(path); return music.cached[name]
end
-- FIX: LastSurvivor sound only exists during a round, not in lobby.
-- Poll for it so musicGetSound() always returns the live instance if present.
local function musicGetSound()
    local t = svc.WS:FindFirstChild("Themes")
    if not t then return nil end
    -- Try direct child first, then deep search in case it's nested
    return t:FindFirstChild("LastSurvivor") or t:FindFirstChild("LastSurvivor", true)
end
local function musicPlay(name)
    local snd=musicGetSound(); if not snd then return false end
    if not music.origId then music.origId=snd.SoundId end
    local asset=musicFetch(name); if not asset then return false end
    snd.SoundId=asset; snd:Stop(); task.wait(); snd:Play(); return true
end
local function musicReset() local snd=musicGetSound(); if snd and music.origId then snd.SoundId=music.origId; snd:Stop(); task.wait(); snd:Play() end end
local function musicIsLMS()
    local sf=getTeamFolder("Survivors")
    if sf then local alive=0; for _,s in ipairs(sf:GetChildren()) do local h=s:FindFirstChildOfClass("Humanoid"); if h and h.Health>0 then alive+=1 end end; if alive==1 then return true end end
    local snd=musicGetSound(); return snd and snd.IsPlaying and (not music.origId or snd.SoundId~=music.origId)
end
local function musicMonitor()
    local i=0
    while music.on and i<2000 do
        i+=1
        if musicIsLMS() then
            local snd=musicGetSound()
            if not snd or not snd.IsPlaying or snd.SoundId~=(music.cached[music.selected] or "") then musicPlay(music.selected) end
            task.wait(3)
        else task.wait(1) end
    end
end
secLMS:Toggle({ Title="Auto-Play on LMS", Type="Checkbox", Default=music.on, Callback=function(on) music.on=on; cfg.set("musicOn",on); if on then music.thread=task.spawn(musicMonitor) else if music.thread then task.cancel(music.thread); music.thread=nil end; musicReset() end end })
secLMS:Dropdown({ Title="Track", Values=musicList, Value=music.selected, Callback=function(sel) music.selected=type(sel)=="table" and sel[1] or sel; cfg.set("musicSel",music.selected); task.spawn(function()musicFetch(music.selected)end) end })
secLMS:Button({ Title="▶  Play",        Callback=function() musicPlay(music.selected) end })
secLMS:Button({ Title="■  Stop",        Callback=function() musicReset() end })
secLMS:Button({ Title="↓  Preload LMS", Callback=function() for name in pairs(musicTracks) do task.spawn(function()musicFetch(name)end); task.wait(0.1) end end })
lp.CharacterAdded:Connect(function() task.wait(3); if music.on then if music.thread then task.cancel(music.thread) end; music.thread=task.spawn(musicMonitor) end end)

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: CHARACTER
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabChar      = win:Tab({ Title = "Character", Icon = "user" })
local secKillers   = tabChar:Section({ Title = "Killers",   Opened = false })
secKillers:Button({ Title="Slasher",   Locked=true, Callback=function() end })
local secSurvivors = tabChar:Section({ Title = "Survivors", Opened = true })
secSurvivors:Button({ Title="Veeronica", Locked=true, Callback=function() end })
local secSentinels = tabChar:Section({ Title = "Sentinels", Opened = true })
secSentinels:Button({ Title="Guest1337",                          Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/Kx5U4bLL"))() end })
secSentinels:Button({ Title="Shedletsky (just use hitbox lol)", Locked=true, Callback=function() end })
secSentinels:Button({ Title="Chance",                             Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/XnXQY5VD"))() end })
secSentinels:Button({ Title="TwoTime",                            Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/4v3iUxhN"))() end })
secSentinels:Button({ Title="Jane Doe",                           Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/YwkMhHE2"))() end })
local secSupports  = tabChar:Section({ Title = "Supports", Opened = false })
secSupports:Button({ Title="Dusekkar", Locked=true, Callback=function() end })
secSupports:Button({ Title="Elliot",               Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/cD2nYPxE"))() end })

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: INTERFACE
------------------------------------------------------------------------
------------------------------------------------------------------------
local tabInterface = win:Tab({ Title = "Interface", Icon = "scan" })
tabInterface:Section({ Title = "UI Functions", Opened = true })

-- FIX: wrap in pcall since WindUI may use Close() or Destroy() depending on version
tabInterface:Button({ Title = "Close UI", Callback = function()
    local ok = pcall(function() win:Destroy() end)
    if not ok then pcall(function() win:Close() end) end
end })

-- Tạo hoặc xóa UI cũ nếu có trùng lặp
local oldGui = game.CoreGui:FindFirstChild("MangzFlyGui") or game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"):FindFirstChild("MangzFlyGui")
if oldGui then oldGui:Destroy() end

-- Khởi tạo các dịch vụ cần thiết
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Biến cấu hình Logic Fly
local flying = false
local flySpeed = 50

local flightConn = nil
local bodyGyro = nil
local bodyVel = nil

-- Hàm xử lý logic Tắt Bay
local function StopFlying()
    flying = false
    if flightConn then flightConn:Disconnect() flightConn = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if bodyVel then bodyVel:Destroy() bodyVel = nil end

    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.AutoRotate = true end
    end
end

-- Hàm xử lý logic Bật Bay (Giữ nguyên logic camera-aligned mượt mà gốc)
local function StartFlying()
    if flying then return end
    flying = true

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoidRootPart then
        humanoid.AutoRotate = false
        
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 90000
        bodyGyro.MaxTorque = Vector3.new(9000000000, 9000000000, 9000000000)
        bodyGyro.CFrame = humanoidRootPart.CFrame
        bodyGyro.Parent = humanoidRootPart

        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000)
        bodyVel.Velocity = Vector3.zero
        bodyVel.Parent = humanoidRootPart

        flightConn = RunService.Heartbeat:Connect(function()
            local currentCamera = workspace.CurrentCamera
            if not currentCamera or not humanoidRootPart or not humanoid then return end
            
            local lookVector = currentCamera.CFrame.LookVector
            local rightVector = currentCamera.CFrame.RightVector
            local moveDirection = humanoid.MoveDirection
            
            local forwardDot = moveDirection:Dot(Vector3.new(lookVector.X, 0, lookVector.Z).Unit)
            local rightDot = moveDirection:Dot(Vector3.new(rightVector.X, 0, rightVector.Z).Unit)
            
            local verticalVelocity = moveDirection.Magnitude <= 0 and 0 or lookVector.Y * forwardDot
            local planarVelocity = lookVector * forwardDot + rightVector * rightDot
            local finalDirection = Vector3.new(planarVelocity.X, verticalVelocity, planarVelocity.Z)

            if finalDirection.Magnitude > 1 then finalDirection = finalDirection.Unit end

            bodyVel.Velocity = finalDirection * flySpeed
            bodyGyro.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + lookVector, currentCamera.CFrame.UpVector)
        end)
    end
end

-- ====== THIẾT KẾ GIAO DIỆN (UI) KHÔNG DÙNG WINDUI ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MangzFlyGui"
-- Đưa vào CoreGui để không bị mất khi chết (hoặc PlayerGui nếu dùng Executor cũ)
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Khung chứa chính (Main Frame)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 140)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, -70)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Cho phép kéo thả GUI trên màn hình
MainFrame.Parent = ScreenGui

-- Bo góc khung chính
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Thanh Tiêu Đề (Title Bar)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TitleLabel.Text = "  Mangz fly"
TitleLabel.TextColor3 = Color3.fromRGB(0, 247, 255) -- Màu neon giống bản gốc
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- Nút Bật/Tắt Bay (Fly Button)
local FlyButton = Instance.new("TextButton")
FlyButton.Name = "FlyButton"
FlyButton.Size = UDim2.new(0, 180, 0, 35)
FlyButton.Position = UDim2.new(0, 20, 0, 50)
FlyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
FlyButton.Text = "Fly: OFF"
FlyButton.TextColor3 = Color3.fromRGB(255, 100, 100)
FlyButton.TextSize = 14
FlyButton.Font = Enum.Font.GothamBold
FlyButton.BorderSizePixel = 0
FlyButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = FlyButton

-- Khung Text chỉnh tốc độ (Speed Label)
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.Size = UDim2.new(0, 90, 0, 30)
SpeedLabel.Position = UDim2.new(0, 20, 0, 95)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Fly Speed:"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 14
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = MainFrame

-- Ô Nhập Số Tốc Độ (Speed TextBox)
local SpeedInput = Instance.new("TextBox")
SpeedInput.Name = "SpeedInput"
SpeedInput.Size = UDim2.new(0, 80, 0, 30)
SpeedInput.Position = UDim2.new(0, 120, 0, 95)
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedInput.Text = tostring(flySpeed)
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.TextSize = 14
SpeedInput.Font = Enum.Font.GothamBold
SpeedInput.BorderSizePixel = 0
SpeedInput.ClipsDescendants = true
SpeedInput.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = SpeedInput

-- Nút Thu Nhỏ / Ẩn GUI (Minimize Button)
local ToggleGuiBtn = Instance.new("TextButton")
ToggleGuiBtn.Name = "ToggleGuiBtn"
ToggleGuiBtn.Size = UDim2.new(0, 30, 0, 30)
ToggleGuiBtn.Position = UDim2.new(1, -35, 0, 2)
ToggleGuiBtn.BackgroundTransparency = 1
ToggleGuiBtn.Text = "-"
ToggleGuiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleGuiBtn.TextSize = 20
ToggleGuiBtn.Font = Enum.Font.GothamBold
ToggleGuiBtn.Parent = MainFrame

-- Xử lý sự kiện bấm nút Fly Button
FlyButton.MouseButton1Click:Connect(function()
    if not flying then
        StartFlying()
        FlyButton.Text = "Fly: ON"
        FlyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        FlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        StopFlying()
        FlyButton.Text = "Fly: OFF"
        FlyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        FlyButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Xử lý sự kiện thay đổi Tốc Độ Bay
SpeedInput.FocusLost:Connect(function(enterPressed)
    local num = tonumber(SpeedInput.Text)
    if num and num > 0 then
        flySpeed = num
    else
        SpeedInput.Text = tostring(flySpeed) -- Reset lại nếu nhập lỗi chữ
    end
end)

-- Xử lý ẩn/hiện menu khi bấm nút "-"
local menuOpen = true
ToggleGuiBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 140), "Out", "Quad", 0.2, true)
        FlyButton.Visible = true
        SpeedLabel.Visible = true
        SpeedInput.Visible = true
        ToggleGuiBtn.Text = "-"
    else
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 35), "Out", "Quad", 0.2, true)
        FlyButton.Visible = false
        SpeedLabel.Visible = false
        SpeedInput.Visible = false
        ToggleGuiBtn.Text = "+"
    end
end)
