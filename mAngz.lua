– Mangz ULTRA MAX UI LIB (FULL)

if not game:IsLoaded() then game.Loaded:Wait() end

local CoreGui = game:GetService(“CoreGui”) local UIS =
game:GetService(“UserInputService”) local TweenService =
game:GetService(“TweenService”) local HttpService =
game:GetService(“HttpService”)

local Library = {} local Config = {} local SaveFile = “mangz_config.txt”

function Library:CreateWindow(cfg) local gui = Instance.new(“ScreenGui”,
CoreGui) gui.Name = “MangzUltra” gui.ResetOnSpawn = false

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0,520,0,320)
    main.Position = UDim2.new(0.5,-260,0.5,-160)
    main.BackgroundColor3 = Color3.fromRGB(18,18,18)

    local top = Instance.new("Frame", main)
    top.Size = UDim2.new(1,0,0,50)
    top.BackgroundColor3 = Color3.fromRGB(12,12,12)

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1,0,0,25)
    title.BackgroundTransparency = 1
    title.Text = cfg.Name or "Mangz Hub"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true

    local sub = Instance.new("TextLabel", top)
    sub.Size = UDim2.new(1,0,0,20)
    sub.Position = UDim2.new(0,0,0,25)
    sub.BackgroundTransparency = 1
    sub.Text = cfg.Subtitle or ""
    sub.TextColor3 = Color3.fromRGB(170,170,170)
    sub.TextScaled = true

    -- DRAG
    local dragging, dragInput, startPos, startFramePos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = input.Position
            startFramePos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    top.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startPos
            main.Position = UDim2.new(
                startFramePos.X.Scale,
                startFramePos.X.Offset + delta.X,
                startFramePos.Y.Scale,
                startFramePos.Y.Offset + delta.Y
            )
        end
    end)

    local window = {}
    local container = Instance.new("Frame", main)
    container.Size = UDim2.new(1,0,1,-50)
    container.Position = UDim2.new(0,0,0,50)
    container.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0,6)

    function window:AddButton(cfg)
        local b = Instance.new("TextButton", container)
        b.Size = UDim2.new(1,-10,0,35)
        b.Text = cfg.Name
        b.BackgroundColor3 = Color3.fromRGB(40,40,40)
        b.TextColor3 = Color3.new(1,1,1)

        b.MouseButton1Click:Connect(function()
            if cfg.Callback then cfg.Callback() end
        end)
    end

    function window:AddToggle(cfg)
        local state = false
        Config[cfg.Name] = state

        local t = Instance.new("TextButton", container)
        t.Size = UDim2.new(1,-10,0,35)
        t.Text = cfg.Name.." : OFF"
        t.BackgroundColor3 = Color3.fromRGB(40,40,40)
        t.TextColor3 = Color3.new(1,1,1)

        t.MouseButton1Click:Connect(function()
            state = not state
            Config[cfg.Name] = state
            t.Text = cfg.Name.." : "..(state and "ON" or "OFF")
            if cfg.Callback then cfg.Callback(state) end
        end)
    end

    function window:AddSlider(cfg)
        local val = cfg.Default or 0
        Config[cfg.Name] = val

        local frame = Instance.new("Frame", container)
        frame.Size = UDim2.new(1,-10,0,50)
        frame.BackgroundColor3 = Color3.fromRGB(40,40,40)

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1,0,0,20)
        label.BackgroundTransparency = 1
        label.Text = cfg.Name.." : "..val
        label.TextColor3 = Color3.new(1,1,1)

        local bar = Instance.new("Frame", frame)
        bar.Size = UDim2.new(1,-10,0,10)
        bar.Position = UDim2.new(0,5,0,30)
        bar.BackgroundColor3 = Color3.fromRGB(60,60,60)

        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new((val-cfg.Min)/(cfg.Max-cfg.Min),0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(0,170,255)

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local function move(input)
                    local pos = (input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X
                    pos = math.clamp(pos,0,1)
                    fill.Size = UDim2.new(pos,0,1,0)
                    val = math.floor(cfg.Min + (cfg.Max-cfg.Min)*pos)
                    Config[cfg.Name] = val
                    label.Text = cfg.Name.." : "..val
                    if cfg.Callback then cfg.Callback(val) end
                end
                move(input)
                local conn
                conn = UIS.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement then
                        move(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        conn:Disconnect()
                    end
                end)
            end
        end)
    end

    function window:AddDropdown(cfg)
        local current = cfg.Options[1]
        Config[cfg.Name] = current

        local b = Instance.new("TextButton", container)
        b.Size = UDim2.new(1,-10,0,35)
        b.Text = cfg.Name.." : "..current
        b.BackgroundColor3 = Color3.fromRGB(40,40,40)
        b.TextColor3 = Color3.new(1,1,1)

        b.MouseButton1Click:Connect(function()
            current = cfg.Options[math.random(1,#cfg.Options)]
            Config[cfg.Name] = current
            b.Text = cfg.Name.." : "..current
            if cfg.Callback then cfg.Callback(current) end
        end)
    end

    function window:Save()
        writefile(SaveFile, HttpService:JSONEncode(Config))
    end

    function window:Load()
        if isfile(SaveFile) then
            Config = HttpService:JSONDecode(readfile(SaveFile))
            print("Config Loaded")
        end
    end

    return window

end

return Library
