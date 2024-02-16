if SERVER then
	AddCSLuaFile()
	if file.Exists("scripts/sh_explosionutil.lua", "LUA") then
		AddCSLuaFile("scripts/sh_explosionutil.lua")
		print("[INFO][Homing Pigeon] Using the utility plugin to handle explosions instead of the local version")
	else
		AddCSLuaFile("scripts/sh_explosionutil_local.lua")
		print("[INFO][Homing Pigeon] Using the local version to handle explosions instead of the utility plugin")
	end
end

if file.Exists("scripts/sh_explosionutil.lua", "LUA") then
	include("scripts/sh_explosionutil.lua")
else
	include("scripts/sh_explosionutil_local.lua")
end

ENT.Explosion = ExplosionUtil()
ENT.PrintName = "Homing Pigeon"
ENT.Icon = "VGUI/ttt/icon_homingpigeon"
ENT.Type = "anim"
ENT.Model = Model("models/pigeon.mdl")

local BirdSounds = {
	"ambient/creatures/seagull_idle1.wav",
	"ambient/creatures/seagull_idle2.wav",
	"ambient/creatures/seagull_idle3.wav",
	"ambient/creatures/seagull_pain1.wav",
	"ambient/creatures/seagull_pain2.wav",
	"ambient/creatures/seagull_pain3.wav"
}

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetModelScale(2,0.01)

	if SERVER then
		self:SetHealth(1)
		self:SetMaxHealth(1)
		self:GetPhysicsObject():SetMass(1)
		self:GetPhysicsObject():ApplyForceCenter((self.Target:GetShootPos() - self:GetPos()) * Vector(3, 3, 3))
	end

	if CLIENT then
      self:EmitSound(Sound(BirdSounds[math.random(1, #BirdSounds)], 100))
	end
end

function ENT:Think()
	if SERVER then
		if(IsValid(self.Target)) then
			local Mul = 3
			if(self:GetPos():Distance(self.Target:GetPos()) < 200) then 
				Mul = 15 
			end
			self:GetPhysicsObject():ApplyForceCenter((self.Target:GetShootPos() - self:GetPos()) * Vector(Mul, Mul, Mul ))
			self:SetAngles(((self.Target:GetShootPos() - self:GetPos()) * Vector(Mul, Mul, Mul)):Angle())

			if( !self.Target:Alive() ) then
				self:Remove()
			end
		else
			self:Remove()
		end
	end
end

function ENT:Explode()
	local baseDamage = GetConVar("ttt_hompigeon_damage"):GetInt()
	local radius = GetConVar("ttt_hompigeon_radius"):GetInt()
	local debug = GetConVar("ttt_hompigeon_show_debug"):GetBool()
	local pos = self:GetPos()

	if !self.Exploded then
		self.Explosion:Explode(self, pos, baseDamage, radius, self:GetOwner(), ents.Create("swep_homingpigeon"), "Explosion", debug)
		self.Exploded = true
	end
end

function ENT:PhysicsCollide(data, phys)
	self:Explode()
end

function ENT:OnTakeDamage(dmginfo)
	if dmginfo:IsBulletDamage() then
		self:SetHealth(self:Health() - dmginfo:GetDamage())
		if self:Health() <= 0 then
			self:Explode()
		end
	end
end
