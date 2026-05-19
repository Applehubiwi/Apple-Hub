--// new_laui.lua
--// Simple Custom UI Library
--// Mobile + PC Drag Support

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local NewLAUI = {}
NewLAUI.__index = NewLAUI

local ConfigFolder = "NewLAUIConfigs"

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

local function Create(Class, Props)
    local Obj = Instance.new(Class)

    for i,v in pairs(Props or {}) do
        Obj[i] = v
    end

    return Obj
end

local function MakeDraggable(Frame, DragFrame)
    DragFrame = DragFrame or Frame

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function Update(input)
        local delta = input.Position - dragStart

        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    DragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    DragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            Update(input)
        end
    end)
end

function NewLAUI:CreateWindow(Settings)
    local WindowName = Settings.Name or "NewLAUI"

    local ScreenGui = Create("ScreenGui", {
        Name = "NewLAUI_" .. WindowName,
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false
    })

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0, 650, 0, 450),
        Position = UDim2.new(0.5, -325, 0.5, -225),
        BackgroundColor3 = Color3.fromRGB(20,20,20),
        BorderSizePixel = 0
    })

    local Corner = Create("UICorner", {
        Parent = Main,
        CornerRadius = UDim.new(0,12)
    })

    local TopBar = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0
    })

    Create("UICorner", {
        Parent = TopBar,
        CornerRadius = UDim.new(0,12)
    })

    local Title = Create("TextLabel", {
        Parent = TopBar,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = WindowName,
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBold,
        TextSize = 18
    })

    local TabsHolder = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(0,150,1,-40),
        Position = UDim2.new(0,0,0,40),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0
    })

    local TabsLayout = Create("UIListLayout", {
        Parent = TabsHolder,
        Padding = UDim.new(0,5)
    })

    local ContentHolder = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1,-160,1,-50),
        Position = UDim2.new(0,155,0,45),
        BackgroundTransparency = 1
    })

    --// Floating Toggle UI
    local FloatingToggle = Create("TextButton", {
        Parent = ScreenGui,
        Size = UDim2.new(0,50,0,50),
        Position = UDim2.new(0,20,0.5,0),
        BackgroundColor3 = Color3.fromRGB(40,40,40),
        Text = ">",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBold,
        TextSize = 20
    })

    Create("UICorner", {
        Parent = FloatingToggle,
        CornerRadius = UDim.new(1,0)
    })

    MakeDraggable(Main, TopBar)
    MakeDraggable(FloatingToggle)

    FloatingToggle.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible

        if Main.Visible then
            FloatingToggle.Text = ">"
        else
            FloatingToggle.Text = "<"
        end
    end)

    --// Floating Toggle UI is draggable on both PC and Mobile

    local Window = {}
    Window.Tabs = {}
    Window.Flags = {}

    function Window:Notify(Settings)
        local Notification = Create("Frame", {
            Parent = ScreenGui,
            Size = UDim2.new(0,250,0,70),
            Position = UDim2.new(1,-270,1,-90),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            BorderSizePixel = 0
        })

        Create("UICorner", {
            Parent = Notification,
            CornerRadius = UDim.new(0,10)
        })

        local Text = Create("TextLabel", {
            Parent = Notification,
            Size = UDim2.new(1,-10,1,-10),
            Position = UDim2.new(0,5,0,5),
            BackgroundTransparency = 1,
            TextWrapped = true,
            Text = (Settings.Title or "Notification") .. "\n" .. (Settings.Content or ""),
            Font = Enum.Font.Gotham,
            TextColor3 = Color3.new(1,1,1),
            TextSize = 14
        })

        task.delay(Settings.Time or 3,function()
            Notification:Destroy()
        end)
    end

    function Window:SaveConfig(Name)
        local Data = HttpService:JSONEncode(Window.Flags)
        writefile(ConfigFolder .. "/" .. Name .. ".json", Data)
    end

    function Window:LoadConfig(Name)
        local Path = ConfigFolder .. "/" .. Name .. ".json"

        if isfile(Path) then
            local Data = HttpService:JSONDecode(readfile(Path))

            for i,v in pairs(Data) do
                Window.Flags[i] = v
            end
        end
    end

    function Window:DeleteConfig(Name)
        local Path = ConfigFolder .. "/" .. Name .. ".json"

        if isfile(Path) then
            delfile(Path)
        end
    end

    function Window:GetConfigs()
        return listfiles(ConfigFolder)
    end

    function Window:AddTab(Name)
        local TabButton = Create("TextButton", {
            Parent = TabsHolder,
            Size = UDim2.new(1,-10,0,35),
            BackgroundColor3 = Color3.fromRGB(35,35,35),
            Text = Name,
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.GothamBold,
            TextSize = 14
        })

        Create("UICorner", {
            Parent = TabButton,
            CornerRadius = UDim.new(0,8)
        })

        local TabFrame = Create("ScrollingFrame", {
            Parent = ContentHolder,
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarThickness = 4
        })

        local Layout = Create("UIListLayout", {
            Parent = TabFrame,
            Padding = UDim.new(0,6)
        })

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabFrame.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y + 10)
        end)

        if #Window.Tabs == 0 then
            TabFrame.Visible = true
        end

        table.insert(Window.Tabs, TabFrame)

        TabButton.MouseButton1Click:Connect(function()
            for _,v in pairs(Window.Tabs) do
                v.Visible = false
            end

            TabFrame.Visible = true
        end)

        local Tab = {}

        function Tab:AddSection(Name)
            local Section = Create("TextLabel", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,30),
                BackgroundColor3 = Color3.fromRGB(30,30,30),
                Text = Name,
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 16
            })

            Create("UICorner", {
                Parent = Section,
                CornerRadius = UDim.new(0,8)
            })
        end

        function Tab:AddLabel(Text)
            local Label = Create("TextLabel", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,30),
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                Text = Text,
                Font = Enum.Font.Gotham,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = Label,
                CornerRadius = UDim.new(0,8)
            })
        end

        function Tab:AddButton(Settings)
            local Button = Create("TextButton", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,35),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = Settings.Name or "Button",
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = Button,
                CornerRadius = UDim.new(0,8)
            })

            Button.MouseButton1Click:Connect(function()
                if Settings.Callback then
                    Settings.Callback()
                end
            end)
        end

        function Tab:AddToggle(Settings)
            local Enabled = Settings.Default or false

            Window.Flags[Settings.Name] = Enabled

            local Toggle = Create("TextButton", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,35),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = Settings.Name .. " : " .. tostring(Enabled),
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = Toggle,
                CornerRadius = UDim.new(0,8)
            })

            Toggle.MouseButton1Click:Connect(function()
                Enabled = not Enabled
                Window.Flags[Settings.Name] = Enabled

                Toggle.Text = Settings.Name .. " : " .. tostring(Enabled)

                if Settings.Callback then
                    Settings.Callback(Enabled)
                end
            end)
        end

        function Tab:AddTextbox(Settings)
            local Box = Create("TextBox", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,35),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                PlaceholderText = Settings.Placeholder or "Enter text...",
                Text = "",
                Font = Enum.Font.Gotham,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = Box,
                CornerRadius = UDim.new(0,8)
            })

            Box.FocusLost:Connect(function()
                if Settings.Callback then
                    Settings.Callback(Box.Text)
                end
            end)
        end

        function Tab:AddSlider(Settings)
            local Min = Settings.Min or 0
            local Max = Settings.Max or 100
            local Current = Settings.Default or Min

            local SliderButton = Create("TextButton", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,35),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = Settings.Name .. " : " .. tostring(Current),
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = SliderButton,
                CornerRadius = UDim.new(0,8)
            })

            SliderButton.MouseButton1Click:Connect(function()
                Current += 1

                if Current > Max then
                    Current = Min
                end

                SliderButton.Text = Settings.Name .. " : " .. tostring(Current)

                if Settings.Callback then
                    Settings.Callback(Current)
                end
            end)
        end

        function Tab:AddDropdown(Settings)
            local Dropdown = Create("TextButton", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,35),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = Settings.Name or "Dropdown",
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = Dropdown,
                CornerRadius = UDim.new(0,8)
            })

            local Index = 1
            local Options = Settings.Options or {}

            Dropdown.MouseButton1Click:Connect(function()
                if #Options <= 0 then
                    return
                end

                Index += 1

                if Index > #Options then
                    Index = 1
                end

                local Selected = Options[Index]

                Dropdown.Text = Settings.Name .. " : " .. Selected

                if Settings.Callback then
                    Settings.Callback(Selected)
                end
            end)
        end

        function Tab:AddMultiDropdown(Settings)
            local Selected = {}

            local Multi = Create("TextButton", {
                Parent = TabFrame,
                Size = UDim2.new(1,-5,0,35),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = Settings.Name or "Multi Dropdown",
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14
            })

            Create("UICorner", {
                Parent = Multi,
                CornerRadius = UDim.new(0,8)
            })

            local Options = Settings.Options or {}
            local Index = 1

            Multi.MouseButton1Click:Connect(function()
                if #Options <= 0 then
                    return
                end

                local Option = Options[Index]

                table.insert(Selected, Option)

                Multi.Text = table.concat(Selected, ", ")

                if Settings.Callback then
                    Settings.Callback(Selected)
                end

                Index += 1

                if Index > #Options then
                    Index = 1
                end
            end)
        end

        return Tab
    end

    return Window
end

return NewLAUI