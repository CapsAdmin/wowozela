AddCSLuaFile()

wowozela = {}

wowozela.ValidNotes =
{
	IN_ATTACK,
	IN_ATTACK2,
}

wowozela.ValidKeys =
{
	IN_ATTACK,
	IN_ATTACK2,
	IN_WALK,
	IN_SPEED,
	IN_USE,
}
if(SERVER) then
	for key, value in pairs(wowozela.ValidNotes) do
		concommand.Add("wowozela_select_" .. key, function(ply, _, args)
			local wep = ply:GetActiveWeapon()
			if wep:IsValid() and wep:GetClass() == "wowozela" then
				local val = tonumber(args[1]) or 1
				wep.dt[value] = val
			end		
		end)
	end
end

wowozela.Samples = {}

for _, file_name in pairs(file.Find("sound/wowozela/samples/*.wav", "GAME")) do
	
	table.insert(wowozela.Samples, "wowozela/samples/" .. file_name)

	if SERVER then
		resource.AddFile("sound/wowozela/samples/" .. file_name)
	end
end

table.sort(wowozela.Samples, function(a,b) return a < b end)


function wowozela.New(ply)
	local sampler = setmetatable({}, wowozela.SamplerMeta)
	ply.sampler = sampler

	sampler.Player = NULL

	sampler.Pitch = 100
	sampler.Volume = 1

	sampler.Keys = {}
	sampler.CSP = {}

	sampler:Initialize(ply)

	return sampler
end

function wowozela.IsValidKey(key)
	return table.HasValue(wowozela.ValidKeys, key)
end

function wowozela.IsValidNote(key)
	return table.HasValue(wowozela.ValidNotes, key)
end

do -- swep meta
	local SWEP = {Primary = {}, Secondary = {}}

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
		for i, key in ipairs(wowozela.ValidNotes) do
			self:DTVar("Int", i, key)
		end
	end

	function SWEP:PrintWeaponInfo() end
	function SWEP:DrawWeaponSelection() end
	function SWEP:DrawWorldModel() return true end
	function SWEP:CanPrimaryAttack() return false end
	function SWEP:CanSecondaryAttack() return false end
	function SWEP:ShouldDropOnDie() return false end
	function SWEP:Reload() return false end

	function SWEP:Initialize()
	   self:SetWeaponHoldType("normal")
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
		--[[if press and wowozela.IsValidNote(key) and self.Owner:KeyDown(IN_RELOAD) then
			self.dt[key] = math.Clamp((self.dt[key] + 1)%#wowozela.Samples, 1, #wowozela.Samples)
			wowozela.BroadcastKeyEvent(self.Owner, key, press, true)
			wowozela.BroadcastKeyEvent(self.Owner, key, press, false)
		end]]
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
		
		local names = {}
		local wason = false
		local selection = 1
		local alpha = 0
		local showing = 5
		function SWEP:DrawHUD()
			local in1 = self.dt and self.dt[IN_ATTACK] ~= 0 and self.dt[IN_ATTACK] or 1
			local in2 = self.dt and self.dt[IN_ATTACK2] ~= 0 and self.dt[IN_ATTACK2] or 1 
			local left = self.Owner:KeyDown(IN_ATTACK) or input.IsMouseDown(MOUSE_LEFT)
			local right = self.Owner:KeyDown(IN_ATTACK2) or input.IsMouseDown(MOUSE_RIGHT)
			local total = #wowozela.Samples

			if self.Owner:KeyDown(IN_RELOAD) then
				if not wason then
					gui.EnableScreenClicker(true)
					wason = true
				end
				if left or right then
					surface.SetFont("WowozelaFont")
					
					local start = math.max(selection - showing, 1)
					local index_end = math.min(selection + showing, total)
					local center = showing + 0.5
					
					for I = start, index_end, 1 do
						if not names[I] then
							names[I] = wowozela.Samples[I]:match("^wowozela/samples/(.+)%.wav")
						end
						
						local w,h = surface.GetTextSize(names[I])
						local col = HSVToColor(math.abs(selection - I) / center * 90, 1, 1)
						
						surface.SetTextColor(col.r, col.g, col.b, (1 - (math.abs(selection - I)/ center)^2)*255)
						surface.SetTextPos(ScrW()/2 - w/2, ScrH() / 2 + h * (I-start) - h * center)
						surface.DrawText(names[I])
					end	
					
					--[[Selection]]

					local scale = ScrH() / total
					local selected1 = math.Clamp(math.ceil(gui.MouseY()/scale),1,total) 
					
					if left and selected1 ~= in1 then
						RunConsoleCommand("cmd", "wowozela_select_1", selected1)
					end
					
					if right and selected1 ~= in2 then
						RunConsoleCommand("cmd", "wowozela_select_2", selected1)
					end
					selection = selected1
				end
			else
				if(wason) then
					gui.EnableScreenClicker(false)
					wason = false
				end
				if not names[in1] then
					names[in1] = wowozela.Samples[in1]:match("^wowozela/samples/(.+)%.wav")
				end
				
				if not names[in2] then
					names[in2] = wowozela.Samples[in2]:match("^wowozela/samples/(.+)%.wav")
				end				
			
				draw.SimpleText(
					names[in1], 
					"WowozelaFont", 
					16, 
					ScrH() - ScrH()/2, 
					HSVToColor((in1/total)*360, 1, 1), 
					TEXT_ALIGN_LEFT, 
					TEXT_ALIGN_CENTER
				)
					
				draw.SimpleText(
					names[in2], 
					"WowozelaFont",
					ScrW() - 16, 
					ScrH() - ScrH()/2, 
					HSVToColor((in2/total)*360, 1, 1), 
					TEXT_ALIGN_RIGHT, 
					TEXT_ALIGN_CENTER
				)
			end
		end
	end
	weapons.Register(SWEP, "wowozela", true)
end

do -- sample meta
	local META = {}
	META.__index = META

	META.Weapon = NULL

	function META:Initialize(ply)
		self.Player = ply

		for i, path in pairs(wowozela.Samples) do
			self:SetSample(i, path)
		end

		self.IDs = {}
	end

	function META:GetSampleIndex(key)
		if wowozela.IsValidNote(key) then
			local wep = self.Player:GetActiveWeapon()

			if wep:IsWeapon() and wep.dt and wep:GetClass() == "wowozela" then
				return math.Clamp(wep.dt[key], 1, #wowozela.Samples)
			end
		end
	end

	function META:CanPlay()
		local wep = self.Player:GetActiveWeapon()
		if wep:IsWeapon() and wep:GetClass() == "wowozela" then
			self.Weapon = wep
			return true
		end

		return false
	end

	function META:GetPos()
		if self.Player == LocalPlayer() and not self.Player:ShouldDrawLocalPlayer() then
			return self.Player:EyePos()
		end
		
		local id = self.Player:LookupBone("ValveBiped.Bip01_Head1")
		local pos = id and self.Player:GetBonePosition(id)
		return pos or self.Player:EyePos()
	end

	function META:GetAngles()
		local ang = self.Player:GetAimVector():Angle()
		
		ang.p = math.NormalizeAngle(ang.p)
		ang.y = math.NormalizeAngle(ang.y)
		ang.r = 0
		
		return ang
	end

	function META:IsPlaying() -- hm
		for _, on in pairs(self.Keys) do
			if on then
				return true
			end
		end

		return false
	end

	function META:SetSample(i, path)
		self.CSP[i] = CreateSound(self.Player, path or wowozela.DefaultSound)
		self.CSP[i]:SetSoundLevel(100)
	end

	function META:ChangeVolume(i, num)
		if self.CSP[i] then
			self.CSP[i]:ChangeVolume(self.Volume, -1)
		end
	end

	function META:ChangePitch(i, num)
		if self.CSP[i] then
			self.CSP[i]:ChangePitch(self.Pitch, -1)
		end
	end

	function META:SetPitch(num) -- ???
		num = num or 1

		if self:IsKeyDown(IN_WALK) then
			num = num - 1
		end
		
		self.Pitch = math.Clamp(math.floor(100 * 2 ^ num), 1, 255)

		for i in pairs(wowozela.Samples) do
			self:ChangePitch(i, self.Pitch)
		end
	end

	function META:SetVolume(num)
		self.Volume = math.Clamp(num or self.Volume, 0.0001, 1)

		for i in pairs(wowozela.Samples) do
			self:ChangeVolume(i, self.Volume)
		end
	end

	function META:Start(i, id)
		if not self:CanPlay() then return end

		if self.CSP[i] then
			if id then
				local snd = self.IDs[id]
				if snd then
					snd:Stop()
				end
				snd = self.CSP[i]
				snd:PlayEx(self.Volume, self.Pitch)
				self.IDs[id] = snd
			else
				self.CSP[i]:PlayEx(self.Volume, self.Pitch)
			end
		end
	end

	function META:Stop(i, id)
		if self.CSP[i] then
			if id then
				local snd = self.IDs[id]
				if snd then
					snd:Stop()
				end
				self.IDs[id] = self.CSP[i]
			else
				self.CSP[i]:Stop()
			end
		end
	end

	function META:IsKeyDown(key)
		return self.Keys[key] == true
	end

	function META:OnKeyEvent(key, press)
		local id = self:GetSampleIndex(key)

		if id then
			if press then
				if self:IsKeyDown(IN_SPEED) and self.Player == LocalPlayer() then
					local ang = self.Player:EyeAngles()
					
					local p = ang.p / 89 -- -1 to 1
					p = (p + 1) / 2 -- 0 to 1
					p = p * 12 -- 0 to 12
					p = math.Round(p*2)/2 -- rounded
					p = p / 12
					p = (p * 2) - 1
					
					ang.p = p * 89
					self.Player:SetEyeAngles(ang)
				end
			
				self:Start(id, key)
				self:SetVolume(1)
			else
				self:Stop(id, key)
			end
		end
	end

	function META:Think()
		if not self:CanPlay() then
			for _, csp in pairs(self.CSP) do 
				csp:Stop()
			end
			return
		end
	
		local ang = self:GetAngles()

		if self:IsKeyDown(IN_USE) then
			if self.using then
				self:SetVolume(math.abs(ang.y - self.using) / 20)
			else
				self.using = ang.y
			end
		else
			self.using = false
			self:SetVolume(1)
		end

		self:SetPitch(-ang.p/89)

		if self:IsKeyDown(IN_ATTACK) or self:IsKeyDown(IN_ATTACK2) then
			self:MakeParticle()
		end
	end

	local emitter

	function META:MakeParticle()
		local pitch = self.Pitch
		
		emitter = emitter or ParticleEmitter(Vector())
		
		local scale = self.Player:GetModelScale()
		
		local forward = self:GetAngles():Forward()
		local particle = emitter:Add("particle/fire", self:GetPos() + forward * 10 * scale)
		
		if particle then
			local col = HSVToColor(pitch*2.55, self.Volume, 1)
			particle:SetColor(col.r, col.g, col.b, self.Volume)

			particle:SetVelocity(self.Volume * self:GetAngles():Forward() * 500 * scale)

			particle:SetDieTime(20)
			particle:SetLifeTime(0)

			local size = ((-pitch + 255) / 250) + 1

			particle:SetAngles(AngleRand())
			particle:SetStartSize(math.max(size*2*scale, 1) * 1.5)
			particle:SetEndSize(0)

			particle:SetStartAlpha(255*self.Volume)
			particle:SetEndAlpha(0)

			--particle:SetRollDelta(math.Rand(-1,1)*20)
			particle:SetAirResistance(500)
			--particle:SetGravity(Vector(math.Rand(-1,1), math.Rand(-1,1), math.Rand(-1, 1)) * 8 )
		end
	end

	wowozela.SamplerMeta = META
end

do -- player meta
	local PLAYER = FindMetaTable("Player")

	function PLAYER:GetSampler()
		return self.sampler
	end
end

do -- hooks

	local hack = {}

	function wowozela.KeyEvent(ply, key, press)
		--WHAT
		local id = ply:UniqueID() .. key
		if hack[id] == press then return end
		hack[id] = press
		--WHAT

		local sampler = ply:GetSampler()

		if sampler and sampler.OnKeyEvent and ply == sampler.Player then

			sampler.Keys[key] = press

			return sampler:OnKeyEvent(key, press)
		end
	end

	function wowozela.Think()
		for key, ply in pairs(player.GetAll()) do
			local sampler = ply:GetSampler()

			if not sampler then sampler = wowozela.New(ply) end

			if sampler and sampler.Think then
				sampler:Think()
			end
		end
	end

	hook.Add("Think", "wowozela_think", wowozela.Think)

	function wowozela.Draw()
		for key, ply in pairs(player.GetAll()) do
			local sampler = ply:GetSampler()

			if sampler and sampler.Draw then
				sampler:Draw()
			end
		end
	end

	hook.Add("PostDrawOpaqueRenderables", "wowozela_draw", wowozela.Draw)

	function wowozela.BroadcastKeyEvent(ply, key, press, filter)
		local rp = RecipientFilter()
		rp:AddAllPlayers()
		if not filter then
			rp:RemovePlayer(ply)
		end

		umsg.Start("wowozela_keyevent", rp)
			umsg.Entity(ply)
			umsg.Long(key) -- or short?
			umsg.Bool(press)
		umsg.End()
	end

	hook.Add("KeyPress", "wowozela_keypress", function(ply, key)
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == "wowozela" and wowozela.IsValidKey(key) then
			if SERVER then
				wowozela.BroadcastKeyEvent(ply, key, true)
				wep:OnKeyEvent(key, true)
			end

			if CLIENT then
				wowozela.KeyEvent(ply, key, true)
			end
		end
	end)

	hook.Add("KeyRelease", "wowozela_keyrelease", function(ply, key)
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == "wowozela" and wowozela.IsValidKey(key) then
			if SERVER then
				wowozela.BroadcastKeyEvent(ply, key, false)
				wep:OnKeyEvent(key, false)
			end

			if CLIENT then
				wowozela.KeyEvent(ply, key, false)
			end
		end
	end)

	if CLIENT then
		usermessage.Hook("wowozela_keyevent", function(umr)
			local ply = umr:ReadEntity()
			local key = umr:ReadLong()
			local press = umr:ReadBool()

			if ply:IsPlayer() then
				wowozela.KeyEvent(ply, key, press)
			end
		end)
	end

end