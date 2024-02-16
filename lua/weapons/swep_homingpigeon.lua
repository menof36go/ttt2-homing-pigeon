if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/VGUI/ttt/icon_homingpigeon.png")
  util.AddNetworkString("DropPigeon")
  util.AddNetworkString("RemovePigeon")
  util.AddNetworkString("SendTargetPigeon")
  resource.AddWorkshop("620936792")
end

SWEP.HoldType = "grenade"
SWEP.PrintName = "Homing Pigeon"
SWEP.Slot = 6
SWEP.ViewModelFlip = false
SWEP.EquipMenuData = {
  	type = "item_weapon",
  	desc = "A flying pigeon that seeks out a target."
};
SWEP.Icon = "VGUI/ttt/icon_homingpigeon.png"
SWEP.Base = "weapon_tttbase"
SWEP.ViewModel = "models/weapons/v_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 60
SWEP.DrawCrosshair = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "AR2AltFire"
SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.LimitedStock = true
SWEP.IsEmpty = false
SWEP.BoneCountManipulated = 0

function SWEP:RemoveViewModel()
	if (self.Pigeon and IsValid(self.Pigeon)) then
		self.Pigeon:Remove()
		self.Pigeon = nil
	end
end

function SWEP:RemoveWorldModel()
	if (self.PigeonModel and IsValid(self.PigeonModel)) then
		self.PigeonModel:Remove()
		self.PigeonModel = nil
	end
end

local function RemovePigeonModel(Ent)
	if (CLIENT) then
		local l = LocalPlayer()
		if !(l) then
			return
		end
		if !(l.GetViewModel) then
			return
		end
		local VM = l:GetViewModel()
		if (IsValid(VM) and VM.GetBoneCount and VM:GetBoneCount() and VM:GetBoneCount() > 0) then
			local I = 0
			while (I <= Ent.BoneCountManipulated) do
				VM:ManipulateBoneScale(I, Vector(1,1,1))
				I = I + 1
			end
		end
	end

	if (!IsValid(Ent)) then
		return 
	end

	Ent:RemoveWorldModel()
	Ent:RemoveViewModel()	
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:OnRemove()
	if CLIENT then
		if IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
			RunConsoleCommand("lastinv")
		end
		RemovePigeonModel(self)
	end
end

function SWEP:Holster()
	RemovePigeonModel(self)
	return true
end

if SERVER then
	function SWEP:PrimaryAttack()
		return
	end

	function SWEP:OnDrop()
		net.Start("DropPigeon")
		net.WriteEntity(self)
		net.Broadcast()
	end

	function SWEP:Equip()
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	end

	net.Receive("SendTargetPigeon", function(len,ply)
		if !IsValid(ply) then return end
		local activeWeapon = ply:GetActiveWeapon()
		if IsValid(activeWeapon) and activeWeapon:GetClass() == "swep_homingpigeon" then
			local TargetPly = net.ReadEntity()
			local wep = ply:GetWeapon("swep_homingpigeon")
			if (IsValid(ply) and IsValid(TargetPly)) then
				local Pigeon = ents.Create("sent_homingpigeon")
				if !IsValid(Pigeon) then 
					return 
				end
				Pigeon:SetPos(ply:GetShootPos() + ply:GetAimVector() * 5)
				Pigeon:SetAngles((TargetPly:GetShootPos() - ply:GetShootPos()):Angle())
				Pigeon.Target = TargetPly
				Pigeon:Spawn()
				Pigeon:SetOwner(ply)
				wep:TakePrimaryAmmo(1)
				wep:SetNextPrimaryFire(CurTime() + wep.Primary.Delay)
				wep:Remove()
				ply:StripWeapon("swep_homingpigeon")
			end
		end
	end)
end

if CLIENT then
	util.PrecacheModel("models/pigeon.mdl") 

	function SWEP:OwnerChanged()
		if self:GetOwner() ~= nil then
			self:RemoveWorldModel()
		end
	end

	function SWEP:ViewModelDrawn()
		local VM = LocalPlayer():GetViewModel()
		if (IsValid(VM) and IsValid(self:GetOwner()) and LocalPlayer() == self:GetOwner())then
			if (!IsValid(self.Pigeon) and !self.IsEmpty) then
				self.Pigeon = ents.CreateClientProp("models/pigeon.mdl")
				local I = 0
				local bones = VM:GetBoneCount()
				while (I <= bones) do
					VM:ManipulateBoneScale(I, Vector(0.005, 0.005, 0.005))
					I = I + 1
				end
				if (self.BoneCountManipulated <= bones) then
					self.BoneCountManipulated = bones
				end
			elseif(IsValid(self.Pigeon)) then
				local VM = self:GetOwner():GetViewModel()
				local boneId = VM:LookupBone("ValveBiped.Bip01_R_Hand")
				if boneId then
    					local BP, BA = VM:GetBonePosition(boneId)
					BP = BP - BA:Forward() * 3 - BA:Up() * 6 - BA:Right() * 4
					self.Pigeon:SetPos(BP)
					BA:RotateAroundAxis(BA:Right(), -60)
					BA:RotateAroundAxis(BA:Forward(), 180)
					self.Pigeon:SetAngles(BA)
					self.Pigeon:SetParent(VM)
				else
					return					
				end
			end
		end
	end

	function SWEP:DrawWorldModel()
		if IsValid(self:GetOwner()) and !(IsValid(self.PigeonModel)) and !self.IsEmpty then
			self.PigeonModel = ents.CreateClientProp("models/pigeon.mdl")
			--local Pos, Ang = self:GetOwner():GetBonePosition(self:GetOwner():LookupBone("ValveBiped.Bip01_R_Hand"))
			local Hand = self:GetOwner():LookupAttachment("anim_attachment_RH")
			if Hand then
				Hand = self:GetOwner():GetAttachment(Hand)
				if Hand then
					local Pos, Ang = Hand.Pos, Hand.Ang
					self.PigeonModel:SetRenderOrigin(Pos)
					self.PigeonModel:SetRenderAngles(Ang)
					self.PigeonModel:AddEffects(EF_BONEMERGE)
					self.PigeonModel:SetParent(self:GetOwner())
				end
			end
		end

		if (IsValid(self.PigeonModel) and IsValid(self:GetOwner())) then
			--local Pos, Ang = self:GetOwner():GetBonePosition(self:GetOwner():LookupBone("ValveBiped.Bip01_R_Hand"))
			local Hand = self:GetOwner():LookupAttachment("anim_attachment_RH")
			if Hand then
				Hand = self:GetOwner():GetAttachment(Hand)
				if Hand then
					local Pos, Ang = Hand.Pos, Hand.Ang
					Ang:RotateAroundAxis(Ang:Forward(), -100)
					self.PigeonModel:SetRenderOrigin(Pos)
					self.PigeonModel:SetRenderAngles(Ang)
				end
			end
		end
	end

	function SWEP:PrimaryAttack()
		if !self:CanPrimaryAttack() then 
			return 
		end
		local TargetPly = self:GetOwner():GetEyeTrace().Entity
		if IsValid(TargetPly) and TargetPly:IsPlayer() then
			self:TakePrimaryAmmo(1)
			if self:Clip1() <= 0 then
				self.IsEmpty = true
			end
			net.Start("SendTargetPigeon")
			net.WriteEntity(TargetPly)
			net.SendToServer()
			RemovePigeonModel(self)
		else
			self:SetNextPrimaryFire(CurTime() + 0.1)
		end
	end

	  net.Receive("DropPigeon", function()
		local E = net.ReadEntity()
		if (!IsValid(E)) then 
			return 
		end
		RemovePigeonModel(E)
		E.PigeonModel = ents.CreateClientProp("models/pigeon.mdl")
		if (IsValid(E.PigeonModel)) then
			E.PigeonModel:SetPos(E:GetPos() - E:GetUp() * 7)
			E.PigeonModel:SetParent(E)
		end
    end)
end
