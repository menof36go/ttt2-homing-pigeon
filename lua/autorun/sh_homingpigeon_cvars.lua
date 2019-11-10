if SERVER then
	AddCSLuaFile()
	if file.Exists("scripts/sh_convarutil.lua", "LUA") then
		AddCSLuaFile("scripts/sh_convarutil.lua")
		print("[INFO][Homing Pigeon] Using the utility plugin to handle convars instead of the local version")
	else
		AddCSLuaFile("scripts/sh_convarutil_local.lua")
		print("[INFO][Homing Pigeon] Using the local version to handle convars instead of the utility plugin")
	end
end

if file.Exists("scripts/sh_convarutil.lua", "LUA") then
	include("scripts/sh_convarutil.lua")
else
	include("scripts/sh_convarutil_local.lua")
end

-- Must run before hook.Add
local cg = ConvarGroup("HomPigeon", "Homing Pigeon")
Convar(cg, false, "ttt_hompigeon_damage", 300, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Damage the pigeon deals on impact", "int", 1, 1200)
Convar(cg, false, "ttt_hompigeon_radius", 200, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Radius of the explosion caused on impact", "int", 1, 800)
Convar(cg, false, "ttt_hompigeon_show_debug", 0, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Show debug information including the homing pigeon blast radius on impact", "bool")
--
--generateCVTable()
--