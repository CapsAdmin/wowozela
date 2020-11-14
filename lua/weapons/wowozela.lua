local SWEP = _G.SWEP or {
    Primary = {},
    Secondary = {}
}

if SERVER then
    AddCSLuaFile()
end

-- easylua.StartWeapon("wowozela")
SWEP.Base = "weapon_base"

SWEP.Author = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.PrintName = "Wowozela"
-- SWEP.Category = "Toys"

SWEP.SlotPos = 1
SWEP.Slot = 1

SWEP.Spawnable = true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = true
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.DrawWeaponInfoBox = true

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "NoteIndexLeft")
    self:NetworkVar("Int", 1, "NoteIndexRight")
end

function SWEP:PrintWeaponInfo()
end

local mat = Material("particle/fire")

function SWEP:DrawWeaponSelection(x,y,w,h,a)
    surface.SetDrawColor(HSVToColor(RealTime() * 10, 1, 1))
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x,y-w / 6,w,w)
end

function SWEP:DrawWorldModel()
    return true
end
function SWEP:CanPrimaryAttack()
    return false
end
function SWEP:CanSecondaryAttack()
    return false
end
function SWEP:ShouldDropOnDie()
    return false
end
function SWEP:Reload()
    return false
end

function SWEP:Initialize()
    if self.SetWeaponHoldType then
        self:SetWeaponHoldType("normal")
    end

    self.CurrentPageIndex = 1
    self:SetNoteIndexLeft(1)
    self:SetNoteIndexRight(1)
end

if SERVER then
    function SWEP:OnDrop()
        self:Remove()
    end

    util.AddNetworkString("wowozela_pitch")

    net.Receive("wowozela_pitch", function(len, ply)
        ply.net_incoming_rate_count = nil
        ply.net_incoming_rate_count = nil

        local pitch = net.ReadFloat()

        ply.wowozela_real_pitch = pitch

        net.Start("wowozela_pitch", true)
            net.WriteEntity(ply)
            net.WriteFloat(pitch)
        net.SendOmit(ply)
    end)
end

if CLIENT then
    net.Receive("wowozela_pitch", function(len)
        local ply = net.ReadEntity()
        if not ply:IsValid() then return end
        local pitch = net.ReadFloat()

        ply.wowozela_real_pitch = pitch
    end)
end

local DisableUnlimitedPitch
local EnableUnlimitedPitch

if CLIENT then
    function DisableUnlimitedPitch(ply)

        if ply.wowozela_head_cb then
            ply:RemoveCallback("BuildBonePositions", ply.wowozela_head_cb)
            ply.wowozela_head_cb = nil
        end
    end

    function EnableUnlimitedPitch(ply)

        if not ply.wowozela_sampler then return end

        if not ply.wowozela_head_cb then
            ply.wowozela_head_cb = ply:AddCallback("BuildBonePositions", function(oply)
                local head = oply:LookupBone("ValveBiped.Bip01_Head1")

                if head then
                    local m = oply:GetBoneMatrix(head)
                    if m then
                        local pitch = math.NormalizeAngle(oply.wowozela_sampler:GetPlayerPitch() * -89)
                        local yaw = oply:EyeAngles().y

                        local vec = Angle(pitch, yaw):Forward() * 100

                        local ang = vec:AngleEx(Vector(0,0,-1)) + Angle(-90,0,-90)

                        if pitch > 90 then
                            ang.y = ang.y - 180
                            ang.p = -ang.p
                        elseif pitch < -90 then
                            ang.y = ang.y - 180
                            ang.p = -ang.p
                        end


                        m:SetAngles(ang)
                        ply:SetBoneMatrix(head, m)
                    end
                end
            end)
        end

    end
end

function SWEP:Deploy()
    self.Think = self._Think
    if CLIENT then
        self:LoadPages()
    end

    return true
end

function SWEP:Holster()
    if CLIENT then
        local ply = self:GetOwner()

        if ply.wowozela_head_cb then
            ply:RemoveCallback("BuildBonePositions", ply.wowozela_head_cb)
            ply.wowozela_head_cb = nil
        end
    end

    if not self:GetOwner():KeyDown(IN_RELOAD) then
        return true
    end
    return false
end

function SWEP:OnKeyEvent(key, press)

end

function SWEP:_Think()
    if self:GetOwner() and self:GetOwner():IsValid() and self:GetOwner():GetViewModel():IsValid() then
        self:GetOwner():GetViewModel():SetNoDraw(true)
        self.Think = nil
    end
end

function SWEP:GetViewModelPosition(pos, ang)
    pos.x = 35575
    pos.y = 35575
    pos.z = 35575

    return pos, ang
end

hook.Add("PlayerSwitchWeapon", "WowozelaDontSwap", function(ply, wep, newwep)
    if IsValid(wep) and wep:GetClass() == "wowozela" and
        (ply:KeyDown(IN_RELOAD) or ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2)) then
        return true
    end
end)

local selection = nil

if CLIENT then
    surface.CreateFont("WowozelaFont", {
        font = "Roboto Bk",
        size = 35,
        weight = 1000
    })

    surface.CreateFont("WowozelaFont2", {
        font = "Roboto Bk",
        size = 17,
        weight = 1000
    })

    surface.CreateFont("WowozelaTutorial", {
        font = "Roboto Bk",
        size = 24,
        weight = 1000
    })

    local left_mouse_button_tex = Material("gui/lmb.png")
    local right_mouse_button_tex = Material("gui/rmb.png")



    local function drawCircle(x, y, radius, seg)
        local cir = {}

        table.insert(cir, {
            x = x,
            y = y,
            u = 0.5,
            v = 0.5
        })
        for i = 0, seg do
            local a = math.rad((i / seg) * -360)
            table.insert(cir, {
                x = x + math.sin(a) * radius,
                y = y + math.cos(a) * radius,
                u = math.sin(a) / 2 + 0.5,
                v = math.cos(a) / 2 + 0.5
            })
        end

        local a = math.rad(0) -- This is needed for non absolute segment counts
        table.insert(cir, {
            x = x + math.sin(a) * radius,
            y = y + math.cos(a) * radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })

        surface.DrawPoly(cir)
    end

    local function drawWedge(cx, cy, inner_radius, outer_radius, start_angle, stop_angle, text, text_color)
        local cir = {}

        local a = math.rad(start_angle)
        table.insert(cir, {
            x = cx + math.sin(a) * inner_radius,
            y = cy + math.cos(a) * inner_radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })

        a = math.rad(start_angle)
        table.insert(cir, {
            x = cx + math.sin(a) * outer_radius,
            y = cy + math.cos(a) * outer_radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })

        a = math.rad(stop_angle)
        table.insert(cir, {
            x = cx + math.sin(a) * outer_radius,
            y = cy + math.cos(a) * outer_radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })

        a = math.rad(stop_angle)
        table.insert(cir, {
            x = cx + math.sin(a) * inner_radius,
            y = cy + math.cos(a) * inner_radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })

        local center_angle = (stop_angle + start_angle) / 2
        a = math.rad(center_angle)

        surface.SetTexture(0)
        surface.DrawPoly(cir)
        local radius = (outer_radius + inner_radius) / 2 - 7

        local align = TEXT_ALIGN_CENTER

        if center_angle > 15 and center_angle < 165 then
            align = TEXT_ALIGN_LEFT
        elseif center_angle > 195 and center_angle < 345 then
            align = TEXT_ALIGN_RIGHT
        end

        draw.TextShadow({
            text = text,
            color = text_color,
            pos = {cx + math.sin(a) * outer_radius * 1.05, cy + math.cos(a) * outer_radius * 1.05},
            xalign = align,
            yalign = TEXT_ALIGN_CENTER,
            font = "WowozelaFont2"
        }, 2)

        return cx + math.sin(a) * radius, cy + math.cos(a) * radius
    end

    function SWEP:LoadPages()

        if not wowozela.GetSample(1) then
            return
        end

        self.Categories = {"solo", "guitar", "voices", "bass", "drums", "horn", "animals", "polyphonic", "custom"}

        for k, v in ipairs(wowozela.GetSamples()) do
            if not table.HasValue(self.Categories, v.category) then
                table.insert(self.Categories, v.category)
            end
        end

        self.Pages = {}

        for i, category in ipairs(self.Categories) do
            self.Pages[i] = {}
            for k, v in ipairs(wowozela.GetSamples()) do
                if v.category == category then
                    table.insert(self.Pages[i], v)
                end
            end
        end

        if file.Exists("wowozela_custom_page.txt", "DATA") then
            for i, v in ipairs(self.Categories) do
                if v == "custom" then
                    self.Pages[i] = util.JSONToTable(file.Read("wowozela_custom_page.txt", "DATA"))
                    break
                end
            end
        end
    end

    concommand.Add("wowozela_reset_custom_page", function()
        file.Delete("wowozela_custom_page.txt", "DATA")
    end)

    function SWEP:HUDShouldDraw(element)
        if self:GetOwner():KeyDown(IN_RELOAD) and element == "CHudCrosshair" then
            return false
        end
        return true
    end

    function SWEP:GetNoteNameRight()
        local sample = wowozela.GetSample(self:GetNoteIndexRight())

        return sample and sample.name
    end

    function SWEP:GetNoteNameLeft()
        local sample = wowozela.GetSample(self:GetNoteIndexLeft())

        return sample and sample.name
    end

    function SWEP:GetPageNoteIndexLeft()
        local sample = wowozela.GetSample(self:GetNoteIndexLeft())
        if not sample then
            return
        end

        for i, v in pairs(self.Pages[self.CurrentPageIndex]) do
            if sample.path == v.path then
                return i
            end
        end
    end

    function SWEP:GetPageNoteIndexRight()
        local sample = wowozela.GetSample(self:GetNoteIndexRight())
        if not sample then
            return
        end

        for i, v in pairs(self.Pages[self.CurrentPageIndex]) do
            if sample.path == v.path then
                return i
            end
        end
    end

    function SWEP:PageIndexToWowozelaIndex(page_index)

        local sample = self.Pages[self.CurrentPageIndex][page_index]
        if not sample then
            return
        end

        for i, v in ipairs(wowozela.GetSamples()) do
            if sample.path == v.path then
                return i
            end
        end
    end

    local arrow_left_tex = Material("vgui/cursors/arrow")
    local circle_tex = Material("particle/particle_glow_02")

    local function play_non_looping_sound(self, path)
        if self.preview_csp then
            self.preview_csp:Stop()
        end
        self.preview_csp = CreateSound(LocalPlayer(), path)
        self.preview_csp:PlayEx(0.1, 100)

        timer.Create("wowozela_preview", 1, 1, function()
            self.preview_csp:Stop()
        end)
    end

    local function draw_hud_text(x, y, hue, text, xalign)
        surface.SetFont("WowozelaFont")
        local w, h = surface.GetTextSize(text)

        do
            local s = 400
            local c = HSVToColor(hue, 1, 1)
            c.a = 50
            surface.SetMaterial(circle_tex)
            surface.SetDrawColor(c)

            surface.DrawTexturedRect(x - s / 2, y - s / 2, s, s)
        end

        draw.TextShadow({
            text = text,
            color = HSVToColor(hue, 0.75, 1),
            pos = {x - w / 2, y - h / 2},
            font = "WowozelaFont"
        }, 2, 200)
    end
    local function draw_lines(x, y, lines)
        local _, h = 0, 0
        for i = #lines, 1, -1 do
            local line = lines[i]
            w, h = draw.TextShadow({
                text = line,
                pos = {x, y - i * h - 64},
                xalign = TEXT_ALIGN_CENTER,
                yalign = TEXT_ALIGN_BOTTOM,
                font = "WowozelaTutorial",
                color = Color(255, 255, 255, 255)
            }, 2)
        end
    end

    local function draw_shadow(x, y, size)
        surface.SetMaterial(circle_tex)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawTexturedRect(x - size / 2, y - size / 2, size, size)
    end

    local function draw_mouse_icon(x, y, pressed, offset, tex)
        local icon_size = pressed and 32 or 16
        local w2, h2 = icon_size, icon_size

        offset = offset * (w2 / 4)

        x, y = x - w2 / 2, y - h2 / 2
        surface.SetMaterial(tex)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(x - offset, y, w2, h2)
    end

    local left_down, right_down
    local show_help_text = true
    local freeze_mouse

    function SWEP:DrawHelp(center_x)
        local keyName = input.LookupBinding("+menu", true) or "<+menu not bound>"

        draw_lines(center_x, ScrH(),
            {"select a voice with your left or right mouse button", "find more samples by clicking < or >",
             self.Categories[self.CurrentPageIndex] == "custom" and
                ("press " .. keyName .. " while hovering over a sample to reassign it") or nil})
    end

    function SWEP:DrawHUD()
        if not self.Pages then
            self:LoadPages()
            return
        end

        local mouse_x, mouse_y = gui.MouseX(), gui.MouseY()
        local center_x, center_y = ScrW() / 2, ScrH() / 2

        if freeze_mouse and freeze_mouse.ref:IsValid() then
            mouse_x = freeze_mouse.x
            mouse_y = freeze_mouse.y
        end

        local time = RealTime()

        if input.IsMouseDown(MOUSE_LEFT) then
            left_down = left_down or time
        else
            left_down = nil
        end

        if input.IsMouseDown(MOUSE_RIGHT) then
            right_down = right_down or time
        else
            right_down = nil
        end

        local left_pressed = left_down == time
        local right_pressed = right_down == time

        local in_menu = self:GetOwner():KeyDown(IN_RELOAD)

        if show_help_text then
            draw_lines(center_x, ScrH(), {"to select different sounds, hold " ..
                (input.LookupBinding("+reload", true) or "<+reload not bound>")})
        end

        if in_menu then
            show_help_text = false

            if not self.mouse_shown then
                input.SetCursorPos(center_x, center_y)
                gui.EnableScreenClicker(true)
                self.mouse_shown = true
            end

            local max = #self.Pages[self.CurrentPageIndex]

            local radians = math.atan2(mouse_y - center_y, center_x - mouse_x)
            local degrees = (math.deg(radians) - 90) % 360
            local wedge_step = 360 / max
            local hovered_wedge_index = nil
            local mouse_far_enough = (Vector(center_x, center_y) - Vector(mouse_x, mouse_y)):Length2D()

            if mouse_far_enough < 32 or mouse_far_enough > 175 then
                mouse_far_enough = nil
            end

            draw.NoTexture()
            surface.SetDrawColor(Color(100, 100, 100, 75))
            drawCircle(center_x, center_y, 36, 10)

            draw.TextShadow({
                text = self.Categories[self.CurrentPageIndex],
                pos = {center_x, center_y},
                xalign = TEXT_ALIGN_CENTER,
                yalign = TEXT_ALIGN_CENTER,
                font = "WowozelaFont2",
                color = Color(255, 255, 255, 255)
            }, 2)

            self:DrawHelp(center_x)

            if self.Categories[self.CurrentPageIndex] == "custom" then
                max = 10
            end

            for index = 1, max do
                local page_index = self:PageIndexToWowozelaIndex(index)
                local wedge_size = ((index - 1) / max)
                local wedge_angle = wedge_size * 360

                local col = page_index and HSVToColor((page_index / #wowozela.GetSamples()) * 360, 0.75, 1) or
                                Color(255, 255, 255, 255)

                local is_hovering = false

                if degrees >= wedge_angle and degrees <= (wedge_angle + wedge_step) and mouse_far_enough then
                    hovered_wedge_index = index
                    is_hovering = true
                end

                local left_selected = self:GetPageNoteIndexLeft() == index
                local right_selected = self:GetPageNoteIndexRight() == index

                if left_selected or right_selected then
                    is_hovering = true
                end

                local wedge_name = tostring(self.Pages[self.CurrentPageIndex][index] and
                                                self.Pages[self.CurrentPageIndex][index].name or "(unassigned)")

                surface.SetDrawColor(col)
                local x, y = drawWedge(center_x, center_y, 130, is_hovering and 150 or 140, wedge_angle,
                                 wedge_angle + wedge_step, wedge_name, is_hovering and col or nil)

                col.a = 50
                surface.SetDrawColor(col)
                drawWedge(center_x, center_y, 36, 130, wedge_angle, wedge_angle + wedge_step, "")

                if left_selected or right_selected then
                    draw_shadow(x, y, 64)
                end

                if left_selected then
                    draw_mouse_icon(x, y, left_down, not (left_selected and right_selected) and 0 or 1,
                        left_mouse_button_tex)
                end

                if right_selected then
                    draw_mouse_icon(x, y, right_down, not (left_selected and right_selected) and 0 or -1,
                        right_mouse_button_tex)
                end
            end

            if left_down or right_down then
                local sample_index = self:PageIndexToWowozelaIndex(hovered_wedge_index)
                if sample_index then
                    if left_pressed then
                        play_non_looping_sound(self, wowozela.GetSample(sample_index).path)
                        wowozela.SetSampleIndexLeft(sample_index)
                    end

                    if right_pressed then
                        play_non_looping_sound(self, wowozela.GetSample(sample_index).path)
                        wowozela.SetSampleIndexRight(sample_index)
                    end
                end
            end

            if hovered_wedge_index and mouse_far_enough and self.Categories[self.CurrentPageIndex] == "custom" then
                selection = {
                    left_pressed = left_down,
                    right_pressed = right_down,
                    index = hovered_wedge_index,
                    page = self.CurrentPageIndex,
                    name = self.Pages[self.CurrentPageIndex][hovered_wedge_index] and
                        self.Pages[self.CurrentPageIndex][hovered_wedge_index].name
                }
            else
                selection = nil
            end

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(arrow_left_tex)

            local s = 32
            local distance = 275

            local left_x = center_x - distance
            local right_x = center_x + distance

            local hover_left = mouse_x < left_x + s / 2
            local hover_right = mouse_x > right_x - s / 2

            surface.SetMaterial(arrow_left_tex)

            do
                local s2 = hover_left and s * 1.5 or s
                if hover_left and left_down then
                    s2 = s2 * 1.5
                end
                surface.DrawTexturedRectRotated(left_x, center_y, s2, s2, 45)
            end

            do
                local s2 = hover_right and s * 1.5 or s
                if hover_right and left_down then
                    s2 = s2 * 1.5
                end
                surface.DrawTexturedRectRotated(right_x, center_y, s2, s2, 45 + 180)
            end

            -- surface.DrawTexturedRectRotated(left_x, center_y, w, h, 0)
            -- surface.DrawTexturedRectRotated(right_x, center_y, w, h, 180)

            if hover_left and left_pressed then
                self.CurrentPageIndex = self.CurrentPageIndex - 1
            end

            if hover_right and left_pressed then
                self.CurrentPageIndex = self.CurrentPageIndex + 1
            end

            if self.CurrentPageIndex <= 0 then
                self.CurrentPageIndex = #self.Pages
            end

            if self.CurrentPageIndex > #self.Pages then
                self.CurrentPageIndex = 1
            end

        else
            if self.mouse_shown then
                gui.EnableScreenClicker(false)
                self.mouse_shown = false
            end
        end

        if not LocalPlayer():ShouldDrawLocalPlayer() then

            local hud_distance = 128

            local left_hue = (self:GetNoteIndexLeft() / #wowozela.GetSamples()) * 360
            local right_hue = (self:GetNoteIndexRight() / #wowozela.GetSamples()) * 360

            if left_down and not in_menu then

                local offset = 0

                if right_down and left_down then
                    offset = -hud_distance
                end

                draw_hud_text(ScrW() / 2 + offset, ScrH() / 2, left_hue, tostring(self:GetNoteNameLeft()))
            end

            if right_down and not in_menu then

                local offset = 0

                if right_down and left_down then
                    offset = hud_distance
                end

                draw_hud_text(ScrW() / 2 + offset, ScrH() / 2, right_hue, tostring(self:GetNoteNameRight()),
                    TEXT_ALIGN_RIGHT)
            end
        end

        local vol = GetConVar("wowozela_volume")
        if vol and vol:GetFloat() <= 0.01 then
            draw.SimpleText("Warning your wowozela_volume is set to 0!", "WowozelaFont", center_x, ScrH() - 10,
                Color(255, 255, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end

    timer.Create("wowozela_head_turn", 0.1, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local wep = ply:GetActiveWeapon()
            if not wep:IsValid() or wep:GetClass() ~= "wowozela" then
                DisableUnlimitedPitch(ply)
            else
                EnableUnlimitedPitch(ply)
            end
        end
    end)

    local cx, cy = 0, 0
    local upsidedown = false

    hook.Add("InputMouseApply", "wowozela_unlocked_pitch", function(cmd, x, y, ang)
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if not wep:IsValid() or wep:GetClass() ~= "wowozela" then
            DisableUnlimitedPitch(ply)
            return
        end

        EnableUnlimitedPitch(ply)

        local m_pitch = GetConVar("m_pitch") and GetConVar("m_pitch"):GetFloat() or 0.022
        local m_yaw = GetConVar("m_yaw") and GetConVar("m_yaw"):GetFloat() or 0.022

        if upsidedown then
            x = -x
        end

        cx = cx + x * m_yaw
        cy = cy + y * m_pitch

        local rcy = cy
        if ply:KeyDown(IN_SPEED) then
            rcy = rcy / 90 -- -1 to 1
            rcy = (rcy + 1) / 2 -- 0 to 1
            rcy = rcy * 12 -- 0 to 12
            rcy = math.Round(rcy * 2) / 2 -- rounded
            rcy = rcy / 12
            rcy = (rcy * 2) - 1

            rcy = rcy * 90
        end


        ang = Angle(rcy, -cx, ang.r)
        ang.p = math.NormalizeAngle(ang.p)

        local max = GetConVar("cl_pitchup") and GetConVar("cl_pitchup"):GetFloat() or 89
        local min = GetConVar("cl_pitchdown") and GetConVar("cl_pitchdown"):GetFloat() or 89

        if ang.p >= max then
            upsidedown = true
        elseif ang.p <= -min then
            upsidedown = true
        else
            upsidedown = false
        end

        local pitch_offset = Angle(0,0,0)

        if upsidedown then
            ang.p = math.NormalizeAngle(ang.p + 180)
            pitch_offset.p = -180
            pitch_offset.y = 0
        end

        cmd:SetViewAngles(ang + pitch_offset)

        if ply.wowozela_real_pitch ~= rcy then
            net.Start("wowozela_pitch", true)
            net.WriteFloat(rcy)
            net.SendToServer()
            --print("sending")
            ply.wowozela_real_pitch = rcy
        end

        return true
    end)

    hook.Add("PlayerBindPress", "WowozelaBindPress", function(ply, bind, pressed)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "wowozela" and ply:KeyDown(IN_RELOAD) then
            local selection2 = table.Copy(selection)
            if bind:find("+menu") and pressed and selection2 then
                local Menu = DermaMenu()
                local submenus = {}
                local done = {}
                for _, data in pairs(wowozela.GetSamples()) do
                    local category = data.category

                    submenus[category] = submenus[category] or Menu:AddSubMenu(category)

                    for _, data2 in pairs(wowozela.GetSamples()) do
                        if data2.category == category and not done[data2.path] then
                            done[data2.path] = true
                            submenus[data2.category]:AddOption(data2.name, function()
                                wep.Pages[selection2.page][selection2.index] = data2
                                file.Write("wowozela_custom_page.txt",
                                    util.TableToJSON(wep.Pages[selection2.page], true))
                                wep:LoadPages()
                                play_non_looping_sound(wep, data2.path)
                            end)
                        end
                    end
                end
                Menu:Open()

                freeze_mouse = {
                    ref = Menu,
                    x = gui.MouseX(),
                    y = gui.MouseY()
                }
            end

            local num = tonumber(bind:match("slot(%d+)"))
            if num and pressed then
                if num == 0 then
                    num = 10
                end

                if wep.Pages and wep.Pages[num] then
                    wep.CurrentPageIndex = num
                end
            end
            return true
        end
    end)
end

if not _G.SWEP then
    weapons.Register(SWEP, "wowozela")
end
