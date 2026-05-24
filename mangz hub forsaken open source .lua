print("Mangz loaded (Rayfield Edition)")

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
-- Rayfield UI Library
------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local win = Rayfield:CreateWindow({
    Name = "ᴹᵃⁿᵍᶻ ʰᵘᵇ | ᶠᵒʳˢᵃᵏᵉⁿ ᵛ¹.⁰",
    LoadingTitle = "Mangz Hub Loader",
    LoadingSubtitle = "by Mangz team v1.0",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Mangzhub",
        FileName = "mangzhub_rayfield"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
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
-- TAB: SETTINGS
------------------------------------------------------------------------
local tabSettings = win:CreateTab("Setting", "settings")
local secInterface = tabSettings:CreateSection("Interface")

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

secInterface:CreateToggle({
    Name = "Spoof Usernames",
    CurrentValue = spoofActive,
    Flag = "Toggle_SpoofUsernames",
    Callback = function(on)
        spoofActive = on
        cfg.set("spoofActive", on)
        if on then spoofStart() else spoofStop() end
    end
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

secInterface:CreateToggle({
    Name = "Show Chat Logs",
    CurrentValue = chatForceEnabled,
    Flag = "Toggle_ShowChatLogs",
    Callback = function(on)
        chatForceEnabled = on
        cfg.set("chatForceEnabled", on)
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

secInterface:CreateDropdown({
    Name = "Timer Position",
    Options = { "Middle", "Right" },
    CurrentOption = { timerSide },
    MultipleOptions = false,
    Flag = "Dropdown_TimerPosition",
    Callback = function(v)
        timerSide = v[1] or v
        cfg.set("timerSide", timerSide)
        applyTimerPos()
    end
})

local secPlatform = tabSettings:CreateSection("Platform Spoofer")
local platEnabled = cfg.get("platEnabled", false)
local platDevice  = cfg.get("platDevice",  "Console")
local platLoop    = nil
local platConn    = nil

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

secPlatform:CreateToggle({
    Name = "Enable Spoofer",
    CurrentValue = platEnabled,
    Flag = "Toggle_EnableSpoofer",
    Callback = function(on)
        platEnabled = on
        cfg.set("platEnabled", on)
        if on then platStart() else platStop() end
    end
})

secPlatform:CreateDropdown({
    Name = "Device",
    Options = { "PC", "Mobile", "Console" },
    CurrentOption = { platDevice },
    MultipleOptions = false,
    Flag = "Dropdown_SpoofDevice",
    Callback = function(v)
        platDevice = v[1] or v
        cfg.set("platDevice", platDevice)
        if platEnabled then platPush() end
    end
})

------------------------------------------------------------------------
-- TAB: GLOBAL
------------------------------------------------------------------------
local tabGlobal  = win:CreateTab("Global", "globe")
local secStamina = tabGlobal:CreateSection("Stamina")

local stam = {
    on      = cfg.get("stamOn",      false),
    loss    = cfg.get("stamLoss",    10),
    gain    = cfg.get("stamGain",    20),
    max     = cfg.get("stamMax",     100),
    current = cfg.get("stamCurrent", 100),
    noLoss  = cfg.get("stamNoLoss",  false),
    thread  = nil,
}

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

secStamina:CreateToggle({
    Name = "Custom Stamina 🏃",
    CurrentValue = stam.on,
    Flag = "Toggle_CustomStamina",
    Callback = function(on)
        stam.on = on
        cfg.set("stamOn", on)
        if on then stamStart() else stamStop() end
    end
})

secStamina:CreateSlider({
    Name = "Loss Rate", Min = 0, Max = 50, CurrentValue = stam.loss, Increment = 1, ValueName = "Loss", Flag = "Slider_LossRate",
    Callback = function(v) stam.loss = v; cfg.set("stamLoss", v) end
})
secStamina:CreateSlider({
    Name = "Gain Rate", Min = 0, Max = 200, CurrentValue = stam.gain, Increment = 1, ValueName = "Gain", Flag = "Slider_GainRate",
    Callback = function(v) stam.gain = v; cfg.set("stamGain", v) end
})
secStamina:CreateSlider({
    Name = "Max Pool", Min = 50, Max = 500, CurrentValue = stam.max, Increment = 1, ValueName = "Max", Flag = "Slider_MaxPool",
    Callback = function(v) stam.max = v; cfg.set("stamMax", v) end
})

secStamina:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = stam.noLoss,
    Flag = "Toggle_InfStamina",
    Callback = function(on)
        stam.noLoss = on; cfg.set("stamNoLoss", on); stamApply()
        if on and not stam.on then stam.on = true; stamStart() end
    end
})

local secStatus = tabGlobal:CreateSection("Status")
local statusGroups = {
    Slowness      = { on = false, paths = { "Modules.Schematics.StatusEffects.Slowness" } },
    Hallucination = { on = false, paths = { "Modules.Schematics.StatusEffects.KillerExclusive.Hallucination" } },
    Visual        = { on = false, paths = {
        "Modules.Schematics.StatusEffects.Blindness",
        "Modules.Schematics.StatusEffects.SurvivorExclusive.Subspaced",
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
    local parentPath = saved.parentPath or path:match("^(.-)%.?[^%.]+$")
    local parent = statusResolve(parentPath)
    if parent then
        if not saved.isFolder then saved.clone.Source = saved.src end
        saved.clone.Parent = parent
    end
    statusBackup[path] = nil
end
local function statusToggle(name)
    local g = statusGroups[name]; if not g then return end; g.on = not g.on
    for _, p in ipairs(g.paths) do if g.on then statusBlock(p) else statusRestore(p) end end
end

secStatus:CreateButton({ Name = "Toggle: Slowness", Callback = function() statusToggle("Slowness") end })
secStatus:CreateButton({ Name = "Toggle: Hallucination", Callback = function() statusToggle("Hallucination") end })
secStatus:CreateButton({ Name = "Toggle: Visual Effects", Callback = function() statusToggle("Visual") end })

local secHitbox = tabGlobal:CreateSection("Hitbox")
local hb = { on = cfg.get("hbOn", false), strength = cfg.get("hbStrength", 50), conn = nil, active = {} }
local hbAbilities = { Slash=1,Swing=1,Dagger=1,Charge=1,Punch=1,PlasmaBeam=1,Shoot=1,Behead=1,GashingWound=1,CorruptNature=1,WalkspeedOride=1,Stab=1,Nova=1,MassInfection=1,Entanglement=1,Axe=1 }

local function hbReadName(raw)
    if typeof(raw) == "buffer" then local s = buffer.tostring(raw); return s:match("[%a]+") or s:gsub("[^%w]","") end
    return tostring(raw):gsub(""","")
end
local function hbPush(dist)
    local ch = lp.Character; if not ch then return end
    local r  = ch:FindFirstChild("HumanoidRootPart"); if not r then return end
    local was = r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity = was + r.CFrame.LookVector * dist
    svc.Run.RenderStepped:Wait()
    if ch and ch.Parent and r and r.Parent then r.AssemblyLinearVelocity = was end
end

local _hbRemote = nil
local function hbGetRemote()
    if _hbRemote and _hbRemote.Parent then return _hbRemote end
    local ok, re = pcall(function() return svc.RS.Modules.Network.Network:FindFirstChild("RemoteEvent") end)
    if ok and re then _hbRemote = re; return re end
    return nil
end

local function hbStart()
    if hb.conn then return end
    local remote = hbGetRemote()
    if not remote then return end
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

secHitbox:CreateToggle({
    Name = "Hitbox Expander🎯",
    CurrentValue = hb.on,
    Flag = "Toggle_HitboxExpander",
    Callback = function(on)
        hb.on = on
        cfg.set("hbOn", on)
        if on then hbStart() else hbStop() end
    end
})

secHitbox:CreateSlider({
    Name = "Strength", Min = 5, Max = 450, CurrentValue = hb.strength, Increment = 1, ValueName = "Studs", Flag = "Slider_HitboxStrength",
    Callback = function(v) hb.strength = v; cfg.set("hbStrength", v) end
})

------------------------------------------------------------------------
-- TAB: GENERATOR
------------------------------------------------------------------------
local tabGen     = win:CreateTab("Generator", "circuit-board")
local secGenAuto = tabGen:CreateSection("Auto Solve")

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
    for _, ep in ipairs(endpoints or {}) do
        for _, n in ipairs(path) do if n.row == ep.row and n.col == ep.col then start = { row = ep.row, col = ep.col }; break end end
        if start then break end
    end
    if not start then
        for _, n in ipairs(path) do
            local nb = 0
            for _, d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do if lookup[(n.row+d[1]).."-"..(n.col+d[2])] then nb += 1 end end
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
    local indices = {}
    for i = 1, #puzzle.Solution do indices[i] = i end
    for i = #indices, 2, -1 do local j = math.random(1, i); indices[i], indices[j] = indices[j], indices[i] end
    for _, ci in ipairs(indices) do
        local solution = puzzle.Solution[ci]
        if not solution then continue end
        local ordered = flowOrder(solution, puzzle.targetPairs[ci])
        if not ordered or #ordered == 0 then continue end
        puzzle.paths[ci] = {}
        for _, node in ipairs(ordered) do
            table.insert(puzzle.paths[ci], { row = node.row, col = node.col })
            puzzle:updateGui()
            task.wait(flow.nodeDelay)
        end
        task.wait(flow.lineDelay)
        puzzle:checkForWin()
    end
end

secGenAuto:CreateToggle({
    Name = "Auto Solve", CurrentValue = flow.on, Flag = "Toggle_AutoSolve",
    Callback = function(on) flow.on = on; cfg.set("flowOn", on) end
})
secGenAuto:CreateSlider({
    Name = "Node Speed", Min = 0.01, Max = 0.50, CurrentValue = flow.nodeDelay, Increment = 0.01, ValueName = "Secs", Flag = "Slider_NodeSpeed",
    Callback = function(v) flow.nodeDelay = v; cfg.set("flowNodeDelay", v) end
})

------------------------------------------------------------------------
-- TAB: KILLER
------------------------------------------------------------------------
local tabKiller = win:CreateTab("Killer", "crosshair")
local secAimbot = tabKiller:CreateSection("Aimbot")

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

secAimbot:CreateToggle({
    Name = "Enable Aimbot", CurrentValue = aim.on, Flag = "Toggle_EnableAimbot",
    Callback = function(on) aim.on=on; cfg.set("aimOn",on); if not on then aimUnlock() end end
})
secAimbot:CreateSlider({
    Name = "Max Distance", Min = 5, Max = 100, CurrentValue = aim.maxDist, Increment = 5, ValueName = "Studs", Flag = "Slider_AimMaxDist",
    Callback = function(v) aim.maxDist=v; cfg.set("aimMaxDist",v)   end
})

local secKillerAbilities = tabKiller:CreateSection("Killer Abilities")
local sixerStrafeOn = cfg.get("sixerStrafeOn", false)
local coolkidWSOOn = cfg.get("coolkidWSOOn", false)

secKillerAbilities:CreateToggle({
    Name = "Sixer — Air Strafe", CurrentValue = sixerStrafeOn, Flag = "Toggle_SixerStrafe",
    Callback = function(on) sixerStrafeOn=on; cfg.set("sixerStrafeOn",on) end
})
secKillerAbilities:CreateToggle({
    Name = "c00lkidd — Dash Turn", CurrentValue = coolkidWSOOn, Flag = "Toggle_CoolkidWSO",
    Callback = function(on) coolkidWSOOn=on; cfg.set("coolkidWSOOn",on) end
})

-- Hoàn tất đóng gói toàn bộ tính năng và khởi chạy
Rayfield:Notify({
    Title = "Mangz Hub Loaded!",
    Content = "Chuyển giao diện Rayfield thành công cho Gà nhé!",
    Duration = 5,
    Image = 4483362458,
})
