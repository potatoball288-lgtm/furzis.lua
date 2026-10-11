-- palofsc // hood mod v4
-- speed fix + yeni esp sistemi (box, corner, health, isim, mesafe)
-- teknik yorumlar // Rusça

local config = {
    -- aimlock
    aimlock_enabled = true,
    aimlock_key = Enum.KeyCode.E,
    aimlock_smoothness = 0.12,
    aimlock_fov = 120,
    aimlock_part = "UpperTorso",
    aimlock_visible_check = false,
    aimlock_team_check = false,
    -- silent aim
    silent_enabled = false,
    silent_key = Enum.KeyCode.Q,
    silent_fov = 90,
    silent_part = "Head",
    silent_visible_check = false,
    silent_team_check = false,
    -- esp
    esp_enabled = true,
    esp_color = Color3.fromRGB(255, 0, 0),
    esp_fill = true,
    esp_outline = true,
    esp_health = true,
    esp_name = true,
    esp_distance = true,
    esp_box = true,
    esp_corner = false,
    esp_tracer = false,
    esp_max_distance = 1000,
    esp_team_color = false,
    -- speed
    speed_enabled = false,
    speed_key = Enum.KeyCode.LeftControl,
    speed_value = 50,
    speed_toggle_mode = true,
    -- ui
    ui_keybind = Enum.KeyCode.RightShift,
    ui_visible = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================
-- ESP SİSTEMİ v2
-- ============================================
local esp_folder = Instance.new("Folder")
esp_folder.Name = "palofsc_esp"
esp_folder.Parent = workspace
local esp_cache = {}

-- çizim kütüphanesi
local Drawing = Drawing or nil

local function create_esp(player)
    if player == LocalPlayer then return end
    if esp_cache[player] then return end

    local esp = {}

    -- highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "palofsc_highlight"
    highlight.Adornee = player.Character
    highlight.FillColor = config.esp_color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = config.esp_fill and 0.5 or 1
    highlight.OutlineTransparency = config.esp_outline and 0 or 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = esp_folder

    -- billboard (isim + mesafe + can)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "palofsc_billboard"
    billboard.Adornee = player.Character and player.Character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 200, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = esp_folder

    local name_label = Instance.new("TextLabel")
    name_label.Name = "name"
    name_label.Size = UDim2.new(1, 0, 0.35, 0)
    name_label.BackgroundTransparency = 1
    name_label.TextColor3 = Color3.fromRGB(255, 255, 255)
    name_label.TextStrokeTransparency = 0
    name_label.TextScaled = true
    name_label.Font = Enum.Font.Code
    name_label.Text = player.Name
    name_label.Parent = billboard

    local info_label = Instance.new("TextLabel")
    info_label.Name = "info"
    info_label.Size = UDim2.new(1, 0, 0.25, 0)
    info_label.Position = UDim2.new(0, 0, 0.35, 0)
    info_label.BackgroundTransparency = 1
    info_label.TextColor3 = Color3.fromRGB(0, 255, 0)
    info_label.TextStrokeTransparency = 0
    info_label.TextScaled = true
    info_label.Font = Enum.Font.Code
    info_label.Text = ""
    info_label.Parent = billboard

    local health_bar_bg = Instance.new("Frame")
    health_bar_bg.Name = "health_bg"
    health_bar_bg.Size = UDim2.new(0.8, 0, 0.12, 0)
    health_bar_bg.Position = UDim2.new(0.1, 0, 0.68, 0)
    health_bar_bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    health_bar_bg.BorderSizePixel = 0
    health_bar_bg.Parent = billboard

    local health_bar = Instance.new("Frame")
    health_bar.Name = "health"
    health_bar.Size = UDim2.new(1, 0, 1, 0)
    health_bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    health_bar.BorderSizePixel = 0
    health_bar.Parent = health_bar_bg

    -- box esp (SelectionBox)
    local box = Instance.new("SelectionBox")
    box.Name = "palofsc_box"
    box.Adornee = player.Character
    box.Color3 = config.esp_color
    box.LineThickness = 0.05
    box.Transparency = 1
    box.Parent = esp_folder

    -- tracer
    local tracer = Instance.new("LineHandleAdornment")
    tracer.Name = "palofsc_tracer"
    tracer.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    tracer.Color3 = config.esp_color
    tracer.Thickness = 2
    tracer.Transparency = 1
    tracer.AlwaysOnTop = true
    tracer.Parent = esp_folder

    -- corner box (Drawing)
    local corner_lines = {}
    if Drawing then
        for i = 1, 8 do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = config.esp_color
            line.Thickness = 1
            line.Transparency = 1
            corner_lines[i] = line
        end
    end

    esp.highlight = highlight
    esp.billboard = billboard
    esp.name_label = name_label
    esp.info_label = info_label
    esp.health_bar = health_bar
    esp.health_bar_bg = health_bar_bg
    esp.box = box
    esp.tracer = tracer
    esp.corner_lines = corner_lines

    esp_cache[player] = esp
end

local function remove_esp(player)
    if esp_cache[player] then
        for _, v in pairs(esp_cache[player]) do
            if typeof(v) == "Instance" then
                v:Destroy()
            elseif typeof(v) == "table" then
                for _, line in pairs(v) do
                    if line and line.Remove then line:Remove() end
                end
            end
        end
        esp_cache[player] = nil
    end
end

-- corner box çizimi
local function update_corner_box(esp, char)
    if not Drawing or not esp.corner_lines or #esp.corner_lines == 0 then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then
        for _, line in pairs(esp.corner_lines) do line.Visible = false end
        return
    end

    local top = head.Position + Vector3.new(0, 0.6, 0)
    local bottom = hrp.Position - Vector3.new(0, 3, 0)

    local top_screen, top_on = Camera:WorldToViewportPoint(top)
    local bottom_screen, bottom_on = Camera:WorldToViewportPoint(bottom)

    if not top_on or not bottom_on then
        for _, line in pairs(esp.corner_lines) do line.Visible = false end
        return
    end

    local height = math.abs(bottom_screen.Y - top_screen.Y)
    local width = height * 0.55
    local x = top_screen.X - width / 2
    local y = top_screen.Y

    local corner_size = math.min(width, height) * 0.25

    -- 8 çizgi: 4 köşe, her köşe 2 çizgi
    local lines = esp.corner_lines
    -- sol üst
    lines[1].From = Vector2.new(x, y)
    lines[1].To = Vector2.new(x + corner_size, y)
    lines[2].From = Vector2.new(x, y)
    lines[2].To = Vector2.new(x, y + corner_size)
    -- sağ üst
    lines[3].From = Vector2.new(x + width, y)
    lines[3].To = Vector2.new(x + width - corner_size, y)
    lines[4].From = Vector2.new(x + width, y)
    lines[4].To = Vector2.new(x + width, y + corner_size)
    -- sol alt
    lines[5].From = Vector2.new(x, y + height)
    lines[5].To = Vector2.new(x + corner_size, y + height)
    lines[6].From = Vector2.new(x, y + height)
    lines[6].To = Vector2.new(x, y + height - corner_size)
    -- sağ alt
    lines[7].From = Vector2.new(x + width, y + height)
    lines[7].To = Vector2.new(x + width - corner_size, y + height)
    lines[8].From = Vector2.new(x + width, y + height)
    lines[8].To = Vector2.new(x + width, y + height - corner_size)

    for _, line in pairs(lines) do
        line.Visible = config.esp_corner
        line.Color = config.esp_color
    end
end

local function update_esp()
    for player, esp in pairs(esp_cache) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            local visible = distance <= config.esp_max_distance

            local color = config.esp_color
            if config.esp_team_color and player.Team then
                color = player.TeamColor.Color
            end

            if esp.highlight then
                esp.highlight.Adornee = char
                esp.highlight.FillColor = color
                esp.highlight.FillTransparency = config.esp_fill and 0.5 or 1
                esp.highlight.OutlineTransparency = config.esp_outline and 0 or 1
                esp.highlight.Enabled = config.esp_enabled and visible
            end

            if esp.billboard then
                esp.billboard.Adornee = head
                esp.billboard.Enabled = config.esp_enabled and (config.esp_name or config.esp_health or config.esp_distance) and visible
            end

            if humanoid and esp.info_label then
                local health = math.floor(humanoid.Health)
                local max_health = math.floor(humanoid.MaxHealth)
                local health_percent = health / max_health
                local text = ""
                if config.esp_health then text = text .. "HP: " .. health .. "/" .. max_health end
                if config.esp_distance then
                    if text ~= "" then text = text .. " | " end
                    text = text .. math.floor(distance) .. "m"
                end
                esp.info_label.Text = text
                esp.info_label.Visible = (config.esp_health or config.esp_distance) and visible
                esp.name_label.Visible = config.esp_name and visible
                if esp.health_bar then
                    esp.health_bar.Size = UDim2.new(health_percent, 0, 1, 0)
                    esp.health_bar.BackgroundColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - health_percent)),
                        math.floor(255 * health_percent),
                        0
                    )
                    esp.health_bar.Visible = config.esp_health and visible
                    esp.health_bar_bg.Visible = config.esp_health and visible
                end
            end

            if esp.box then
                esp.box.Adornee = char
                esp.box.Color3 = color
                esp.box.Transparency = (config.esp_box and visible) and 0 or 1
            end

            if esp.tracer then
                esp.tracer.Adornee = hrp
                esp.tracer.Color3 = color
                esp.tracer.Transparency = (config.esp_tracer and visible) and 0.3 or 1
                esp.tracer.Visible = config.esp_tracer and visible
            end

            update_corner_box(esp, char)
        end
    end
end

-- ============================================
-- AIMLOCK
-- ============================================
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

local function get_closest_player(mode)
    local closest = nil
    local shortest_distance = math.huge
    local fov = mode == "silent" and config.silent_fov or config.aimlock_fov
    local part_name = mode == "silent" and config.silent_part or config.aimlock_part
    local vis_check = mode == "silent" and config.silent_visible_check or config.aimlock_visible_check
    local team_check = mode == "silent" and config.silent_team_check or config.aimlock_team_check

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local target_part = char:FindFirstChild(part_name) or hrp
            if hrp and humanoid and humanoid.Health > 0 and target_part then
                if vis_check then
                    local ray = Ray.new(Camera.CFrame.Position, (target_part.Position - Camera.CFrame.Position).Unit * 500)
                    local hit, pos = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                    if hit and not hit:IsDescendantOf(char) then continue end
                end
                if team_check and player.Team == LocalPlayer.Team then continue end
                local screen_pos, on_screen = Camera:WorldToViewportPoint(target_part.Position)
                if on_screen then
                    local mouse_pos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screen_pos.X, screen_pos.Y) - mouse_pos).Magnitude
                    if distance < fov and distance < shortest_distance then
                        shortest_distance = distance
                        closest = target_part
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================
-- SİLENT AİM
-- ============================================
local silent_active = false
local silent_target = nil

local function silent_aim_hook()
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if silent_active and silent_target and tostring(method) == "FindPartOnRayWithIgnoreList" then
            local args = {...}
            if args[1] then
                local origin = args[1].Origin
                local direction = (silent_target.Position - origin).Unit * (silent_target.Position - origin).Magnitude
                args[1] = Ray.new(origin, direction)
            end
            return old_namecall(self, unpack(args))
        end
        return old_namecall(self, ...)
    end)
    setreadonly(mt, true)
end

pcall(silent_aim_hook)

-- ============================================
-- SPEED SİSTEMİ v2 (FIX)
-- ============================================
local speed_active = false
local speed_connection = nil

local function apply_speed()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.WalkSpeed = config.speed_value

    -- sürekli güncelle (macro gibi)
    if speed_connection then speed_connection:Disconnect() end
    speed_connection = RunService.Heartbeat:Connect(function()
        if speed_active then
            if char.Parent and humanoid.Parent then
                humanoid.WalkSpeed = config.speed_value
            end
        end
    end)
end

local function reset_speed()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
    if speed_connection then
        speed_connection:Disconnect()
        speed_connection = nil
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if speed_active then
        apply_speed()
    end
end)

-- ============================================
-- ANA DÖNGÜ
-- ============================================
RunService.RenderStepped:Connect(function()
    if config.esp_enabled then update_esp() end

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

    if config.silent_enabled and silent_active then
        silent_target = get_closest_player("silent")
    else
        silent_target = nil
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
        if config.esp_enabled then create_esp(player) end
    end)
end)
Players.PlayerRemoving:Connect(function(player) remove_esp(player) end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then create_esp(player) end
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if config.esp_enabled then create_esp(player) end
        end)
    end
end

-- ============================================
-- UI SİSTEMİ
-- ============================================
local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "palofsc_ui"
screen_gui.ResetOnSpawn = false
screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen_gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

create_fov_circle()

local main_frame = Instance.new("Frame")
main_frame.Name = "main_frame"
main_frame.Size = UDim2.new(0, 480, 0, 580)
main_frame.Position = UDim2.new(0, 50, 0, 50)
main_frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
main_frame.BorderSizePixel = 0
main_frame.Active = true
main_frame.Draggable = true
main_frame.Parent = screen_gui

local main_corner = Instance.new("UICorner")
main_corner.CornerRadius = UDim.new(0, 10)
main_corner.Parent = main_frame

local main_stroke = Instance.new("UIStroke")
main_stroke.Color = Color3.fromRGB(80, 80, 140)
main_stroke.Thickness = 1.5
main_stroke.Parent = main_frame

local title_bar = Instance.new("Frame")
title_bar.Name = "title_bar"
title_bar.Size = UDim2.new(1, 0, 0, 40)
title_bar.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
title_bar.BorderSizePixel = 0
title_bar.Parent = main_frame

local title_corner = Instance.new("UICorner")
title_corner.CornerRadius = UDim.new(0, 10)
title_corner.Parent = title_bar

local title_label = Instance.new("TextLabel")
title_label.Size = UDim2.new(1, -80, 1, 0)
title_label.Position = UDim2.new(0, 15, 0, 0)
title_label.BackgroundTransparency = 1
title_label.Text = "palofsc // hood v4"
title_label.TextColor3 = Color3.fromRGB(180, 180, 255)
title_label.Font = Enum.Font.Code
title_label.TextSize = 17
title_label.TextXAlignment = Enum.TextXAlignment.Left
title_label.Parent = title_bar

local minimize_btn = Instance.new("TextButton")
minimize_btn.Size = UDim2.new(0, 25, 0, 25)
minimize_btn.Position = UDim2.new(1, -60, 0, 7)
minimize_btn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
minimize_btn.BorderSizePixel = 0
minimize_btn.Text = "-"
minimize_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimize_btn.Font = Enum.Font.Code
minimize_btn.TextSize = 16
minimize_btn.Parent = title_bar

local minimize_corner = Instance.new("UICorner")
minimize_corner.CornerRadius = UDim.new(0, 4)
minimize_corner.Parent = minimize_btn

local close_btn = Instance.new("TextButton")
close_btn.Size = UDim2.new(0, 25, 0, 25)
close_btn.Position = UDim2.new(1, -30, 0, 7)
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

close_btn.MouseButton1Click:Connect(function() main_frame.Visible = false end)
minimize_btn.MouseButton1Click:Connect(function()
    if main_frame.Size.Y.Offset > 50 then
        TweenService:Create(main_frame, TweenInfo.new(0.2), {Size = UDim2.new(0, 480, 0, 40)}):Play()
    else
        TweenService:Create(main_frame, TweenInfo.new(0.2), {Size = UDim2.new(0, 480, 0, 580)}):Play()
    end
end)

local tab_frame = Instance.new("Frame")
tab_frame.Name = "tab_frame"
tab_frame.Size = UDim2.new(1, -20, 0, 32)
tab_frame.Position = UDim2.new(0, 10, 0, 50)
tab_frame.BackgroundTransparency = 1
tab_frame.Parent = main_frame

local function make_tab(text, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -5, 1, 0)
    btn.Position = UDim2.new(position, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 180)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.Parent = tab_frame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn
    return btn
end

local aimlock_tab = make_tab("AIMLOCK", 0)
local silent_tab = make_tab("SILENT", 0.25)
local esp_tab = make_tab("ESP", 0.5)
local misc_tab = make_tab("MISC", 0.75)

local content_frame = Instance.new("Frame")
content_frame.Name = "content_frame"
content_frame.Size = UDim2.new(1, -20, 1, -145)
content_frame.Position = UDim2.new(0, 10, 0, 90)
content_frame.BackgroundTransparency = 1
content_frame.Parent = main_frame

local function make_page(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 140)
    page.Visible = false
    page.Parent = content_frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page
    return page
end

local aimlock_page = make_page("aimlock_page")
local silent_page = make_page("silent_page")
local esp_page = make_page("esp_page")
local misc_page = make_page("misc_page")

aimlock_page.Visible = true

local function set_active_tab(active)
    for _, tab in ipairs({aimlock_tab, silent_tab, esp_tab, misc_tab}) do
        tab.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
        tab.TextColor3 = Color3.fromRGB(150, 150, 180)
    end
    active.BackgroundColor3 = Color3.fromRGB(45, 45, 80)
    active.TextColor3 = Color3.fromRGB(200, 200, 255)
end

aimlock_tab.MouseButton1Click:Connect(function()
    aimlock_page.Visible = true; silent_page.Visible = false; esp_page.Visible = false; misc_page.Visible = false
    set_active_tab(aimlock_tab)
end)
silent_tab.MouseButton1Click:Connect(function()
    aimlock_page.Visible = false; silent_page.Visible = true; esp_page.Visible = false; misc_page.Visible = false
    set_active_tab(silent_tab)
end)
esp_tab.MouseButton1Click:Connect(function()
    aimlock_page.Visible = false; silent_page.Visible = false; esp_page.Visible = true; misc_page.Visible = false
    set_active_tab(esp_tab)
end)
misc_tab.MouseButton1Click:Connect(function()
    aimlock_page.Visible = false; silent_page.Visible = false; esp_page.Visible = false; misc_page.Visible = true
    set_active_tab(misc_tab)
end)

set_active_tab(aimlock_tab)

-- ============================================
-- UI BİLEŞENLERİ
-- ============================================
local function create_toggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local toggle_bg = Instance.new("Frame")
    toggle_bg.Size = UDim2.new(0, 42, 0, 22)
    toggle_bg.Position = UDim2.new(1, -54, 0.5, -11)
    toggle_bg.BackgroundColor3 = default and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 80)
    toggle_bg.BorderSizePixel = 0
    toggle_bg.Parent = frame
    local toggle_corner = Instance.new("UICorner")
    toggle_corner.CornerRadius = UDim.new(1, 0)
    toggle_corner.Parent = toggle_bg
    local toggle_circle = Instance.new("Frame")
    toggle_circle.Size = UDim2.new(0, 18, 0, 18)
    toggle_circle.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
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
        toggle_bg.BackgroundColor3 = state and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 80)
        TweenService:Create(toggle_circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
        callback(state)
    end)
    return frame
end

local function create_slider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local slider_bg = Instance.new("Frame")
    slider_bg.Size = UDim2.new(1, -24, 0, 8)
    slider_bg.Position = UDim2.new(0, 12, 0, 32)
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
    slider_btn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local value_btn = Instance.new("TextButton")
    value_btn.Size = UDim2.new(0.4, 0, 1, -10)
    value_btn.Position = UDim2.new(0.55, 0, 0, 5)
    value_btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
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
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local key_btn = Instance.new("TextButton")
    key_btn.Size = UDim2.new(0.3, 0, 1, -10)
    key_btn.Position = UDim2.new(0.65, 0, 0, 5)
    key_btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    key_btn.BorderSizePixel = 0
    key_btn.Text = default.Name or "?"
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
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    waiting = false
                    key_btn.Text = input.KeyCode.Name
                    callback(input.KeyCode)
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                waiting = false
                local mouse_names = {
                    [Enum.UserInputType.MouseButton1] = "Mouse1",
                    [Enum.UserInputType.MouseButton2] = "Mouse2",
                    [Enum.UserInputType.MouseButton3] = "Mouse3"
                }
                key_btn.Text = mouse_names[input.UserInputType]
                callback(input.UserInputType)
            end
        end
    end)
    return frame
end

local function is_key_pressed(input, key)
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.KeyCode then
            return input.KeyCode == key
        elseif key.EnumType == Enum.UserInputType then
            return input.UserInputType == key
        end
    end
    return false
end

-- AIMLOCK SAYFASI
create_toggle(aimlock_page, "Aimlock Aktif", config.aimlock_enabled, function(v) config.aimlock_enabled = v end)
create_keybind(aimlock_page, "Aimlock Tuşu", config.aimlock_key, function(v) config.aimlock_key = v end)
create_slider(aimlock_page, "Hız (Düşük=Hızlı)", 0.01, 1.0, config.aimlock_smoothness, function(v) config.aimlock_smoothness = v end)
create_slider(aimlock_page, "FOV", 10, 500, config.aimlock_fov, function(v) config.aimlock_fov = v end)
create_dropdown(aimlock_page, "Hedef Bölge", {"UpperTorso", "HumanoidRootPart", "Head", "LowerTorso"}, config.aimlock_part, function(v) config.aimlock_part = v end)
create_toggle(aimlock_page, "Görünürlük Kontrolü", config.aimlock_visible_check, function(v) config.aimlock_visible_check = v end)
create_toggle(aimlock_page, "Takım Kontrolü", config.aimlock_team_check, function(v) config.aimlock_team_check = v end)

-- SİLENT SAYFASI
create_toggle(silent_page, "Silent Aim Aktif", config.silent_enabled, function(v) config.silent_enabled = v end)
create_keybind(silent_page, "Silent Tuşu", config.silent_key, function(v) config.silent_key = v end)
create_slider(silent_page, "Silent FOV", 10, 500, config.silent_fov, function(v) config.silent_fov = v end)
create_dropdown(silent_page, "Hedef Bölge", {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}, config.silent_part, function(v) config.silent_part = v end)
create_toggle(silent_page, "Görünürlük Kontrolü", config.silent_visible_check, function(v) config.silent_visible_check = v end)
create_toggle(silent_page, "Takım Kontrolü", config.silent_team_check, function(v) config.silent_team_check = v end)

-- ESP SAYFASI
create_toggle(esp_page, "ESP Aktif", config.esp_enabled, function(v) config.esp_enabled = v end)
create_toggle(esp_page, "Highlight", config.esp_fill, function(v) config.esp_fill = v end)
create_toggle(esp_page, "Outline", config.esp_outline, function(v) config.esp_outline = v end)
create_toggle(esp_page, "İsim Göster", config.esp_name, function(v) config.esp_name = v end)
create_toggle(esp_page, "Mesafe Göster", config.esp_distance, function(v) config.esp_distance = v end)
create_toggle(esp_page, "Can Barı", config.esp_health, function(v) config.esp_health = v end)
create_toggle(esp_page, "Box ESP", config.esp_box, function(v) config.esp_box = v end)
create_toggle(esp_page, "Corner Box", config.esp_corner, function(v) config.esp_corner = v end)
create_toggle(esp_page, "Tracer", config.esp_tracer, function(v) config.esp_tracer = v end)
create_toggle(esp_page, "Takım Rengi", config.esp_team_color, function(v) config.esp_team_color = v end)
create_slider(esp_page, "Max Mesafe", 50, 5000, config.esp_max_distance, function(v) config.esp_max_distance = v end)

-- MISC SAYFASI
create_toggle(misc_page, "Speed Aktif", config.speed_enabled, function(v) config.speed_enabled = v end)
create_keybind(misc_page, "Speed Tuşu", config.speed_key, function(v) config.speed_key = v end)
create_slider(misc_page, "Speed Değeri", 16, 500, config.speed_value, function(v)
    config.speed_value = v
    if speed_active then apply_speed() end
end)
create_toggle(misc_page, "Toggle Modu", config.speed_toggle_mode, function(v) config.speed_toggle_mode = v end)

-- ============================================
-- TUŞ KONTROLLERİ
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if config.aimlock_enabled and is_key_pressed(input, config.aimlock_key) then
        aimlock_active = true
        aimlock_target = get_closest_player("aimlock")
    end

    if config.silent_enabled and is_key_pressed(input, config.silent_key) then
        silent_active = true
    end

    if config.speed_enabled and is_key_pressed(input, config.speed_key) then
        if config.speed_toggle_mode then
            speed_active = not speed_active
            if speed_active then apply_speed() else reset_speed() end
        else
            speed_active = true
            apply_speed()
        end
    end

    if is_key_pressed(input, config.ui_keybind) then
        config.ui_visible = not config.ui_visible
        main_frame.Visible = config.ui_visible
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if config.aimlock_enabled and is_key_pressed(input, config.aimlock_key) then
        aimlock_active = false
        aimlock_target = nil
    end

    if config.silent_enabled and is_key_pressed(input, config.silent_key) then
        silent_active = false
    end

    if config.speed_enabled and is_key_pressed(input, config.speed_key) then
        if not config.speed_toggle_mode then
            speed_active = false
            reset_speed()
        end
    end
end)

print("[palofsc] hood v4 yüklendi")
print("[palofsc] speed fix aktif")
print("[palofsc] corner box esp eklendi")
