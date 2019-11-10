ExplosionUtil = {}
ExplosionUtil.__index = ExplosionUtil
local registeredExplosions = 0

local function IsPlayerBehindWall(ent, ply, pos)
    if IsValid(ply) then
        connection = ply:GetPos() - pos
        local normal = nil
        if (connection.x == 0 and connection.y == 0 and connection.z ~= 0) then
            normal = Vector(1,0,0)
        else
            normal = Vector(0,0,1):Cross(connection)
        end
        normal:Normalize()
        mid = pos
        right = pos + normal * 10
        left = pos - normal * 10
        local tr1 = util.TraceLine( {
            start = left,
            endpos = left + connection + Vector(0,0,50),
            filter = ent,
            mask = MASK_NPCWORLDSTATIC 
        } )
        local tr2 = util.TraceLine( {
            start = mid,
            endpos = mid + connection + Vector(0,0,50),
            filter = ent,
            mask = MASK_NPCWORLDSTATIC 
        } )
        local tr3 = util.TraceLine( {
            start = right,
            endpos = right + connection + Vector(0,0,50),
            filter = ent,
            mask = MASK_NPCWORLDSTATIC 
		} )
		local tr4 = util.TraceLine( {
            start = left + Vector(0,0,100),
            endpos = left + connection + Vector(0,0,50),
            filter = ent,
            mask = MASK_NPCWORLDSTATIC 
        } )
        local tr5 = util.TraceLine( {
            start = mid + Vector(0,0,100),
            endpos = mid + connection + Vector(0,0,50),
            filter = ent,
            mask = MASK_NPCWORLDSTATIC 
        } )
        local tr6 = util.TraceLine( {
            start = right + Vector(0,0,100),
            endpos = right + connection + Vector(0,0,50),
            filter = ent,
            mask = MASK_NPCWORLDSTATIC 
        } )

        
        net.WriteVector(left)
        net.WriteVector(right)
		net.WriteVector(connection)
        net.WriteBool(true)

        if (tr1.Hit and tr2.Hit and tr3.Hit and tr4.Hit and tr5.Hit and tr6.Hit) then
            return true
        end
        return false
    end
end

function ExplosionUtil:new()
	local newExplosionUtil = { Id = registeredExplosions }
	
	if SERVER then
		util.AddNetworkString("Explosion" .. registeredExplosions .. "NetworkString")
	end

	if CLIENT then
		net.Receive("Explosion" .. registeredExplosions .. "NetworkString", function(len,ply)
			local hit = net.ReadVector() 
			local radius = net.ReadInt(32)
			local baseDamage = net.ReadInt(32)
			local left = net.ReadVector() 
			local right = net.ReadVector()
			local connection = net.ReadVector()
			local hasBlockInformation = net.ReadBool()
			local mid = hit
			hook.Add("PostDrawTranslucentRenderables", "Explosion" .. registeredExplosions .. "HitSphere", function()
		
				-- Set the draw material to solid white
				render.SetColorMaterial()
			
				-- The position to render the sphere at, in this case, the looking position of the local player
				local pos = hit
				local y = math.sqrt(radius * radius - (radius * radius * 100) / baseDamage)
				local z = math.sqrt(radius * radius - (radius * radius * 50) / baseDamage)
	
				local wideSteps = 10
				local tallSteps = 10
		
				-- Death sphere
				render.DrawWireframeSphere(pos, y, wideSteps, tallSteps, Color(255, 0, 0, 255))
		
				-- Halflife sphere
				render.DrawWireframeSphere(pos, z, wideSteps, tallSteps, Color(255, 255, 0, 255))
				
				-- Blast sphere
				render.DrawWireframeSphere(pos, radius, wideSteps, tallSteps, Color(0, 255, 0, 255))
		
				if (hasBlockInformation) then
					render.DrawLine(left, left + connection + Vector(0,0,50), Color(255,255,255))
					render.DrawLine(mid, mid + connection + Vector(0,0,50), Color(255,255,255))
					render.DrawLine(right, right + connection + Vector(0,0,50), Color(255,255,255))
					render.DrawLine(left + Vector(0,0,100), left + connection + Vector(0,0,50), Color(255,255,255))
					render.DrawLine(mid + Vector(0,0,100), mid + connection + Vector(0,0,50), Color(255,255,255))
					render.DrawLine(right + Vector(0,0,100), right + connection + Vector(0,0,50), Color(255,255,255))
				end
			end)
			timer.Simple(10, function() hook.Remove("PostDrawTranslucentRenderables", "Explosion" .. registeredExplosions .. "HitSphere") end)
		end)
	end

	setmetatable(newExplosionUtil, ExplosionUtil)
	registeredExplosions = registeredExplosions + 1
	return newExplosionUtil
end

function ExplosionUtil:Explode(ent, pos, baseDamage, radius, attacker, inflictor, effect, debug)
	effect = effect or "Explosion"
	baseDamage = baseDamage or 100
	radius = radius or 200
	debug = debug or false

	local effd = EffectData()
            effd:SetStart(pos)
            effd:SetOrigin(pos)
            effd:SetScale(1)
            effd:SetRadius(radius)
            effd:SetEntity(NULL)
        util.Effect(effect, effd)

	attacker = IsValid(attacker) and attacker or ent
	
	local d = DamageInfo()
	d:SetAttacker(attacker)
	d:SetInflictor(inflictor)
	d:SetDamageType(DMG_BLAST)

	if debug then
		net.Start("Explosion" .. self.Id .. "NetworkString")
		net.WriteVector(pos)
		net.WriteInt(radius, 32)
		net.WriteInt(baseDamage, 32)
	end
	local u = ents.FindInSphere(pos, radius)
	for key,ply in ipairs(u) do
		if (ply:IsPlayer() or ply:IsNPC()) then
			local dmg = baseDamage * ((radius * radius - ply:GetPos():DistToSqr(pos)) / (radius * radius))
			--print("Player", ply:GetName(), dmg)
			if (dmg > 0) then
				local behindWall = IsPlayerBehindWall(ent, ply, pos)
				--print("IsPlayerBehindWall", behindWall)
				if (!behindWall) then
					d:SetDamage(dmg)
					ply:TakeDamageInfo(d)
				end
			end
		end
	end
	if debug then
		net.Send(attacker)
	end

	timer.Simple(0, function() ent:Remove() end)
end

setmetatable(ExplosionUtil, {__call = ExplosionUtil.new})