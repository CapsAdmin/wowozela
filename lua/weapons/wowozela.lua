local SWEP = _G.SWEP or {Primary = {}, Secondary = {}}

if wowozela == nil then
    wowozela = {}

    wowozela.ValidNotes =
    {
        ["Left"] = IN_ATTACK,
        ["Right"] = IN_ATTACK2
    }

    wowozela.ValidKeys =
    {
        IN_ATTACK,
        IN_ATTACK2,
        IN_WALK,
        IN_SPEED,
        IN_USE
    }
end
if SERVER then AddCSLuaFile() end

--easylua.StartWeapon("wowozela")
SWEP.Base = "weapon_base"

SWEP.Author = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.PrintName = "Wowozela"
--SWEP.Category = "Toys"

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

function SWEP:PrintWeaponInfo() end
function SWEP:DrawWeaponSelection() end
function SWEP:DrawWorldModel() return true end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:ShouldDropOnDie() return false end
function SWEP:Reload() return false end

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
end

function SWEP:Deploy()
    self.Think = self._Think
    return true
end

function SWEP:Holster()
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
    if IsValid(wep) and wep:GetClass() == "wowozela" and (ply:KeyDown(IN_RELOAD) or ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2)) then
        return true
    end
end)

if CLIENT then
    surface.CreateFont(
        "WowozelaFont",
        {
            font		= "Roboto Bk",
            size		= 35,
            weight		= 1000,
        }
    )

    surface.CreateFont(
        "WowozelaFont2",
        {
            font		= "Roboto Bk",
            size		= 17,
            weight		= 1000,
        }
    )

    surface.CreateFont(
        "WowozelaTutorial",
        {
            font		= "Roboto Bk",
            size		= 24,
            weight		= 1000,
        }
    )
    local wason = false

    local selection = nil

    local function testDist(x, y, x2, y2)
        return math.pow(y2 - y, 2) + math.pow(x2 - x, 2)
    end

    local function drawCircle( x, y, radius, seg )
        local cir = {}

        table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
        for i = 0, seg do
            local a = math.rad( ( i / seg ) * -360 )
            table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
        end

        local a = math.rad( 0 ) -- This is needed for non absolute segment counts
        table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

        surface.DrawPoly( cir )
    end

    local left_mouse_button_tex = Material("gui/lmb.png")
    local right_mouse_button_tex = Material("gui/rmb.png")
    
    local function drawWedge(centerX, centerY, innerRadius, outerRadius, startAng, endAng, nameText, textColor)
		local cir = {}

		local a = math.rad( startAng )
		table.insert( cir, { x = centerX + math.sin( a ) * innerRadius, y = centerY + math.cos( a ) * innerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		a = math.rad( startAng )
		table.insert( cir, { x = centerX + math.sin( a ) * outerRadius, y = centerY + math.cos( a ) * outerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		a = math.rad( endAng )
		table.insert( cir, { x = centerX + math.sin( a ) * outerRadius, y = centerY + math.cos( a ) * outerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		a = math.rad( endAng )
		table.insert( cir, { x = centerX + math.sin( a ) * innerRadius, y = centerY + math.cos( a ) * innerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		local centerAng = (endAng + startAng) / 2
		a = math.rad( centerAng )
		surface.SetTexture(0)
		surface.DrawPoly(cir)
        local rad = ((outerRadius + innerRadius) / 2 - 7)
                
        local align = TEXT_ALIGN_CENTER

		if centerAng > 15 and centerAng < 165 then
		    align = TEXT_ALIGN_LEFT
		elseif centerAng > 195 and centerAng < 345 then
		    align = TEXT_ALIGN_RIGHT
		end

		draw.TextShadow( {
            text = nameText,
            color = textColor,
		    pos = { centerX + math.sin( a ) * outerRadius * 1.05, centerY + math.cos( a ) * outerRadius * 1.05 },
		    xalign = align,
		    yalign = TEXT_ALIGN_CENTER,
		    font = "WowozelaFont2"
        }, 2 )
        
        return centerX + math.sin( a ) * rad, centerY + math.cos( a ) * rad
	end

    function SWEP:LoadPages()
        self.Categories = {
            "solo",
            "guitar",
            "voices",
            "bass",
            "piano",
            "drums",
            "horn",
            "animals",
            "polyphonic",
            "custom",
        }

        for k, v in ipairs(wowozela.Samples) do
            if not table.HasValue(self.Categories, v.category) then
                table.insert(self.Categories, v.category)
            end
        end

        self.Pages = {}

        for i, category in ipairs(self.Categories) do
            self.Pages[i] = {}
            for k, v in ipairs(wowozela.Samples) do
                if v.category == category then
                    table.insert(self.Pages[i], v)
                end
            end
        end

        if file.Exists("wowozela_custom_page.txt", "DATA") then
            for i,v in ipairs(self.Categories) do
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
        local sample = wowozela.Samples[self:GetNoteIndexRight()]
        
        return sample and sample.name
    end

    function SWEP:GetNoteNameLeft()
        local sample = wowozela.Samples[self:GetNoteIndexLeft()]

        return sample and sample.name
    end

    function SWEP:GetPageNoteIndexLeft()
        local sample = wowozela.Samples[self:GetNoteIndexLeft()]
        if not sample then return end

        for i, v in ipairs(self.Pages[self.CurrentPageIndex]) do
            if sample.path == v.path then
                return i
            end
        end
    end

    function SWEP:GetPageNoteIndexRight()
        local sample = wowozela.Samples[self:GetNoteIndexRight()]
        if not sample then return end

        for i, v in ipairs(self.Pages[self.CurrentPageIndex]) do
            if sample.path == v.path then
                return i
            end
        end
    end

    function SWEP:PageIndexToWowozelaIndex(page_index)
        local sample = self.Pages[self.CurrentPageIndex][page_index]
        if not sample then return end

        for i, v in ipairs(wowozela.Samples) do
            if sample.path == v.path then
                return i
            end
        end
    end

    local arrow_left_tex = Material("vgui/cursors/arrow")
    local circle_tex = Material("particle/particle_glow_02")
    
    local function play_non_looping(self, path)
        if self.preview_csp then
            self.preview_csp:Stop()
        end
        self.preview_csp = CreateSound(LocalPlayer(), path)
        self.preview_csp:Play()
        timer.Create("wowozela_preview", 1, 1, function() self.preview_csp:Stop() end)
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
            
            surface.DrawTexturedRect(x - s/2, y- s/2, s, s)
        end

        draw.TextShadow({
            text = text,
            color = HSVToColor(hue, 0.75, 1),
            pos = { x - w/2, y - h / 2 },
            font = "WowozelaFont"
        }, 2, 200)
    end
    local function draw_lines(x, y, lines)
        local w, h = 0, 0
        for i = #lines, 1, -1 do
            local line = lines[i]
            w, h = draw.TextShadow( {
                text = line,
                pos = { x, y- i * h - 64 },
                xalign = TEXT_ALIGN_CENTER,
                yalign = TEXT_ALIGN_BOTTOM,
                font = "WowozelaTutorial",
                color = Color(255, 255, 255, 255)
            }, 2 )
        end
    end
    local left_down, right_down
    local show_help_text = true
    local freeze_mouse

    function SWEP:DrawHUD()
        if not self.Pages then
            self:LoadPages()
            return
        end

        local mouseX, mouseY = gui.MouseX(), gui.MouseY()
        local center_x, center_y = ScrW() / 2, ScrH() / 2

        if freeze_mouse and freeze_mouse.ref:IsValid() then 
            mouseX = freeze_mouse.x
            mouseY = freeze_mouse.y
        end

        local time = RealTime()

        if input.IsMouseDown(MOUSE_LEFT) then
            left_down = left_down or RealTime()
        else
            left_down = nil
        end

        if input.IsMouseDown(MOUSE_RIGHT) then
            right_down = right_down or RealTime()
        else
            right_down = nil
        end

        local left_pressed = left_down == time
        local right_pressed = right_down == time
        local in_menu = self:GetOwner():KeyDown(IN_RELOAD)

        if show_help_text then
            draw_lines(center_x, ScrH() , {
                "to select different sounds, hold " .. (input.LookupBinding("+reload", true) or "<+reload not bound>"),
            })
        end

        if in_menu then
            show_help_text = false

            if not self.mouse_shown then
                input.SetCursorPos(center_x, center_y)
                gui.EnableScreenClicker(true)
                self.mouse_shown = true
            end

            local ang = math.atan2(mouseY - center_y, center_x - mouseX)
            local ang2 = (math.deg(ang) - 90) % 360
            local Pagesize = 36
            local wedge2 = Pagesize
            local hoverWedge = nil
            local farEnough = (Vector(center_x, center_y) - Vector(mouseX, mouseY)):Length2D()
            
            if farEnough < 32 or farEnough > 175 then
                farEnough = nil
            end

            draw.NoTexture()
            surface.SetDrawColor(Color(100, 100, 100, 75))
            drawCircle(center_x, center_y, 36, 10)

            draw.TextShadow( {
                text = self.Categories[self.CurrentPageIndex],
                pos = { center_x, center_y },
                xalign = TEXT_ALIGN_CENTER,
                yalign = TEXT_ALIGN_CENTER,
                font = "WowozelaFont2",
                color = Color(255, 255, 255, 255)
            }, 2 )

            if true then
                local keyName = input.LookupBinding("+menu", true) or "<+menu not bound>"
                local left_name = input.LookupBinding("+attack", true) or "<+attack not bound>"
                local right_name = input.LookupBinding("+attack2", true) or "<+attack2 not bound>"
                
        

                draw_lines( center_x, ScrH() , {
                    "select a voice with your left or right mouse button",
                    "find more samples by clicking < or >",
                    self.Categories[self.CurrentPageIndex] == "custom" and ("press " .. keyName ..  " while hovering over a sample to reassign it") or nil,
                })
                
            end

            local max = #self.Pages[self.CurrentPageIndex]

            if self.Categories[self.CurrentPageIndex] == "custom" then
                max = 10
            end

            for I = 1, max do
                local wedgeSize = ((I - 1) / max) 
                local wedgeAng = wedgeSize * 360
                local page_index = self:PageIndexToWowozelaIndex(I)

                local col = page_index and HSVToColor((page_index / #wowozela.Samples) * 360, 0.75, 1) or Color(255, 255, 255, 255)
                local selected = false
                
                if ang2 >= wedgeAng and ang2 <= (wedgeAng + wedge2) and farEnough then
                    hoverWedge = I
                    selected = true
                end


                local left_selected = self:GetPageNoteIndexLeft() == I
                local right_selected = self:GetPageNoteIndexRight() == I

                if left_selected or right_selected then
                    selected = true
                end

                local wedgeText = tostring(self.Pages[self.CurrentPageIndex][I] and self.Pages[self.CurrentPageIndex][I].name or "(unassigned)")

                surface.SetDrawColor(col)
                local x, y = drawWedge(center_x, center_y, 130, selected and 150 or 140, wedgeAng, wedgeAng + wedge2, wedgeText, selected and col or nil)

                col.a = 50
                surface.SetDrawColor(col)
                drawWedge(center_x, center_y, 36, 130, wedgeAng, wedgeAng + wedge2, "")

                if left_selected or right_selected then
                    surface.SetMaterial(circle_tex)
                    surface.SetDrawColor(0,0,0,150)
                    surface.DrawTexturedRect(x-32, y-32, 64, 64)
                end
                
                surface.SetDrawColor(255,255,255,255)

                local icon_size = 16

                if left_selected then
                    local icon_size = icon_size
                    if left_down then
                        icon_size = 32
                    end

                    local w,h = icon_size, icon_size
                    local offset = w/4

                    if not (left_selected and right_selected) then
                        offset = 0
                    end

                    local x,y = x - w/2, y - h/2

                    surface.SetMaterial(left_mouse_button_tex)                    
                    surface.DrawTexturedRect(x - offset, y, w,h)
                end

                if right_selected then
                    local icon_size = icon_size
                    if right_down then
                        icon_size = 32
                    end

                    local w,h = icon_size, icon_size
                    local offset = -w/4

                    if not (left_selected and right_selected) then
                        offset = 0
                    end

                    surface.SetMaterial(right_mouse_button_tex)                    
                    surface.DrawTexturedRect((x - w/2) - offset, y - h/2, w,h)
                end

            end

            if left_down or right_down then
                local noteIndex = self:PageIndexToWowozelaIndex(hoverWedge)
                if noteIndex then
                    if left_pressed then
                        play_non_looping(self, wowozela.Samples[noteIndex].path)
                        wowozela.SetSampleIndexLeft(noteIndex)
                    end

                    if right_pressed then
                        play_non_looping(self, wowozela.Samples[noteIndex].path)
                        wowozela.SetSampleIndexRight(noteIndex)
                    end
                end
            end

            if hoverWedge and farEnough and self.Categories[self.CurrentPageIndex] == "custom" then
                selection = {
                    left_pressed = left_down, 
                    right_pressed = right_down, 
                    index = hoverWedge, 
                    page = self.CurrentPageIndex,
                    name = self.Pages[self.CurrentPageIndex][hoverWedge] and  self.Pages[self.CurrentPageIndex][hoverWedge].name
                }
            else
                selection = nil
            end


            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(arrow_left_tex)

            local s = 32
            local distance = 275

            local left_x = center_x - distance
            local right_x = center_x + distance

            local hover_left = mouseX < left_x + s/2
            local hover_right = mouseX > right_x - s/2

            surface.SetMaterial(arrow_left_tex)


            do
                local s = hover_left and s*1.5 or s
                if hover_left and left_down then
                    s = s * 1.5
                end
                surface.DrawTexturedRectRotated(left_x, center_y, s, s, 45)
            end

            do
                local s = hover_right and s*1.5 or s
                if hover_right and left_down then
                    s = s * 1.5
                end
                surface.DrawTexturedRectRotated(right_x, center_y, s, s, 45 + 180)
            end

            --surface.DrawTexturedRectRotated(left_x, center_y, w, h, 0)
            --surface.DrawTexturedRectRotated(right_x, center_y, w, h, 180)

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

        local hud_distance = 128

        local left_hue = (self:GetNoteIndexLeft() / #wowozela.Samples) * 360
        local right_hue = (self:GetNoteIndexRight() / #wowozela.Samples) * 360

        local s = 1024


        if left_down and not in_menu then

            local offset = 0

            if right_down and left_down then
                offset = -hud_distance
            end

            draw_hud_text(
                ScrW()/2 + offset, 
                ScrH()/2, 
                left_hue,
                tostring(self:GetNoteNameLeft())
            )
        end

        if right_down and not in_menu then

            local offset = 0

            if right_down and left_down then
                offset = hud_distance
            end

            draw_hud_text(
                ScrW()/2 + offset, 
                ScrH()/2,
                right_hue,
                tostring(self:GetNoteNameRight()),
                TEXT_ALIGN_RIGHT
            )
        end
                    

        local vol = GetConVar("wowozela_volume")
        if vol and vol:GetFloat() <= 0.01 then
            draw.SimpleText(
                "Warning your wowozela_volume is set to 0!",
                "WowozelaFont",
                center_x,
                ScrH() - 10,
                Color(255, 255, 255, 150),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_BOTTOM
            )
        end
    end

    hook.Add("PlayerBindPress", "WowozelaBindPress", function(ply, bind, pressed)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "wowozela" then
            if ply:KeyDown(IN_RELOAD) then
                if bind:find("+menu") and pressed then
                    if selection then
                        local selection = table.Copy(selection)

                        local Menu = DermaMenu()
                        local submenus = {}
                        local done = {}
                        for _, data in pairs(wowozela.Samples) do
                            local category = data.category

                            submenus[category] = submenus[category] or Menu:AddSubMenu(category)

                            for _, data in pairs(wowozela.Samples) do
                                if data.category == category and not done[data.path] then
                                    done[data.path] = true
                                    submenus[data.category]:AddOption(data.name, function()
                                        wep.Pages[selection.page][selection.index] = data
                                        file.Write("wowozela_custom_page.txt", util.TableToJSON(wep.Pages[selection.page], true))
                                        wep:LoadPages()
                                        play_non_looping(wep, data.path)
                                    end)
                                end
                            end
                        end
                        Menu:Open()

                        freeze_mouse = {
                            ref = Menu,
                            x = gui.MouseX(),
                            y = gui.MouseY(),
                        }
                    end
                    return true
                end
                local num = tonumber(bind:match("slot(%d+)"))
                if num and pressed then
                    if num == 0 then num = 10 end

                    if wep.Pages[num] then
                        wep.CurrentPageIndex = num
                    end
                    return true
                end
            end
        end
    end)
end

if not _G.SWEP then
    weapons.Register(SWEP, "wowozela")
end