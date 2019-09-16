if SERVER then AddCSLuaFile() end
if not wowozela then wowozela = {} end

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

if SERVER then
	for key, value in pairs(wowozela.ValidNotes) do
		concommand.Add("wowozela_select_" .. key:lower(), function(ply, _, args)
			local wep = ply:GetActiveWeapon()
			if wep:IsValid() and wep:GetClass() == "wowozela" then
				
				local val = tonumber(args[1]) or 1
				local test = "SetNote" .. key -- naughty
				
				if wep[test] then
					wep[test](wep, val)
				end
			end		
		end)
	end
	wowozela.Samples = {}
	local workshopSounds = {
		["bass.wav"] = true,
		["bass3.wav"] = true,
		["bassguitar2.wav"] = true,
		["bell.wav"] = true,
		["coolchiff.wav"] = true,
		["crackpiano.wav"] = true,
		["dingdong.wav"] = true,
		["dooooooooh.wav"] = true,
		["dusktodawn.wav"] = true,
		["flute.wav"] = true,
		["fmbass.wav"] = true,
		["fuzz.wav"] = true,
		["guitar.wav"] = true,
		["hit.wav"] = true,
		["honkytonk.wav"] = true,
		["horn.wav"] = true,
		["justice.wav"] = true,
		["littleflower.wav"] = true,
		["meow.wav"] = true,
		["miku.wav"] = true,
		["mmm.wav"] = true,
		["oohh.wav"] = true,
		["overdrive.wav"] = true,
		["pianostab.wav"] = true,
		["prima.wav"] = true,
		["quack.wav"] = true,
		["saw_880.wav"] = true,
		["sine_880.wav"] = true,
		["skull.wav"] = true,
		["slap.wav"] = true,
		["square_880.wav"] = true,
		["string.wav"] = true,
		["toypiano.wav"] = true,
		["triangle_880.wav"] = true,
		["trumpet.wav"] = true,
		["woof.wav"] = true
	}

	for _, file_name in pairs(file.Find("sound/wowozela/samples/*.wav", "GAME")) do
		
		table.insert(wowozela.Samples, {"wowozela/samples/" .. file_name, file_name:match("(.+)%.wav")})
		
		if SERVER then
			if not workshopSounds[file_name] then
				resource.AddFile("sound/wowozela/samples/" .. file_name)
			end
			resource.AddWorkshop("108170491")
		end
	end

	table.sort(wowozela.Samples, function(a,b) return a[1] < b[1] end)
	util.AddNetworkString("wowozela_update")
	util.AddNetworkString("wowozela_key")

	concommand.Add("wowozela_request_samples", function(ply)
		net.Start("wowozela_update")
			net.WriteTable(wowozela.Samples)
		net.Send(ply)
	end)

else
	wowozela.Samples = {}
	net.Receive("wowozela_update", function()
		wowozela.Samples = net.ReadTable()
	end)
end




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
	for k,v in pairs(wowozela.ValidNotes) do
		if v == key then
			return k 
		end
	end
	return false
end


do -- sample meta
	local META = {}
	META.__index = META

	META.Weapon = NULL

	function META:Initialize(ply)
		self.Player = ply

		for i, path in pairs(wowozela.Samples) do
			self:SetSample(i, path[1])
		end

		self.IDs = {}
	end

	function META:GetSampleIndex(key)
		local Note = wowozela.IsValidNote(key)
		if Note then
			local wep = self.Player:GetActiveWeapon()
			local get = "GetNote" .. Note
			if wep:IsWeapon() and wep[get] and wep:GetClass() == "wowozela" then
				return math.Clamp(wep[get](wep), 1, #wowozela.Samples)
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
		if #wowozela.Samples > 0 then
			for key, ply in pairs(player.GetAll()) do
				local sampler = ply:GetSampler()

				if not sampler then sampler = wowozela.New(ply) end

				if sampler and sampler.Think then
					sampler:Think()
				end
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
		net.Start("wowozela_key")
			net.WriteEntity(ply)
			net.WriteInt(key, 32)
			net.WriteBool(press)
		net.Broadcast() 
	end

	hook.Add("KeyPress", "wowozela_keypress", function(ply, key)
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == "wowozela" then
			local wep = ply:GetActiveWeapon()
			if wowozela.IsValidKey(key) then
				if SERVER and wep.OnKeyEvent then
					wowozela.BroadcastKeyEvent(ply, key, true)
					wep:OnKeyEvent(key, true)
				end

				if CLIENT then
					wowozela.KeyEvent(ply, key, true)
				end
			end
		end
	end)

	hook.Add("KeyRelease", "wowozela_keyrelease", function(ply, key)
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == "wowozela" then
			if wowozela.IsValidKey(key) then
				if SERVER and wep.OnKeyEvent then
					wowozela.BroadcastKeyEvent(ply, key, false)
					wep:OnKeyEvent(key, false)
				end

				if CLIENT then
					wowozela.KeyEvent(ply, key, false)
				end
			end
		end
	end)

	if CLIENT then
		net.Receive("wowozela_key", function()
			local ply = net.ReadEntity()
			local key = net.ReadInt(32)
			local press = net.ReadBool()
			if IsValid(ply) and ply:IsPlayer() then
				wowozela.KeyEvent(ply, key, press)
			end
		end)
		
		RunConsoleCommand("wowozela_request_samples")
	else
		hook.Add("PlayerInitialSpawn", "WowozelaPlayerJoined", function(ply)
			net.Start("wowozela_update")
				net.WriteTable(wowozela.Samples)
			net.Send(ply)
		end)


		if #player.GetAll() > 0 then
			net.Start("wowozela_update")
				net.WriteTable(wowozela.Samples)
			net.Broadcast()
		end
	end
end