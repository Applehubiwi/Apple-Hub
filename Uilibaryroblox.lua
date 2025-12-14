--================================--
--        TOHA UI LIB             --
--================================--

local TohaUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- MAKE WINDOW
function TohaUI:MakeWindow(config)
    local Window = {}
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    -- UI HOLDER
    local holder = Instance.new("ScreenGui")
    holder.Name = "TohaUIHolder"
    holder.Parent = player:WaitForChild("PlayerGui")
    holder.ResetOnSpawn = false

    -- MAIN
    local main = Instance.new("Frame", holder)
    main.Size = UDim2.fromScale(0.32, 0.42)
    main.Position = UDim2.fromScale(0.34, 0.27)
    main.BackgroundColor3 = Color3.fromRGB(25,25,25)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Visible = true

    Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)

    -- TITLE
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1,0,0,42)
    title.BackgroundTransparency = 1
    title.Text = config.Name or "Toha Hub"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = Color3.new(1,1,1)

    -- TAB BAR
    local tabs = Instance.new("Frame", main)
    tabs.Position = UDim2.new(0,0,0,42)
    tabs.Size = UDim2.new(0.28,0,1,-42)
    tabs.BackgroundColor3 = Color3.fromRGB(30,30,30)
    tabs.BorderSizePixel = 0

    -- CONTENT
    local content = Instance.new("Frame", main)
    content.Position = UDim2.new(0.28,0,0,42)
    content.Size = UDim2.new(0.72,0,1,-42)
    content.BackgroundTransparency = 1

    local tabLayout = Instance.new("UIListLayout", tabs)

    -- TOGGLE UI (KEY)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            main.Visible = not main.Visible
        end
    end)

    -- TAB FUNCTION
    function Window:MakeTab(tabConfig)
        local Tab = {}

        local tabButton = Instance.new("TextButton", tabs)
        tabButton.Size = UDim2.new(1,0,0,40)
        tabButton.Text = tabConfig.Name or "Tab"
        tabButton.Font = Enum.Font.Gotham
        tabButton.TextSize = 15
        tabButton.TextColor3 = Color3.new(1,1,1)
        tabButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
        tabButton.BorderSizePixel = 0

        local tabFrame = Instance.new("ScrollingFrame", content)
        tabFrame.Size = UDim2.new(1,0,1,0)
        tabFrame.Visible = false
        tabFrame.CanvasSize = UDim2.new(0,0,0,0)
        tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabFrame.ScrollBarImageTransparency = 0.4
        tabFrame.BackgroundTransparency = 1

        local layout = Instance.new("UIListLayout", tabFrame)
        layout.Padding = UDim.new(0,8)

        tabButton.MouseButton1Click:Connect(function()
            for _,v in pairs(content:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            tabFrame.Visible = true
        end)

        -- BUTTON
        function Tab:AddButton(btn)
            local b = Instance.new("TextButton", tabFrame)
            b.Size = UDim2.new(1,-10,0,40)
            b.Text = btn.Name or "Button"
            b.Font = Enum.Font.Gotham
            b.TextSize = 15
            b.TextColor3 = Color3.new(1,1,1)
            b.BackgroundColor3 = Color3.fromRGB(45,45,45)
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)

            b.MouseButton1Click:Connect(function()
                if btn.Callback then btn.Callback() end
            end)
        end

        -- TOGGLE
        function Tab:AddToggle(tog)
            local state = tog.Default or false

            local t = Instance.new("TextButton", tabFrame)
            t.Size = UDim2.new(1,-10,0,40)
            t.Text = (tog.Name or "Toggle") .. ": " .. (state and "ON" or "OFF")
            t.Font = Enum.Font.Gotham
            t.TextSize = 15
            t.TextColor3 = Color3.new(1,1,1)
            t.BackgroundColor3 = Color3.fromRGB(45,45,45)
            t.BorderSizePixel = 0
            Instance.new("UICorner", t).CornerRadius = UDim.new(0,10)

            t.MouseButton1Click:Connect(function()
                state = not state
                t.Text = tog.Name .. ": " .. (state and "ON" or "OFF")
                if tog.Callback then tog.Callback(state) end
            end)
        end

        return Tab
    end

    return Window
end

return TohaUI
