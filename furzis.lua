-- palofsc // gelişmiş UI sistemi
-- aimlock + esp için tam kontrol paneli
-- teknik yorumlar // Rusça

local config = {
    aimlock_enabled = true,
    aimlock_key = Enum.KeyCode.E,
    aimlock_smoothness = 0.15,
    aimlock_fov = 120,
    aimlock_part = "UpperTorso",
    aimlock_visible_check = false,
    aimlock_team_check = false,
    esp_enabled = true,
    esp_color = Color3.fromRGB(255, 0, 0),
    esp_fill = true,
    esp_health = true,
    esp_name = true,
    esp_distance = true,
    esp_box = false,
    esp_tracer = false,
    esp_skeleton = false,
    ui_keybind = Enum.KeyCode.RightShift,
    ui_visible = true,
    ui_theme = "dark"
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local esp_folder = Instance.new("Folder")
esp_folder.Name = "palofsc_esp"
esp_folder.Parent = workspace

local esp_cache = {}

local function create_esp(player)
    if player == LocalPlayer then return end
    if esp_cache[player] then return end
    local esp = {}
    local highlight = Instance.new("Highlight")
    highlight.Name = "palofsc_highlight"
    highlight.Adornee = player.Character
    highlight.FillColor = config.esp_color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = config.esp_fill and 0.5 or 1
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = esp_folder
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "palofsc_billboard"
    billboard.Adornee = player.Character and player.Character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = esp_folder
    local name_label = Instance.new("TextLabel")
    name_label.Name = "name"
    name_label.Size = UDim2.new(1, 0, 0.4, 0)
    name_label.BackgroundTransparency = 1
    name_label.TextColor3 = Color3.fromRGB(255, 255, 255)
    name_label.TextStrokeTransparency = 0
    name_label.TextScaled = true
    name_label.Font = Enum.Font.Code
    name_label.Text = player.Name
    name_label.Parent = billboard
    local info_label = Instance.new("TextLabel")
    info_label.Name = "info"
    info_label.Size = UDim2.new(1, 0, 0.3, 0)
    info_label.Position = UDim2.new(0, 0, 0.4, 0)
    info_label.BackgroundTransparency = 1
    info_label.TextColor3 = Color3.fromRGB(0, 255, 0)
    info_label.TextStrokeTransparency = 0
    info_label.TextScaled = true
    info_label.Font = Enum.Font.Code
    info_label.Text = ""
    info_label.Parent = billboard
    local health_bar_bg = Instance.new("Frame")
    health_bar_bg.Name = "health_bg"
    health_bar_bg.Size = UDim2.new(0.8, 0, 0.15, 0)
    health_bar_bg.Position = UDim2.new(0.1, 0, 0.75, 0)
    health_bar_bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    health_bar_bg.BorderSizePixel = 0
    health_bar_bg.Parent = billboard
    local health_bar = Instance.new("Frame")
    health_bar.Name = "health"
    health_bar.Size = UDim2.new(1, 0, 1, 0)
    health_bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    health_bar.BorderSizePixel = 0
    health_bar.Parent = health_bar_bg
    local box = Instance.new("SelectionBox")
    box.Name = "palofsc_box"
    box.Adornee = player.Character
    box.Color3 = config.esp_color
    box.LineThickness = 0.05
    box.Transparency = 1
    box.Parent = esp_folder
    local tracer = Instance.new("LineHandleAdornment")
    tracer.Name = "palofsc_tracer"
    tracer.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    tracer.Color3 = config.esp_color
    tracer.Thickness = 2
    tracer.Transparency = 1
    tracer.AlwaysOnTop = true
    tracer.Parent = esp_folder
    esp.highlight = highlight
    esp.billboard = billboard
    esp.name_label = name_label
    esp.info_label = info_label
    esp.health_bar = health_bar
    esp.health_bar_bg = health_bar_bg
    esp.box = box
    esp.tracer = tracer
    esp_cache[player] = esp
end

local function remove_esp(player)
    if esp_cache[player] then
        for _, v in pairs(esp_cache[player]) do
            if typeof(v) == "Instance" then
                v:Destroy()
            end
        end
        esp_cache[player] = nil
    end
end

local function update_esp()
    for player, esp in pairs(esp_cache) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if esp.highlight then
                esp.highlight.Adornee = char
                esp.highlight.FillColor = config.esp_color
                esp.highlight.FillTransparency = config.esp_fill and 0.5 or 1
                esp.highlight.Enabled = config.esp_enabled
            end
            if esp.billboard then
                esp.billboard.Adornee = head
                esp.billboard.Enabled = config.esp_enabled and config.esp_name
            end
            if humanoid and esp.info_label then
                local distance = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                local health = math.floor(humanoid.Health)
                local max_health = math.floor(humanoid.MaxHealth)
                local health_percent = health / max_health
                local text = ""
                if config.esp_health then
                    text = text .. "HP: " .. health .. "/" .. max_health
                end
                if config.esp_distance then
                    text = text .. " | " .. distance .. "m"
                end
                esp.info_label.Text = text
                esp.info_label.Visible = config.esp_health or config.esp_distance
                if esp.health_bar then
                    esp.health_bar.Size = UDim2.new(health_percent, 0, 1, 0)
                    esp.health_bar.BackgroundColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - health_percent)),
                        math.floor(255 * health_percent),
                        0
                    )
                    esp.health_bar.Visible = config.esp_health
                    esp.health_bar_bg.Visible = config.esp_health
                end
            end
            if esp.box then
                esp.box.Adornee = char
                esp.box.Color3 = config.esp_color
                esp.box.Transparency = config.esp_box and 0 or 1
            end
            if esp.tracer then
                esp.tracer.Adornee = hrp
                esp.tracer.Color3 = config.esp_color
                esp.tracer.Transparency = config.esp_tracer and 0.5 or 1
                esp.tracer.Visible = config.esp_tracer
            end
        end
    end
end

local aimlock_target = nil
local aimlock_active = false
local aimlock_circle = nil

local function create_fov_circle()
    if aimlock_circle then aimlock_circle:Destroy() end
    local circle = Instance.new("Frame")
    circle.Name = "fov_circle"
    circle.Size = UDim2.new(0, config.aimlock_fov * 2, 0, config.aimlock_fov * 2)
    circle.Position = UDim2.new(0.5, -config.aimlock_fov, 0.5, -config.aimlock_fov)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = screen_gui
    local circle_ui = Instance.new("UICorner")
    circle_ui.CornerRadius = UDim.new(1, 0)
    circle_ui.Parent = circle
    local circle_stroke = Instance.new("UIStroke")
    circle_stroke.Color = Color3.fromRGB(255, 255, 255)
    circle_stroke.Thickness = 1
    circle_stroke.Transparency = 0.5
    circle_stroke.Parent = circle
    aimlock_circle = circle
end

local function get_closest_player()
    local closest = nil
    local shortest_distance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local target_part = char:FindFirstChild(config.aimlock_part) or hrp
            if hrp and humanoid and humanoid.Health > 0 and target_part then
                if config.aimlock_visible_check then
                    local ray = Ray.new(Camera.CFrame.Position, (target_part.Position - Camera.CFrame.Position).Unit * 500)
                    local hit, pos = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                    if hit and not hit:IsDescendantOf(char) then
                        continue
                    end
                end
                if config.aimlock_team_check then
                    if player.Team == LocalPlayer.Team then
                        continue
                    end
                end
                local screen_pos, on_screen = Camera:WorldToViewportPoint(target_part.Position)
                if on_screen then
                    local mouse_pos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screen_pos.X, screen_pos.Y) - mouse_pos).Magnitude
                    if distance < config.aimlock_fov and distance < shortest_distance then
                        shortest_distance = distance
                        closest = target_part
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if config.esp_enabled then
        update_esp()
    end
    if config.aimlock_enabled and aimlock_active and aimlock_target then
        if aimlock_target.Parent and aimlock_target.Parent:FindFirstChildOfClass("Humanoid") and aimlock_target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
            local target_pos = aimlock_target.Position
            local camera_pos = Camera.CFrame.Position
            local direction = (target_pos - camera_pos).Unit
            local new_cframe = CFrame.new(camera_pos, camera_pos + direction)
            Camera.CFrame = Camera.CFrame:Lerp(new_cframe, 1 - config.aimlock_smoothness)
        else
            aimlock_target = nil
        end
    end
    if aimlock_circle then
        aimlock_circle.Visible = config.aimlock_enabled and config.ui_visible
        aimlock_circle.Size = UDim2.new(0, config.aimlock_fov * 2, 0, config.aimlock_fov * 2)
        aimlock_circle.Position = UDim2.new(0.5, -config.aimlock_fov, 0.5, -config.aimlock_fov)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if config.esp_enabled then
            create_esp(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    remove_esp(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            create_esp(player)
        end
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if config.esp_enabled then
                create_esp(player)
            end
        end)
    end
end

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "palofsc_ui"
screen_gui.ResetOnSpawn = false
screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen_gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

create_fov_circle()

local main_frame = Instance.new("Frame")
main_frame.Name = "main_frame"
main_frame.Size = UDim2.new(0, 420, 0, 520)
main_frame.Position = UDim2.new(0, 50, 0, 50)
main_frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main_frame.BorderSizePixel = 0
main_frame.Active = true
main_frame.Draggable = true
main_frame.Parent = screen_gui

local main_corner = Instance.new("UICorner")
main_corner.CornerRadius = UDim.new(0, 8)
main_corner.Parent = main_frame

local main_stroke = Instance.new("UIStroke")
main_stroke.Color = Color3.fromRGB(60, 60, 80)
main_stroke.Thickness = 1
main_stroke.Parent = main_frame

local title_bar = Instance.new("Frame")
title_bar.Name = "title_bar"
title_bar.Size = UDim2.new(1, 0, 0, 35)
title_bar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title_bar.BorderSizePixel = 0
title_bar.Parent = main_frame

local title_corner = Instance.new("UICorner")
title_corner.CornerRadius = UDim.new(0, 8)
title_corner.Parent = title_bar

local title_label = Instance.new("TextLabel")
title_label.Size = UDim2.new(1, -60, 1, 0)
title_label.Position = UDim2.new(0, 10, 0, 0)
title_label.BackgroundTransparency = 1
title_label.Text = "palofsc // aimlock + esp"
title_label.TextColor3 = Color3.fromRGB(200, 200, 255)
title_label.Font = Enum.Font.Code
title_label.TextSize = 16
title_label.TextXAlignment = Enum.TextXAlignment.Left
title_label.Parent = title_bar

local close_btn = Instance.new("TextButton")
close_btn.Size = UDim2.new(0, 25, 0, 25)
close_btn.Position = UDim2.new(1, -30, 0, 5)
close_btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close_btn.BorderSizePixel = 0
close_btn.Text = "X"
close_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
close_btn.Font = Enum.Font.Code
close_btn.TextSize = 14
close_btn.Parent = title_bar

local close_corner = Instance.new("UICorner")
close_corner.CornerRadius = UDim.new(0, 4)
close_corner.Parent = close_btn

close_btn.MouseButton1Click:Connect(function()
    main_frame.Visible = false
end)

local tab_frame = Instance.new("Frame")
tab_frame.Name = "tab_frame"
tab_frame.Size = UDim2.new(1, -20, 0, 30)
tab_frame.Position = UDim2.new(0, 10, 0, 45)
tab_frame.BackgroundTransparency = 1
tab_frame.Parent = main_frame

local aimlock_tab = Instance.new("TextButton")
aimlock_tab.Size = UDim2.new(0.5, -5, 1, 0)
aimlock_tab.Position = UDim2.new(0, 0, 0, 0)
aimlock_tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
aimlock_tab.BorderSizePixel = 0
aimlock_tab.Text = "AIMLOCK"
aimlock_tab.TextColor3 = Color3.fromRGB(200, 200, 255)
aimlock_tab.Font = Enum.Font.Code
aimlock_tab.TextSize = 14
aimlock_tab.Parent = tab_frame

local aimlock_tab_corner = Instance.new("UICorner")
aimlock_tab_corner.CornerRadius = UDim.new(0, 4)
aimlock_tab_corner.Parent = aimlock_tab

local esp_tab = Instance.new("TextButton")
esp_tab.Size = UDim2.new(0.5, -5, 1, 0)
esp_tab.Position = UDim2.new(0.5, 5, 0, 0)
esp_tab.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
esp_tab.BorderSizePixel = 0
esp_tab.Text = "ESP"
esp_tab.TextColor3 = Color3.fromRGB(150, 150, 180)
esp_tab.Font = Enum.Font.Code
esp_tab.TextSize = 14
esp_tab.Parent = tab_frame

local esp_tab_corner = Instance.new("UICorner")
esp_tab_corner.CornerRadius = UDim.new(0, 4)
esp_tab_corner.Parent = esp_tab

local content_frame = Instance.new("Frame")
content_frame.Name = "content_frame"
content_frame.Size = UDim2.new(1, -20, 1, -130)
content_frame.Position = UDim2.new(0, 10, 0, 85)
content_frame.BackgroundTransparency = 1
content_frame.Parent = main_frame

local aimlock_page = Instance.new("ScrollingFrame")
aimlock_page.Name = "aimlock_page"
aimlock_page.Size = UDim2.new(1, 0, 1, 0)
aimlock_page.BackgroundTransparency = 1
aimlock_page.BorderSizePixel = 0
aimlock_page.ScrollBarThickness = 4
aimlock_page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
aimlock_page.Parent = content_frame

local aimlock_layout = Instance.new("UIListLayout")
aimlock_layout.Padding = UDim.new(0, 8)
aimlock_layout.Parent = aimlock_page

local esp_page = Instance.new("ScrollingFrame")
esp_page.Name = "esp_page"
esp_page.Size = UDim2.new(1, 0, 1, 0)
esp_page.BackgroundTransparency = 1
esp_page.BorderSizePixel = 0
esp_page.ScrollBarThickness = 4
esp_page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
esp_page.Visible = false
esp_page.Parent = content_frame

local esp_layout = Instance.new("UIListLayout")
esp_layout.Padding = UDim.new(0, 8)
esp_layout.Parent = esp_page

aimlock_tab.MouseButton1Click:Connect(function()
    aimlock_page.Visible = true
    esp_page.Visible = false
    aimlock_tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    aimlock_tab.TextColor3 = Color3.fromRGB(200, 200, 255)
    esp_tab.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    esp_tab.TextColor3 = Color3.fromRGB(150, 150, 180)
end)

esp_tab.MouseButton1Click:Connect(function()
    aimlock_page.Visible = false
    esp_page.Visible = true
    esp_tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    esp_tab.TextColor3 = Color3.fromRGB(200, 200, 255)
    aimlock_tab.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    aimlock_tab.TextColor3 = Color3.fromRGB(150, 150, 180)
end)

local function create_toggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local toggle_bg = Instance.new("Frame")
    toggle_bg.Size = UDim2.new(0, 40, 0, 20)
    toggle_bg.Position = UDim2.new(1, -50, 0.5, -10)
    toggle_bg.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 80)
    toggle_bg.BorderSizePixel = 0
    toggle_bg.Parent = frame
    local toggle_corner = Instance.new("UICorner")
    toggle_corner.CornerRadius = UDim.new(1, 0)
    toggle_corner.Parent = toggle_bg
    local toggle_circle = Instance.new("Frame")
    toggle_circle.Size = UDim2.new(0, 16, 0, 16)
    toggle_circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggle_circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggle_circle.BorderSizePixel = 0
    toggle_circle.Parent = toggle_bg
    local circle_corner = Instance.new("UICorner")
    circle_corner.CornerRadius = UDim.new(1, 0)
    circle_corner.Parent = toggle_circle
    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        state = not state
        toggle_bg.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 80)
        TweenService:Create(toggle_circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        callback(state)
    end)
    return frame
end

local function create_slider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local slider_bg = Instance.new("Frame")
    slider_bg.Size = UDim2.new(1, -20, 0, 8)
    slider_bg.Position = UDim2.new(0, 10, 0, 30)
    slider_bg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    slider_bg.BorderSizePixel = 0
    slider_bg.Parent = frame
    local slider_corner = Instance.new("UICorner")
    slider_corner.CornerRadius = UDim.new(1, 0)
    slider_corner.Parent = slider_bg
    local slider_fill = Instance.new("Frame")
    slider_fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    slider_fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    slider_fill.BorderSizePixel = 0
    slider_fill.Parent = slider_bg
    local fill_corner = Instance.new("UICorner")
    fill_corner.CornerRadius = UDim.new(1, 0)
    fill_corner.Parent = slider_fill
    local slider_btn = Instance.new("TextButton")
    slider_btn.Size = UDim2.new(1, 0, 1, 0)
    slider_btn.BackgroundTransparency = 1
    slider_btn.Text = ""
    slider_btn.Parent = slider_bg
    local dragging = false
    slider_btn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse_pos = UserInputService:GetMouseLocation()
            local slider_pos = slider_bg.AbsolutePosition
            local slider_size = slider_bg.AbsoluteSize
            local relative = math.clamp((mouse_pos.X - slider_pos.X) / slider_size.X, 0, 1)
            local value = min + (max - min) * relative
            slider_fill.Size = UDim2.new(relative, 0, 1, 0)
            label.Text = text .. ": " .. math.floor(value * 100) / 100
            callback(value)
        end
    end)
    return frame
end

local function create_dropdown(parent, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local value_btn = Instance.new("TextButton")
    value_btn.Size = UDim2.new(0.4, 0, 1, -8)
    value_btn.Position = UDim2.new(0.55, 0, 0, 4)
    value_btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    value_btn.BorderSizePixel = 0
    value_btn.Text = default
    value_btn.TextColor3 = Color3.fromRGB(200, 200, 255)
    value_btn.Font = Enum.Font.Code
    value_btn.TextSize = 12
    value_btn.Parent = frame
    local value_corner = Instance.new("UICorner")
    value_corner.CornerRadius = UDim.new(0, 4)
    value_corner.Parent = value_btn
    local current_index = 1
    for i, v in ipairs(options) do
        if v == default then current_index = i break end
    end
    value_btn.MouseButton1Click:Connect(function()
        current_index = current_index + 1
        if current_index > #options then current_index = 1 end
        value_btn.Text = options[current_index]
        callback(options[current_index])
    end)
    return frame
end

local function create_keybind(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local key_btn = Instance.new("TextButton")
    key_btn.Size = UDim2.new(0.3, 0, 1, -8)
    key_btn.Position = UDim2.new(0.65, 0, 0, 4)
    key_btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    key_btn.BorderSizePixel = 0
    key_btn.Text = default.Name
    key_btn.TextColor3 = Color3.fromRGB(200, 200, 255)
    key_btn.Font = Enum.Font.Code
    key_btn.TextSize = 12
    key_btn.Parent = frame
    local key_corner = Instance.new("UICorner")
    key_corner.CornerRadius = UDim.new(0, 4)
    key_corner.Parent = key_btn
    local waiting = false
    key_btn.MouseButton1Click:Connect(function()
        waiting = true
        key_btn.Text = "..."
    end)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if waiting and not gameProcessed then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                waiting = false
                key_btn.Text = input.KeyCode.Name
                callback(input.KeyCode)
            end
        end
    end)
    return frame
end

create_toggle(aimlock_page, "Aimlock Aktif", config.aimlock_enabled, function(v)
    config.aimlock_enabled = v
end)

create_keybind(aimlock_page, "Aimlock Tuşu", config.aimlock_key, function(v)
    config.aimlock_key = v
end)

create_slider(aimlock_page, "Hız (Düşük=Hızlı)", 0.01, 1.0, config.aimlock_smoothness, function(v)
    config.aimlock_smoothness = v
end)

create_slider(aimlock_page, "FOV", 10, 500, config.aimlock_fov, function(v)
    config.aimlock_fov = v
end)

create_dropdown(aimlock_page, "Hedef Bölge", {"UpperTorso", "HumanoidRootPart", "Head", "LowerTorso"}, config.aimlock_part, function(v)
    config.aimlock_part = v
end)

create_toggle(aimlock_page, "Görünürlük Kontrolü", config.aimlock_visible_check, function(v)
    config.aimlock_visible_check = v
end)

create_toggle(aimlock_page, "Takım Kontrolü", config.aimlock_team_check, function(v)
    config.aimlock_team_check = v
end)

create_toggle(esp_page, "ESP Aktif", config.esp_enabled, function(v)
    config.esp_enabled = v
end)

create_toggle(esp_page, "Highlight", config.esp_fill, function(v)
    config.esp_fill = v
end)

create_toggle(esp_page, "İsim Göster", config.esp_name, function(v)
    config.esp_name = v
end)

create_toggle(esp_page, "Mesafe Göster", config.esp_distance, function(v)
    config.esp_distance = v
end)

create_toggle(esp_page, "Can Barı", config.esp_health, function(v)
    config.esp_health = v
end)

create_toggle(esp_page, "Box ESP", config.esp_box, function(v)
    config.esp_box = v
end)

create_toggle(esp_page, "Tracer", config.esp_tracer, function(v)
    config.esp_tracer = v
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == config.aimlock_key then
        aimlock_active = true
        aimlock_target = get_closest_player()
    end
    if input.KeyCode == config.ui_keybind then
        config.ui_visible = not config.ui_visible
        main_frame.Visible = config.ui_visible
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == config.aimlock_key then
        aimlock_active = false
        aimlock_target = nil
    end
end)
