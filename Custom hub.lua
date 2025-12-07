--[[
    ████ MY CUSTOM KAVO UI REMAKE ████
    Features:
    - Tabs
    - Sections
    - Buttons
    - Toggles
    - Sliders
    - Dropdown
    - Keybind
    - Notifications
    - Drag mobile + PC
    - Themes
]]

local MyLibrary = {}

local Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 25),
        Topbar = Color3.fromRGB(40, 40, 40),
        Secondary = Color3.fromRGB(50, 50, 50),
        Text = Color3.fromRGB(255, 255, 255)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Topbar = Color3.fromRGB(200, 200, 200),
        Secondary = Color3.fromRGB(220, 220, 220),
        Text = Color3.fromRGB(0, 0, 0)
    },
    Grape = {
        Background = Color3.fromRGB(45, 0, 60),
        Topbar = Color3.fromRGB(70, 0, 90),
        Secondary = Color3.fromRGB(85, 0, 110),
        Text = Color3.fromRGB(255, 255, 255)
    },
    Midnight = {
        Background = Color3.fromRGB(10, 10, 15),
        Topbar = Color3.fromRGB(20, 20, 35),
        Secondary = Color3.fromRGB(40, 40, 55),
        Text = Color3.fromRGB(255, 255, 255)
    }
}

---------------------------------------------------------------------
-- CREATE LIB
---------------------------------------------------------------------
function MyLibrary.CreateLib(title, themeName)
    local theme = Themes[themeName] or Themes.Dark

    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "MyCustomKavoUI"

    -- Main Frame
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 520, 0, 350)
    Main.Position = UDim2.new(0.3, 0, 0.25, 0)
    Main.BackgroundColor3 = theme.Background
    Main.BorderSizePixel = 0

    ---------------------------------------------------------------------
    -- DRAG SUPPORT (PC + Mobile)
    ---------------------------------------------------------------------
    local UIS = game:GetService("UserInputService")
    local dragging, dragStart, startPos, dragInput

    local function update(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y)
    end

    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    ---------------------------------------------------------------------
    -- TOPBAR
    ---------------------------------------------------------------------
    local Topbar = Instance.new("Frame", Main)
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    Topbar.BackgroundColor3 = theme.Topbar
    Topbar.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", Topbar)
    Title.Size = UDim2.new(1, -10, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.TextColor3 = theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left

    ---------------------------------------------------------------------
    -- Tab system
    ---------------------------------------------------------------------
    local TabFrame = Instance.new("Frame", Main)
    TabFrame.Size = UDim2.new(0, 130, 1, -40)
    TabFrame.Position = UDim2.new(0, 0, 0, 40)
    TabFrame.BackgroundColor3 = theme.Secondary
    TabFrame.BorderSizePixel = 0

    local TabLayout = Instance.new("UIListLayout", TabFrame)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 5)

    local Pages = Instance.new("Folder", Main)

    local Window = {}

    ---------------------------------------------------------------------
    -- NEW TAB
    ---------------------------------------------------------------------
    function Window:NewTab(name)
        local TabButton = Instance.new("TextButton", TabFrame)
        TabButton.Size = UDim2.new(1, -10, 0, 40)
        TabButton.BackgroundColor3 = theme.Background
        TabButton.Text = name
        TabButton.TextColor3 = theme.Text
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 16

        local Page = Instance.new("ScrollingFrame", Pages)
        Page.Size = UDim2.new(1, -130, 1, -40)
        Page.Position = UDim2.new(0, 130, 0, 40)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 4
        Page.Visible = false
        Page.BackgroundColor3 = theme.Background
        Page.BorderSizePixel = 0

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, page in ipairs(Pages:GetChildren()) do
                page.Visible = false
            end
            Page.Visible = true
        end)

        local Tab = {}

        ---------------------------------------------------------------------
        -- NEW SECTION
        ---------------------------------------------------------------------
        function Tab:NewSection(text)
            local Section = Instance.new("Frame", Page)
            Section.Size = UDim2.new(1, -10, 0, 40)
            Section.BackgroundColor3 = theme.Topbar
            Section.BorderSizePixel = 0

            local Label = Instance.new("TextLabel", Section)
            Label.Size = UDim2.new(1, -10, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.Font = Enum.Font.GothamBold
            Label.TextSize = 18
            Label.TextColor3 = theme.Text
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SectionObj = {}

            ---------------------------------------------------------------------
            -- BUTTON
            ---------------------------------------------------------------------
            function SectionObj:NewButton(text, callback)
                local Btn = Instance.new("TextButton", Page)
                Btn.Size = UDim2.new(1, -10, 0, 40)
                Btn.BackgroundColor3 = theme.Secondary
                Btn.Text = text
                Btn.Font = Enum.Font.Gotham
                Btn.TextColor3 = theme.Text

                Btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
            end

            ---------------------------------------------------------------------
            -- TOGGLE
            ---------------------------------------------------------------------
            function SectionObj:NewToggle(text, callback)
                local Frame = Instance.new("Frame", Page)
                Frame.Size = UDim2.new(1, -10, 0, 40)
                Frame.BackgroundColor3 = theme.Secondary

                local Label = Instance.new("TextLabel", Frame)
                Label.Text = text
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.Size = UDim2.new(0.8, 0, 1, 0)
                Label.BackgroundTransparency = 1
                Label.Font = Enum.Font.Gotham
                Label.TextColor3 = theme.Text

                local Toggle = Instance.new("TextButton", Frame)
                Toggle.Size = UDim2.new(0.2, -10, 0.8, 0)
                Toggle.Position = UDim2.new(0.8, 0, 0.1, 0)
                Toggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                Toggle.Text = "OFF"
                Toggle.Font = Enum.Font.GothamBold
                Toggle.TextColor3 = theme.Text

                local state = false

                Toggle.MouseButton1Click:Connect(function()
                    state = not state
                    if state then
                        Toggle.Text = "ON"
                        Toggle.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
                    else
                        Toggle.Text = "OFF"
                        Toggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                    end
                    pcall(callback, state)
                end)
            end

            ---------------------------------------------------------------------
            -- SLIDER
            ---------------------------------------------------------------------
            function SectionObj:NewSlider(text, min, max, callback)
                local Frame = Instance.new("Frame", Page)
                Frame.Size = UDim2.new(1, -10, 0, 55)
                Frame.BackgroundColor3 = theme.Secondary

                local Label = Instance.new("TextLabel", Frame)
                Label.Text = text
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.Size = UDim2.new(1, -20, 0, 20)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = theme.Text

                local Bar = Instance.new("Frame", Frame)
                Bar.Position = UDim2.new(0, 10, 0, 30)
                Bar.Size = UDim2.new(1, -20, 0, 10)
                Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

                local Fill = Instance.new("Frame", Bar)
                Fill.Size = UDim2.new(0, 0, 1, 0)
                Fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)

                Bar.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        local pct = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        Fill.Size = UDim2.new(pct, 0, 1, 0)
                        pcall(callback, math.floor(min + (max - min) * pct))
                    end
                end)
            end

            ---------------------------------------------------------------------
            -- DROPDOWN
            ---------------------------------------------------------------------
            function SectionObj:NewDropdown(text, list, callback)
                local Btn = Instance.new("TextButton", Page)
                Btn.Size = UDim2.new(1, -10, 0, 40)
                Btn.BackgroundColor3 = theme.Secondary
                Btn.Text = text
                Btn.Font = Enum.Font.Gotham
                Btn.TextColor3 = theme.Text

                Btn.MouseButton1Click:Connect(function()
                    for _, item in ipairs(list) do
                        local Option = Instance.new("TextButton", Page)
                        Option.Size = UDim2.new(1, -20, 0, 35)
                        Option.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                        Option.Text = item
                        Option.TextColor3 = theme.Text
                        Option.Font = Enum.Font.Gotham

                        Option.MouseButton1Click:Connect(function()
                            pcall(callback, item)
                        end)
                    end
                end)
            end

            ---------------------------------------------------------------------
            -- KEYBIND
            ---------------------------------------------------------------------
            function SectionObj:NewKeybind(text, callback)
                local Btn = Instance.new("TextButton", Page)
                Btn.Size = UDim2.new(1, -10, 0, 40)
                Btn.BackgroundColor3 = theme.Secondary
                Btn.TextColor3 = theme.Text
                Btn.Font = Enum.Font.GothamBold
                Btn.TextSize = 16
                Btn.Text = text .. ": Press a key"

                Btn.MouseButton1Click:Connect(function()
                    Btn.Text = text .. ": ..."

                    local connection
                    connection = UIS.InputBegan:Connect(function(key)
                        Btn.Text = text .. ": " .. key.KeyCode.Name
                        pcall(callback, key.KeyCode)
                        connection:Disconnect()
                    end)
                end)
            end

            return SectionObj
        end

        return Tab
    end

    ---------------------------------------------------------------------
    -- NOTIFICATION
    ---------------------------------------------------------------------
    function Window:Notify(title, msg)
        local Notify = Instance.new("Frame", Main)
        Notify.Size = UDim2.new(0, 300, 0, 70)
        Notify.Position = UDim2.new(1, -310, 0, 10)
        Notify.BackgroundColor3 = theme.Topbar

        local L1 = Instance.new("TextLabel", Notify)
        L1.Size = UDim2.new(1, 0, 0.4, 0)
        L1.Text = title
        L1.Font = Enum.Font.GothamBold
        L1.TextColor3 = theme.Text
        L1.BackgroundTransparency = 1

        local L2 = Instance.new("TextLabel", Notify)
        L2.Size = UDim2.new(1, 0, 0.6, 0)
        L2.Position = UDim2.new(0, 0, 0.4, 0)
        L2.Text = msg
        L2.Font = Enum.Font.Gotham
        L2.TextColor3 = theme.Text
        L2.BackgroundTransparency = 1

        task.wait(2)
        Notify:Destroy()
    end

    return Window
end

return MyLibrary
