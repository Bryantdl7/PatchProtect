-- Setup Player Variables
function sv_PProtect.Setup(ply)
    ply.propcooldown = 0
    ply.props = 0
    ply.toolcooldown = 0
    ply.tools = 0
    ply.duplicate = false
end
hook.Add('PlayerInitialSpawn', 'pprotect_initialspawn', sv_PProtect.Setup)

-- Check AntiSpam Admin Privileges
function sv_PProtect.CheckASAdmin(ply)
    if not IsValid(ply) then return false end
    return sv_PProtect.Settings.Antispam['enabled'] and not ply:IsSuperAdmin() and (not ply:IsAdmin() or not sv_PProtect.Settings.Antispam['admins'])
end

-- Handle Spam Actions
function sv_PProtect.spamaction(ply)
    local action = sv_PProtect.Settings.Antispam['spamaction']
    local name = ply:Nick()

    if action == 'Cleanup' then
        cleanup.CC_Cleanup(ply, '', {})
        sv_PProtect.Notify(ply, 'Cleaned all your props. (Reason: spamming)')
    elseif action == 'Kick' then
        ply:Kick('Kicked by PatchProtect. (Reason: spamming)')
    elseif action == 'Ban' then
        local mins = sv_PProtect.Settings.Antispam['bantime']
        ply:Ban(mins, 'Banned by PatchProtect. (Reason: spamming)')
    elseif action == 'Command' then
        local cmd = string.Replace(sv_PProtect.Settings.Antispam['concommand'], '<player>', ply:SteamID())
        RunConsoleCommand(unpack(string.Explode(' ', cmd)))
    end

    local actionMessages = {
        Cleanup = 'Cleaned all your props. (Reason: spamming)',
        Kick = 'Kicked ' .. name .. '. (Reason: spamming)',
        Ban = 'Banned ' .. name .. ' for ' .. mins .. ' minutes. (Reason: spamming)',
        Command = "Ran console command '" .. cmd .. "'. (Reason: reached spam limit)"
    }

    sv_PProtect.Notify(nil, actionMessages[action], 'admin')
    print('[PatchProtect - AntiSpam] ' .. actionMessages[action])
end

-- Handle AntiSpam for Prop/Entity Spawning
function sv_PProtect.CanSpawn(ply, mdl)
    if sv_PProtect.CheckASAdmin(ply) or ply.duplicate then return end
    mdl = string.lower(mdl)
    
    if string.find(mdl, '/../') or sv_PProtect.Blocked.props[mdl] or sv_PProtect.Blocked.ents[mdl] then
        sv_PProtect.Notify(ply, 'This object is not allowed.')
        return false
    end

    if not sv_PProtect.Settings.Antispam['prop'] then return end

    if CurTime() > ply.propcooldown then
        ply.props = 0
        ply.propcooldown = CurTime() + sv_PProtect.Settings.Antispam['cooldown']
        return
    end

    ply.props = ply.props + 1
    sv_PProtect.Notify(ply, 'Please wait ' .. math.Round(ply.propcooldown - CurTime(), 1) .. ' seconds', 'normal')

    if ply.props >= sv_PProtect.Settings.Antispam['spam'] then
        ply.props = 0
        sv_PProtect.spamaction(ply)
    end

    return false
end

local spawnHooks = {
    'PlayerSpawnProp', 'PlayerSpawnEffect', 'PlayerSpawnSENT',
    'PlayerSpawnRagdoll', 'PlayerSpawnVehicle', 'PlayerSpawnNPC',
    'PlayerSpawnSWEP'
}
for _, hookName in ipairs(spawnHooks) do
    hook.Add(hookName, 'pprotect_' .. hookName, sv_PProtect.CanSpawn)
end

-- Handle AntiSpam for Tool Usage
function sv_PProtect.CanUseTool(ply, trace, tool)
    if sv_PProtect.CheckASAdmin(ply) then return end

    if sv_PProtect.Blocked.btools[tool] then
        sv_PProtect.Notify(ply, 'This tool is in the blacklist.', 'normal')
        return false
    end

    ply.duplicate = tool:find('duplicator') or tool:find('adv_duplicator')

    if not sv_PProtect.Settings.Antispam['tool'] or not sv_PProtect.Blocked.atools[tool] then return end

    if CurTime() > ply.toolcooldown then
        ply.tools = 0
        ply.toolcooldown = CurTime() + sv_PProtect.Settings.Antispam['cooldown']
        return
    end

    ply.tools = ply.tools + 1
    sv_PProtect.Notify(ply, 'Please wait ' .. math.Round(ply.toolcooldown - CurTime(), 1) .. ' seconds', 'normal')

    if ply.tools >= sv_PProtect.Settings.Antispam['spam'] then
        ply.tools = 0
        sv_PProtect.spamaction(ply)
    end

    return false
end
hook.Add('CanTool', 'pprotect_tool_antispam', sv_PProtect.CanUseTool)

-- Handle Blocked Props/Entities Communication
local function handleBlockedEntities(netMsg, action)
    net.Receive(netMsg, function(_, ply)
        if not ply:IsSuperAdmin() then return end
        local data = net.ReadTable()
        action(ply, data)
    end)
end

handleBlockedEntities('pprotect_request_ents', function(ply, typ)
    net.Start('pprotect_send_ents')
    net.WriteString(typ[1])
    net.WriteTable(sv_PProtect.Blocked[typ[1]])
    net.Send(ply)
end)

handleBlockedEntities('pprotect_save_ents', function(ply, data)
    sv_PProtect.Blocked[data[1]][data[2]] = nil
    sv_PProtect.saveBlockedEnts(data[1], sv_PProtect.Blocked[data[1]])
    print('[PatchProtect - AntiSpam] ' .. ply:Nick() .. ' removed ' .. data[2] .. ' from the blocked-' .. data[1] .. '-list.')
end)

handleBlockedEntities('pprotect_save_cent', function(ply, ent)
    local typ, name, model = ent.typ, ent.name, string.lower(ent.model)
    if sv_PProtect.Blocked[typ][name] then
        sv_PProtect.Notify(ply, 'This object is already in the ' .. typ .. '-list.', 'info')
        return
    end
    sv_PProtect.Blocked[typ][name] = model
    sv_PProtect.saveBlockedEnts(typ, sv_PProtect.Blocked[typ])
    sv_PProtect.Notify(ply, 'Saved ' .. name .. ' to blocked-' .. typ .. '-list.', 'info')
    print('[PatchProtect - AntiSpam] ' .. ply:Nick() .. ' added ' .. name .. ' to the blocked-' .. typ .. '-list.')
end)

-- Import Blocked Props List
concommand.Add('pprotect_import_blocked_props', function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end

    local filePath = 'pprotect_import_blocked_props.txt'
    if not file.Read(filePath, 'DATA') then
        print("Cannot find 'pprotect_import_blocked_props.txt' to import props. Please read the description of PatchProtect.")
        return
    end

    for _, model in ipairs(string.Explode(';', file.Read(filePath, 'DATA'))) do
        if model ~= '' then
            model = string.lower(string.sub(model, string.find(model, 'models/'), string.find(model, ';')))
            if util.IsValidModel(model) and not sv_PProtect.Blocked.props[model] then
                sv_PProtect.Blocked.props[model] = model
            end
        end
    end

    sv_PProtect.saveBlockedEnts('props', sv_PProtect.Blocked.props)
    print("\n[PatchProtect] Imported all blocked props. If you experience any errors,\nthen use the command to reset the whole blocked-props-list:\n'pprotect_reset blocked_props'\n")
end)

-- Handle AntiSpammed/Blocked Tools Communication
handleBlockedEntities('pprotect_request_tools', function(ply, t)
    local tools = {}
    for _, wep in ipairs(weapons.GetList()) do
        if wep.ClassName == 'gmod_tool' then
            for name in pairs(wep.Tool) do
                tools[name] = false
            end
        end
    end
    for name, value in pairs(sv_PProtect.Blocked[t[1] .. 'tools']) do
        tools[name] = value
    end
    net.Start('pprotect_send_tools')
    net.WriteString(t[1] .. 'tools')
    net.WriteTable(tools)
    net.Send(ply)
end)

handleBlockedEntities('pprotect_save_tools', function(ply, d)
    sv_PProtect.Blocked[d[1]][d[3]] = d[4]
    sv_PProtect.saveBlockedTools(d[2], sv_PProtect.Blocked[d[1]])
    print('[PatchProtect - AntiSpam] ' .. ply:Nick() .. ' set "' .. d[3] .. '" from ' .. d[2] .. '-tools-list to "' .. tostring(d[4]) ..
