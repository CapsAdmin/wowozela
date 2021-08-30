if SERVER then
    AddCSLuaFile()
end

local wowozela = _G.wowozela or {}
_G.wowozela = wowozela

wowozela.ValidNotes = {
    ["Left"] = IN_ATTACK,
    ["Right"] = IN_ATTACK2
}

wowozela.ValidKeys = {IN_ATTACK, IN_ATTACK2, IN_WALK, IN_SPEED, IN_USE}

wowozela.KnownSamples = {}

function wowozela.GetSamples()
    return wowozela.KnownSamples
end

function wowozela.GetSample(i)
    return wowozela.KnownSamples[i]
end

if CLIENT then
    wowozela.volume = CreateClientConVar("wowozela_volume", "0.5", true, false)
    wowozela.hudtext = CreateClientConVar("wowozela_hudtext", "1", true, false)
    --wowozela.sensitivity = CreateClientConVar("wowozela_sensitivity", "4", true, false)

    local function set_sample_index(which, note_index)
        local wep = LocalPlayer():GetActiveWeapon()

        if not wep:IsValid() or wep:GetClass() ~= "wowozela" then
            return
        end

        net.Start("wowozela_select_" .. which)
        net.WriteInt(note_index, 32)
        net.SendToServer()

        if not wowozela.KnownSamples[note_index] then
            print("wowozela " .. which .. ": note index " .. note_index .. " is out of range")
        end
    end

    function wowozela.SetSampleIndexLeft(noteIndex)
        return set_sample_index("left", noteIndex)
    end

    function wowozela.SetSampleIndexRight(noteIndex)
        return set_sample_index("right", noteIndex)
    end

    net.Receive("wowozela_update_samples", function()

        for i, v in ipairs(net.ReadTable()) do
            wowozela.KnownSamples[i] = v
        end

        wowozela.SetSampleIndexLeft(1)
        wowozela.SetSampleIndexRight(1)

        for _, ply in ipairs(player.GetAll()) do
            if ply.wowozela_sampler then
                for _,v in pairs(ply.wowozela_sampler.Samples or {}) do
                    if v.obj then
                        v.obj:Stop()
                    end
                end
                wowozela.CreateSampler(ply)
            end
            local wep = ply:GetActiveWeapon()
            if wep:IsValid() and wep:GetClass() == "wowozela" then
                wep:LoadPages()
            end
        end
    end)
end

if SERVER then
    for key, in_enum in pairs(wowozela.ValidNotes) do
        util.AddNetworkString("wowozela_select_" .. key)

        net.Receive("wowozela_select_" .. key:lower(), function(len, ply)
            local wep = ply:GetActiveWeapon()
            if wep:IsValid() and wep:GetClass() == "wowozela" then
                local value = net.ReadInt(32)
                local function_name = "SetNoteIndex" .. key

                if wep[function_name] then
                    wep[function_name](wep, value)
                    net.Start("wowozela_sample")
                    net.WriteEntity(ply)
                    net.WriteInt(in_enum, 32)
                    net.WriteInt(value, 32)
                    net.Broadcast()
                end
            end
        end)
    end

    function wowozela.LoadSamples()
        wowozela.KnownSamples = {}

        local _, directories = file.Find("sound/wowozela/samples/*", "GAME")

        for _, directory in ipairs(directories) do
            for _, file_name in ipairs(file.Find("sound/wowozela/samples/" .. directory .. "/*", "GAME")) do
                if file_name:EndsWith(".ogg") or file_name:EndsWith(".mp3") then
                    table.insert(wowozela.KnownSamples, {
                        category = directory,
                        path = "wowozela/samples/" .. directory .. "/" .. file_name,
                        name = file_name:match("(.+)%.")
                    })

                    if SERVER then
                        --resource.AddFile("sound/wowozela/samples/" .. file_name)
                        resource.AddWorkshop("108170491")
                    end
                end
            end
        end

        table.sort(wowozela.KnownSamples, function(a, b)
            return a.path < b.path
        end)
    end

    wowozela.LoadSamples()

    util.AddNetworkString("wowozela_update_samples")
    util.AddNetworkString("wowozela_key")
    util.AddNetworkString("wowozela_sample")

    function wowozela.BroacastSamples(ply)
        net.Start("wowozela_update_samples")
        net.WriteTable(wowozela.KnownSamples)
        net.Send(ply)
    end

    hook.Add("PlayerInitialSpawn", "send_wowozela_samples", function(ply)
        local hookName = "wowozela_" .. ply:SteamID64()
        hook.Add("SetupMove", hookName, function(oply, _, cmd)
            if ply == oply and not cmd:IsForced() then
                wowozela.BroacastSamples(oply)
                hook.Remove("SetupMove", hookName)
            end
        end)
    end)
end

function wowozela.IsValidKey(key)
    return table.HasValue(wowozela.ValidKeys, key)
end

function wowozela.KeyToButton(key)
    for k, v in pairs(wowozela.ValidNotes) do
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
        ply.wowozela_sampler = self

        self.Player = NULL

        self.Pitch = 100
        self.Volume = 1

        self.Keys = {}
        self.Samples = {}

        self.Player = ply

        for i, sample in pairs(wowozela.KnownSamples) do
            self:SetSample(i, sample.path)
        end

        self.KeyToSample = {}
    end

    function META:KeyToSampleIndex(key)
        local button = wowozela.KeyToButton(key)
        if button then
            local wep = self.Player:GetActiveWeapon()
            local get = "GetNoteIndex" .. button
            if wep:IsWeapon() and wep:GetClass() == "wowozela" and wep[get] then
                return math.Clamp(wep[get](wep), 1, #wowozela.KnownSamples)
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

    local function create_sound(path, sampler)
        if SERVER then return end
        local _smeta = {
            __index = function(self, index)
                if index == "create" then
                    return function(callback)
                        if IsValid(rawget(self, "obj")) then
                            callback()
                        else
                            sound.PlayFile("sound/" .. path, "3d noplay noblock", function(snd, errnum, err)
                                if snd then
                                    self.paused = true
                                    self.obj = snd
                                    snd:EnableLooping(true)
                                    snd:SetVolume(wowozela.intvolume or 1)
                                    snd:SetPlaybackRate((sampler.Pitch or 100) / 100)

                                    if sampler.Player == LocalPlayer() then
                                        snd:Set3DEnabled(false)
                                    else
                                        snd:Set3DEnabled(true)
                                    end
                                    callback()
                                end
                            end)
                        end
                    end
                end
                return rawget(self, index)
            end
        }

        return setmetatable({}, _smeta)
    end

    local function set_volume(snd, num, sampler)
        if not IsValid(snd.obj) then return end

        snd.obj:SetVolume(num * (wowozela.intvolume or 1))
        snd.obj:SetPos(sampler.Player:EyePos(), sampler.Player:GetAimVector())
    end

    local function set_pitch(snd, num, sampler)
        if not IsValid(snd.obj) then return end

        snd.obj:SetPlaybackRate(num / 100)
        snd.obj:SetPos(sampler.Player:EyePos(), sampler.Player:GetAimVector())
    end

    local function stop_sound(snd, sampler)
        if not IsValid(snd.obj) then return end
        if snd.paused then return end

        snd.obj:Pause()
        snd.obj:SetTime(0)
        snd.paused = true
    end

    local function play_sound(snd, sampler)
        if not IsValid(snd.obj) then return end
        if not snd.paused or wowozela.disabled then return end

        snd.obj:Play()
        snd.obj:SetPos(sampler.Player:EyePos(), sampler.Player:GetAimVector())

        snd.paused = false
    end

    function META:SetSample(i, path)
        self.Samples[i] = create_sound(path or wowozela.DefaultSound, self)
    end

    function META:SetPitch(num) -- ???
        num = num or 1

        if self:IsKeyDown(IN_WALK) then
            num = num - 7 / 12
        end

        local lastPitch = self.Pitch
        self.Pitch = math.Clamp(math.floor(100 * 2 ^ num), 1, 2048)
        if lastPitch ~= self.Pitch then
            for _, sample in ipairs(self.Samples) do
                set_pitch(sample, self.Pitch, self)
            end
        end
    end

    function META:SetVolume(num)
        local lastVol = self.Volume
        self.Volume = math.Clamp(num or self.Volume, 0.0001, 1)

        if lastVol ~= self.Volume then
            for _, sample in ipairs(self.Samples) do
                set_volume(sample, self.Volume, self)
            end
        end
    end

    cvars.AddChangeCallback("wowozela_volume", function(cvar, oldval, newval)
        if SERVER then return end
        if oldval == newval then return end

        local vol = tonumber(newval) or 0.5
        wowozela.intvolume = math.Clamp(vol, 0, 1)
        wowozela.disabled = vol < 0.01

        for _, ply in ipairs(player.GetAll()) do
            local sampler = wowozela.GetSampler(ply)

            if sampler and sampler.Samples then
                for _, sample in ipairs(sampler.Samples) do
                    set_volume(sample, sampler.Volume, sampler)
                end
            end
        end
    end, "wowozela")

    function META:Start(sample_index, key)
        if not self:CanPlay() then
            return
        end

        local sample = self.Samples[sample_index]
        if not sample then
            return
        end

        if key then
            local previous_sample = self.KeyToSample[key]
            if previous_sample then
                stop_sound(previous_sample, self)
            end

            self.KeyToSample[key] = sample


            sample.create(function()
                play_sound(sample, self)
            end)
        end
    end

    function META:Stop(sample_index, key)
        local sample = self.Samples[sample_index]
        if not sample then
            return
        end

        if sample == self.last_sample then return end
        if key then
            for k,v in pairs(self.KeyToSample) do
                if v == sample and key ~= k then

                    stop_sound(sample, self)
                    play_sound(sample, self)

                    self.KeyToSample[key] = nil
                    return
                end
            end

            local previous_sample = self.KeyToSample[key]
            if previous_sample then
                stop_sound(previous_sample, self)
                -- previous_sample:Stop() 
            end

            self.KeyToSample[key] = nil
        end

        if sample then
            -- sample:Stop()
            stop_sound(sample, self)
        end
    end

    function META:IsKeyDown(key)
        return self.Keys[key] == true
    end

    function META:OnKeyEvent(key, press)
        local id = self:KeyToSampleIndex(key)
        if id then
            if press then
                self:Start(id, key)
                self:SetVolume(1)
            else
                self:Stop(id, key)
            end
        end
    end
    function META:GetPlayerPitch()
        local ply = self.Player

        if ply.wowozela_real_pitch then
            return -(ply.wowozela_real_pitch / 90)
        end

        local pitch = self:GetAngles().p
        return -pitch / 89
    end

    function META:Think()
        if not self:CanPlay() or wowozela.disabled then
            if self.WasPlaying then
                for _, csp in ipairs(self.Samples) do
                    if not csp.paused then
                        stop_sound(csp, self)
                    end
                end
                self.WasPlaying = false
            end
            return
        end


        self.WasPlaying = true
        local ang = self:GetAngles()

        if self:IsKeyDown(IN_USE) then
            if self.using_angle then
                self:SetVolume(math.abs(ang.y - self.using_angle) / 20)
            else
                self.using_angle = ang.y
            end
        else
            self.using_angle = false
            self:SetVolume(1)
        end

        self:SetPitch(self:GetPlayerPitch())

        if self:IsKeyDown(IN_ATTACK) or self:IsKeyDown(IN_ATTACK2) then
            self:MakeParticle()
        end
    end

    local emitter
    local function fade_in(p)
        local f = p:GetLifeTime()
        p:SetStartSize(p:GetRoll() * (f ^ 0.25))
        if f < 1 then
            p:SetNextThink(CurTime())
        end
    end
    function META:MakeParticle()
        local pitch = self.Pitch

        emitter = emitter or ParticleEmitter(Vector())

        local scale = self.Player:GetModelScale()

        local forward = self:GetAngles():Forward()

        local fft = {}
        for _, sample in pairs(self.KeyToSample) do
            if sample.obj then
                sample.obj:FFT(fft, 1)
            end
        end


        local avg = 0
        for i = 1, #fft do
            avg = avg + fft[i]
        end
        avg = avg / #fft
        local m = ((avg ^ 0.5) * 10)

        local particle = emitter:Add("particle/fire", self:GetPos() + forward * scale)


        if particle then
            local col = HSVToColor(pitch * 2.55, self.Volume, 1)
            particle:SetColor(col.r, col.g, col.b, self.Volume)

            particle:SetVelocity(self.Volume * self:GetAngles():Forward() * 500 * scale)
            particle:SetNextThink(CurTime())

            particle:SetDieTime(5)
            particle:SetLifeTime(0)
            particle:SetBounce(1)
            particle:SetCollide(true)

            particle:SetThinkFunction(fade_in)

            local size = ((-pitch + 255) / 250) + 1

            particle:SetAngles(AngleRand())

            local s = math.max(size * 2 * scale, 1) * m
            particle:SetStartSize(0)
            particle:SetEndSize(s)
            particle:SetRoll(s)

            particle:SetStartAlpha(255 * self.Volume)
            particle:SetEndAlpha(0)

            -- particle:SetRollDelta(math.Rand(-1,1)*20)
            particle:SetAirResistance(500)
            -- particle:SetGravity(Vector(math.Rand(-1,1), math.Rand(-1,1), math.Rand(-1, 1)) * 8 )
        end
    end

    wowozela.SamplerMeta = META

    function wowozela.CreateSampler(ply)
        local sampler = setmetatable({}, wowozela.SamplerMeta)
        sampler:Initialize(ply)
        ply.wowozela_sampler = sampler
        return sampler
    end

    function wowozela.GetSampler(ply)
        return ply.wowozela_sampler
    end
end

do -- hooks
    function wowozela.KeyEvent(ply, key, press)
        local sampler = wowozela.GetSampler(ply)
        if sampler and sampler.OnKeyEvent and ply == sampler.Player then
            sampler.Keys[key] = press
            return sampler:OnKeyEvent(key, press)
        end
    end

    function wowozela.Think()
        if not wowozela.KnownSamples[1] then
            return
        end

        if CLIENT then
            local vol = wowozela.volume:GetFloat()
            wowozela.intvolume = math.Clamp(vol, 0, 1)
            wowozela.disabled = vol < 0.01
        end

        for _, ply in ipairs(player.GetAll()) do
            local sampler = wowozela.GetSampler(ply)

            if not sampler then
                sampler = wowozela.CreateSampler(ply)
            end

            if sampler and sampler.Think then
                sampler:Think()
            end
        end
    end

    hook.Add("Think", "wowozela_think", wowozela.Think)



    function wowozela.Draw()
        if not wowozela.KnownSamples[1] then
            return
        end

        for key, ply in pairs(player.GetAll()) do
            local sampler = wowozela.GetSampler(ply)

            if sampler and sampler.Draw then
                sampler:Draw()
            end
        end
    end

    hook.Add("PostDrawOpaqueRenderables", "wowozela_draw", wowozela.Draw)

    function wowozela.BroadcastKeyEvent(ply, key, press, filter)
        net.Start("wowozela_key", true)
        net.WriteEntity(ply)
        net.WriteInt(key, 32)
        net.WriteBool(press)
        if not filter then
            net.SendOmit(ply)
        else
            net.Broadcast()
        end
    end

    hook.Add("KeyPress", "wowozela_keypress", function(ply, key)
        if not IsFirstTimePredicted() and not game.SinglePlayer() then
            return
        end

        local wep = ply:GetActiveWeapon()
        if wep:IsValid() and wep:GetClass() == "wowozela" and wowozela.IsValidKey(key) then
            if SERVER and wep.OnKeyEvent then
                wowozela.BroadcastKeyEvent(ply, key, true)
                wep:OnKeyEvent(key, true)
            end

            if CLIENT then
                wowozela.KeyEvent(ply, key, true)
            end
        end
    end)

    hook.Add("KeyRelease", "wowozela_keyrelease", function(ply, key)
        if not IsFirstTimePredicted() and not game.SinglePlayer() then
            return
        end

        local wep = ply:GetActiveWeapon()
        if wep:IsValid() and wep:GetClass() == "wowozela" and wowozela.IsValidKey(key) then
            if SERVER and wep.OnKeyEvent then
                wowozela.BroadcastKeyEvent(ply, key, false)
                wep:OnKeyEvent(key, false)
            end

            if CLIENT then
                wowozela.KeyEvent(ply, key, false)
            end
        end
    end)

    if CLIENT then

        net.Receive("wowozela_sample", function()
            local ply = net.ReadEntity()
            if not ply:IsValid() then
                return
            end
            local sampler = wowozela.GetSampler(ply)
            if not sampler then
                return
            end
            local key = net.ReadInt(32)
            local id = net.ReadInt(32)

            if sampler:IsPlaying() then
                sampler:Start(id, key)
            end
        end)

        net.Receive("wowozela_key", function()
            local ply = net.ReadEntity()
            if not ply:IsValid() or not wowozela.GetSampler(ply) then
                return
            end
            local key = net.ReadInt(32)
            local press = net.ReadBool()

            wowozela.KeyEvent(ply, key, press)
        end)
    end
end

if CLIENT then
    for _, ply in ipairs(player.GetAll()) do
        wowozela.CreateSampler(ply)
    end
end

if SERVER then
    timer.Simple(0.1, function()
        for _, ply in ipairs(player.GetAll()) do
            wowozela.BroacastSamples(ply)
        end
    end)
end
