local ConvarGroupClass = {}
ConvarGroupClass.ListOfConvars = {}
local ConvarClass = {}
ConvarClass.HookLabel = "Undefined" .. tostring(CurTime()) .. tostring(math.random())
ConvarClass.UlxLabel = "Undefined" .. tostring(CurTime()) .. tostring(math.random())

function ConvarClass:InitULib()
	if (self.type == "bool") then
		ULib.replicatedWritableCvar(self.name, 'rep_' .. self.name, GetConVar(self.name):GetBool(), true, false, name)
	elseif (self.type == "int") then
		ULib.replicatedWritableCvar(self.name, 'rep_' .. self.name, GetConVar(self.name):GetInt(), true, false, name)
	elseif (self.type == "float") then
		ULib.replicatedWritableCvar(self.name, 'rep_' .. self.name, GetConVar(self.name):GetFloat(), true, false, name)
	end
end

function ConvarClass:GiveUIElement()
	if (self.type == "bool") then
		return xlib.makecheckbox{label =  self.name .. ' (Def. ' .. self.default .. ')', repconvar = 'rep_' .. self.name, parent = tttrslst}
	elseif (self.type == "int" or self.type == "float") then
		return xlib.makeslider{label =  self.name .. ' (Def. ' .. self.default .. ')', repconvar = 'rep_' .. self.name, min = self.min, max = self.max, decimal = self.decimal, parent = tttrslst}
	end
end

local tbl = "[table][tr][th]Name[/th][th]Description[/th][/tr]"
local function generateCVTable()
    tbl = tbl .. "[/table]"
    print(tbl)
end

function ConvarGroupClass:InitCustomVars()
    hook.Add('TTTUlxInitCustomCVar', 'TTT' .. self.HookLabel .. 'InitRWCVar', function(name)
        for i, cvar in ipairs(self.ListOfConvars) do
            cvar:InitULib()
        end
    end)
end

function ConvarGroupClass:SetupULib()
    if CLIENT then
        hook.Add('TTTUlxModifyAddonSettings', 'TTT' .. self.HookLabel .. 'ModifySettings', function(name)
            local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}
            local i = 0
            local firstEncounter = true
            local tttrsclp = nil
            local tttrslst = nil
            for k, cvar in ipairs(self.ListOfConvars) do
                if !cvar.ttt2 then
                    if firstEncounter then
                        firstEncounter = false
                        local tttrsclp = vgui.Create('DCollapsibleCategory', tttrspnl)
                        tttrsclp:SetSize(390, 300)
                        tttrsclp:SetExpanded(1)
                        tttrsclp:SetLabel('Settings')
    
                        tttrslst = vgui.Create('DPanelList', tttrsclp)
                        tttrslst:SetPos(5, 25)
                        tttrslst:SetSpacing(5)
                    end
                    i = i + 1
                    tttrslst:AddItem(cvar:GiveUIElement())
                end
            end
            if tttrslst then
                print(i)
                tttrslst:SetSize(390, i*25)
            end
    
            i = 0
            firstEncounter = true
            local tttrsclp2 = nil
            local tttrslst2 = nil
            for k, cvar in ipairs(self.ListOfConvars) do
                if cvar.ttt2 then
                    if firstEncounter then
                        firstEncounter = false
                        tttrsclp2 = vgui.Create('DCollapsibleCategory', tttrspnl)
                        tttrsclp2:SetSize(390, 300)
                        tttrsclp2:SetExpanded(1)
                        tttrsclp2:SetLabel('TTT2 Settings (TTT2 required)')
    
                        tttrslst2 = vgui.Create('DPanelList', tttrsclp2)
                        tttrslst2:SetPos(5, 25)
                        tttrslst2:SetSpacing(5)
                    end
                    i = i + 1
                    tttrslst2:AddItem(cvar:GiveUIElement())
                end
            end
            if tttrslst2 then
                print(i)
                tttrslst2:SetSize(390, i*25)
            end
    
            xgui.hookEvent('onProcessModules', nil, tttrspnl.processModules)
            xgui.addSubModule(self.UlxLabel, tttrspnl, nil, name)
        end)
    end
end

function ConvarGroup(hookLabel, ulxLabel)
    local obj = table.Copy(ConvarGroupClass)
    obj.HookLabel = hookLabel
    obj.UlxLabel = ulxLabel
    obj:InitCustomVars()
    obj:SetupULib()
    return obj
end

function Convar(convarGroup, ttt2, name, default, tags, desc, type, min, max, decimal)
	if decimal == nil then
		decimal = 0
	end
    local obj = table.Copy(ConvarClass)
    obj.convarGroup = convarGroup
    obj.ttt2 = ttt2
	obj.name = name
	obj.default = default
	obj.tags = tags
	obj.desc = desc
	obj.type = type
	obj.min = min
	obj.max = max
	obj.decimal = decimal
	CreateConVar(name, default, tags, desc)
    table.insert(convarGroup.ListOfConvars, obj)
    tbl = tbl .. "[tr][td]" .. obj.name .. " (Def. " .. obj.default .. ")[/td][td]" .. obj.desc .. "[/td][/tr]"
	return obj
end