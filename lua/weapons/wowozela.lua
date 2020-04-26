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
    self:NetworkVar("Int", 0, "NoteLeft")
    self:NetworkVar("Int", 1, "NoteRight")
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
    

    self.CurrentLayout = 1
    self:SetNoteLeft(1)
    self:SetNoteRight(1)
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
    if not self.Owner:KeyDown(IN_RELOAD) then
        return true
    end
    
    return false
end

function SWEP:OnKeyEvent(key, press)

end

function SWEP:_Think()
    if self.Owner and self.Owner:IsValid() and self.Owner:GetViewModel():IsValid() then
        self.Owner:GetViewModel():SetNoDraw(true)
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
    if IsValid(wep) and wep:GetClass() == "wowozela" and ply:KeyDown(IN_RELOAD) then
        return true
    end
end)

if CLIENT then
    local size = 80
    local count = 4
    
    surface.CreateFont(
        "WowozelaFont",
        {
            font		= "Roboto Bk",
            size		= size,
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
    local wason = false
    local selection1 = 1
    local selection2 = 1
    local alpha = 0
    local showing = 5
    
    local space = 10
    local size_diagy
    local maxheight = 0
    local indexs = {}
    local PanelWidth = ScrW() * 0.75
    local function PosToIndex(posX)
        --local posX = size_diag - posX
        for k,v in pairs(indexs) do
            if posX > v[1] and posX <= v[2] then
                return k
            end 
        end
        return 1
    end
    
    local selectionIndex = nil
    local wason = false
    local function testDist(x, y, x2, y2)
        return math.pow(y2 - y, 2) + math.pow(x2 - x, 2)
    end
    
    function surface.DrawWedge(centerX, centerY, innerRadius, outerRadius, startAng, endAng, numText, nameText)
        local cir = {}
        
        local a = math.rad( startAng )
        table.insert( cir, { x = centerX + math.sin( a ) * innerRadius, y = centerY + math.cos( a ) * innerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
        
        local a = math.rad( startAng )
        table.insert( cir, { x = centerX + math.sin( a ) * outerRadius, y = centerY + math.cos( a ) * outerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
        
        local a = math.rad( endAng )
        table.insert( cir, { x = centerX + math.sin( a ) * outerRadius, y = centerY + math.cos( a ) * outerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
    
        local a = math.rad( endAng )
        table.insert( cir, { x = centerX + math.sin( a ) * innerRadius, y = centerY + math.cos( a ) * innerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
        
        local centerAng = (endAng + startAng) / 2
        local a = math.rad( centerAng )
        surface.SetTexture(0)
        surface.DrawPoly(cir)
        local rad = ((outerRadius + innerRadius)/2 - 7)
    
        draw.Text( {
            text = numText,
            pos = { centerX + math.sin( a ) * rad, centerY + math.cos( a ) * rad},
            xalign = TEXT_ALIGN_CENTER,
            yalign = TEXT_ALIGN_CENTER
        } )
    
    
        local align = TEXT_ALIGN_CENTER
    
    
    
        if centerAng > 15 and centerAng < 165 then
            align = TEXT_ALIGN_LEFT
        elseif centerAng > 195 and centerAng < 345 then
            align = TEXT_ALIGN_RIGHT
        end
    
    
    
        draw.Text( {
            text = nameText,
            pos = { centerX + math.sin( a ) * outerRadius * 1.05, centerY + math.cos( a ) * outerRadius * 1.05 },
            xalign = align,
            yalign = TEXT_ALIGN_CENTER,
            font = "WowozelaFont2"
        } )
    end


    function SWEP:LoadWedges()
        self.Wedges = {}
        for I=1,10 do table.insert(self.Wedges, {}) end

        if file.Exists("wowozela.txt", "DATA") then
            self.Wedges = util.JSONToTable(file.Read("wowozela.txt", "DATA"))
        end
    end

    function SWEP:HUDShouldDraw(element)
        if self.Owner:KeyDown(IN_RELOAD) and element == "CHudCrosshair" then
            return false
        end
        return true
    end

    function SWEP:DrawHUD()
        if not self.Wedges then
            self:LoadWedges()
            return
        end
        
        if not self.Wedges[self.CurrentLayout] then 
            self.Wedges[self.CurrentLayout] = {}
        end


        local mouseX, mouseY = gui.MouseX(), gui.MouseY()
        

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


        if self.Owner:KeyDown(IN_RELOAD) then
            
            local editing = self.Owner:KeyDown(IN_ATTACK) or self.Owner:KeyDown(IN_ATTACK2)

            local ang = math.atan2(mouseY - ScrH()/2, ScrW()/2 - mouseX)
            local ang2 = (math.deg(ang) - 90) % 360
            local wedgeSize = (36)
            local wedge2 = wedgeSize

            local hoverWedge = nil


            local farEnough = testDist(ScrW()/2, ScrH()/2, mouseX, mouseY) > 36 * 36

            draw.NoTexture()
            surface.SetDrawColor(Color(100, 100, 100, 75))
            drawCircle(ScrW()/2, ScrH()/2, 36, 10)

            draw.Text( {
                text = tostring(self.CurrentLayout == 10 and 0 or self.CurrentLayout),
                pos = { ScrW()/2, ScrH()/2 },
                xalign = TEXT_ALIGN_CENTER,
                yalign = TEXT_ALIGN_CENTER,
                font = "WowozelaFont2",
                color = Color(255, 255, 255, 255)
            } )


            for I=1, (360/wedgeSize) do
                local wedgeAng = ((I - 1) * wedgeSize)
                local col = HSVToColor(wedgeAng, 1, 0.75)
                col.a = 150
                
                if editing then 
                    if ang2 >= (wedgeAng) and ang2 <= (wedgeAng + wedge2) and farEnough then
                        hoverWedge = I
                        col = HSVToColor(wedgeAng, 1, 0.5)
                        col.a = 150
                    end
                end

                surface.SetDrawColor(col)
                surface.DrawWedge(ScrW()/2, ScrH()/2, 130, 150, wedgeAng, wedgeAng + wedge2, string.format("%d", I == 10 and 0 or I), ("%s"):format(self.Wedges[self.CurrentLayout][I] or "(unassigned)"))

                col.a = 50
                surface.SetDrawColor(col)
                surface.DrawWedge(ScrW()/2, ScrH()/2, 36, 130, wedgeAng, wedgeAng + wedge2, "", "")
            end
            
            if editing then
                if not wason then
                    gui.EnableScreenClicker(true)
                    wason = true
                end

                if hoverWedge and farEnough then
                    selectionIndex = {self.Owner:KeyDown(IN_ATTACK), self.Owner:KeyDown(IN_ATTACK2), hoverWedge, self.Wedges[self.CurrentLayout][hoverWedge]}
                else
                    selectionIndex = nil
                end
            elseif wason then
                gui.EnableScreenClicker(false)
                wason = false
            end
        elseif wason then
            gui.EnableScreenClicker(false)
            wason = false
        end
    end

	wowozela.sampleSort = {
		["bass"] = "Instrumental",
		["bass3"] = "Instrumental",
		["bassguitar2"] = "Instrumental",
		["bell"] = "Instrumental",
		["coolchiff"] = "Instrumental",
		["crackpiano"] = "Instrumental",
		["dingdong"] = "Instrumental",
		["dooooooooh"] = "Vocal",
		["dusktodawn"] = "Synth",
		["flute"] = "Instrumental",
		["fmbass"] = "Instrumental",
		["fuzz"] = "Instrumental",
		["guitar"] = "Instrumental",
		["hit"] = "Instrumental",
		["honkytonk"] = "Synth",
		["horn"] = "Misc",
		["justice"] = "Synth",
		["littleflower"] = "Instrumental",
		["meow"] = "Misc",
		["miku"] = "Vocal",
		["mmm"] = "Vocal",
		["oohh"] = "Vocal",
		["overdrive"] = "Misc",
		["pianostab"] = "Instrumental",
		["prima"] = "Vocal",
		["quack"] = "Misc",
		["saw_880"] = "Synth",
		["sine_880"] = "Synth",
		["skull"] = "Instrumental",
		["slap"] = "Synth",
		["square_880"] = "Synth",
		["string"] = "Instrumental",
		["toypiano"] = "Instrumental",
		["triangle_880"] = "Synth",
		["trumpet"] = "Instrumental",
		["woof"] = "Misc"
    }
    
    local function generateTable()
        local tbl = {}
        for k,v in pairs(wowozela.Samples) do
            local t = wowozela.sampleSort[v[2]]
            if t then
                if not tbl[t] then
                    tbl[t] = {}
                end
                table.insert(tbl[t], v[2])
            else
                if not tbl.Custom then
                    tbl.Custom = {}
                end
                table.insert(tbl.Custom, v[2])
            end
        end
        return tbl
    end
    hook.Add("PlayerBindPress", "WowozelaBindPress", function(ply, bind, pressed)
        local wep = ply:GetActiveWeapon() 
        if IsValid(wep) and wep:GetClass() == "wowozela" then
            if ply:KeyDown(IN_RELOAD) then 
                if bind == "+menu" and pressed then
                    if selectionIndex and wep.CurrentLayout then
                        local selectionData = table.Copy(selectionIndex)
    
                        selectionData.layout = wep.CurrentLayout 
                        local Menu = DermaMenu()
                        
                        for cat,snds in pairs(generateTable()) do
    
                            local t = Menu:AddSubMenu(cat)
                            for _, snd in pairs(snds) do 
                                t:AddOption(snd, function()
                                    wep.Wedges[selectionData.layout][selectionData[3]] = snd
                                    file.Write("wowozela.txt", util.TableToJSON(wep.Wedges, true))
    
                                    local noteIndex = nil
                                    for k,v in pairs(wowozela.Samples) do
                                        if v[2] == snd then
                                            noteIndex = k
                                        end
                                    end
    
                                    if noteIndex then
                                        if selectionData[1] then
                                            RunConsoleCommand("wowozela_select_left", noteIndex)
                                            selectionIndex = nil
                                        end
                            
                                        if selectionData[2] then
                                            RunConsoleCommand("wowozela_select_right", noteIndex)
                                            selectionIndex = nil
                                        end
                                    end
                                end)
                            end
                        end
                        Menu:Open()
                    end
                    return true
                end
    
                local num = tonumber(bind:match("slot(%d+)"))
                if num and pressed then
                    if num == 0 then num = 10 end

                    if wep.Wedges[num] then
                        
                        wep.CurrentLayout = num
                    end
                    return true
                end
            elseif ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) then

                local num = tonumber(bind:match("slot(%d+)"))
                if num and pressed then
                    if num == 0 then num = 10 end

                    local noteIndex = nil
                    if wep.Wedges and wep.CurrentLayout and wep.Wedges[wep.CurrentLayout] and wep.Wedges[wep.CurrentLayout][num] then
                        for k,v in pairs(wowozela.Samples) do
                            if v[2] == wep.Wedges[wep.CurrentLayout][num] then
                                noteIndex = k
                            end
                        end
                    end

                    if noteIndex then
                        local sampler = ply:GetSampler() 
                        if ply:KeyDown(IN_ATTACK) then
                            RunConsoleCommand("wowozela_select_left", noteIndex)
                            selectionIndex = nil

                            if sampler then
                                sampler:OnKeyEvent(IN_ATTACK, false)
                                timer.Simple(0, function()
                                    sampler:OnKeyEvent(IN_ATTACK, true)
                                end)
                            end
                        end
            
                        if ply:KeyDown(IN_ATTACK2) then
                            RunConsoleCommand("wowozela_select_right", noteIndex)
                            selectionIndex = nil

                            if sampler then
                                sampler:OnKeyEvent(IN_ATTACK2, false)
                                timer.Simple(0, function()
                                    sampler:OnKeyEvent(IN_ATTACK2, true)
                                end)
                            end
                        end 
                    end
                    return true
                end
            end 
        end
    end)

    hook.Add("KeyRelease", "WowozelaFinalizeSelection", function(ply, key)
        local wep = ply:GetActiveWeapon() 
        if IsValid(wep) and wep:GetClass() == "wowozela" and selectionIndex then
            local isLeft, isRight, noteWedgeIndex = unpack(selectionIndex)


            local noteIndex = nil
            if wep.Wedges and wep.CurrentLayout and wep.Wedges[wep.CurrentLayout] and wep.Wedges[wep.CurrentLayout][noteWedgeIndex] then
                for k,v in pairs(wowozela.Samples) do
                    if v[2] == wep.Wedges[wep.CurrentLayout][noteWedgeIndex] then
                        noteIndex = k
                    end
                end
            end


            if noteIndex then
                if isLeft and key == IN_ATTACK then
                    RunConsoleCommand("wowozela_select_left", noteIndex)
                    selectionIndex = nil
                end
    
                if isRight and key == IN_ATTACK2 then
                    RunConsoleCommand("wowozela_select_right", noteIndex)
                    selectionIndex = nil
                end
            end
            
        end
    end)
end

--easylua.EndWeapon(true, true)