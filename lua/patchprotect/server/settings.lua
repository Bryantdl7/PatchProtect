----------------------
--  RESET SETTINGS  --
----------------------

local function resetSettings(ply, cmd, args, auto)
    local tabs = {'all', 'help', 'antispam', 'propprotection', 'blocked_props', 'blocked_ents', 'blocked_tools', 'antispam_tools'}

    if args[1] == 'help' then
        MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Use all, antispam, propprotection, blocked_props, blocked_ents, blocked_tools or antispam_tools.\n')
        return
    end

    if args[1] == 'all' then
        for _, value in pairs(tabs) do
            sql.Query('DROP TABLE IF EXISTS pprotect_' .. value)
        end
        if auto == 'auto' then return end
        MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Successfully deleted all sql-settings.\n', Color(255, 0, 0), '[PatchProtect-Reset]', Color(255, 255, 255), ' PLEASE RESTART YOUR SERVER.\n')
        return
    end

    if not table.HasValue(tabs, args[1]) then
        MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' ' .. args[1] .. ' is not a valid sql-table.\n')
        return
    end

    sql.Query('DROP TABLE IF EXISTS pprotect_' .. args[1])
    MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Successfully deleted all ' .. args[1] .. '-settings.\n', Color(255, 0, 0), '[PatchProtect-Reset]', Color(255, 255, 255), ' PLEASE RESTART THE SERVER WHEN YOU ARE FINISHED WITH ALL RESETS.\n')
end
concommand.Add('pprotect_reset', resetSettings)

---------------------
--  LOAD SETTINGS  --
---------------------

function sv_PProtect.loadSettings(name)
    local sqltable = 'pprotect_' .. string.lower(name)
    sql.Query('CREATE TABLE IF NOT EXISTS ' .. sqltable .. ' (setting TEXT, value TEXT)')

    local sql_settings = {}

    for setting, value in pairs(sv_PProtect.Config[name]) do
        if not sql.Query('SELECT value FROM ' .. sqltable .. ' WHERE setting = ' .. sql.SQLStr(setting)) then
            sql.Query('INSERT INTO ' .. sqltable .. ' (setting, value) VALUES (' .. sql.SQLStr(setting) .. ', ' .. sql.SQLStr(tostring(value)) .. ')')
        end

        sql_settings[setting] = sql.QueryValue('SELECT value FROM ' .. sqltable .. ' WHERE setting = ' .. sql.SQLStr(setting))
    end

    for setting, value in pairs(sql_settings) do
        if tonumber(value) then
            sql_settings[setting] = tonumber(value)
        elseif value == 'true' or value == 'false' then
            sql_settings[setting] = tobool(value)
        end
    end

    return sql_settings
end

function sv_PProtect.loadBlockedEnts(typ)
    if not sql.TableExists('pprotect_blocked_' .. typ) then return {} end

    local sql_ents = {}
    for _, ent in pairs(sql.Query('SELECT * FROM pprotect_blocked_' .. typ) or {}) do
        sql_ents[ent.name] = ent.model
    end

    return sql_ents
end

function sv_PProtect.loadBlockedTools(typ)
    if not sql.TableExists('pprotect_' .. typ .. '_tools') then return {} end

    local sql_tools = {}
    for _, tool in pairs(sql.Query('SELECT * FROM pprotect_' .. typ .. '_tools') or {}) do
        sql_tools[tool.tool] = tobool(tool.bool)
    end

    return sql_tools
end

local sql_version = '2.3'
if not sql.TableExists('pprotect_version') or sql.QueryValue('SELECT * FROM pprotect_version') ~= sql_version then
    resetSettings(nil, nil, {'all'}, 'auto')
    sql.Query('DROP TABLE IF EXISTS pprotect_version')
    sql.Query('CREATE TABLE IF NOT EXISTS pprotect_version (info TEXT)')
    sql.Query('INSERT INTO pprotect_version (info) VALUES (' .. sql.SQLStr(sql_version) .. ')')
    MsgC(Color(255, 0, 0), '\n[PatchProtect-Reset]', Color(255, 255, 255), ' Reset all sql-settings due to a new sql-table-version, sry.\nYou don\'t need to restart the server, but please check all settings. Thanks.\n')
end

sv_PProtect.Settings = {
    Antispam = sv_PProtect.loadSettings('Antispam'),
    Propprotection = sv_PProtect.loadSettings('Propprotection')
}

sv_PProtect.Blocked = {
    props = sv_PProtect.loadBlockedEnts('props'),
    ents = sv_PProtect.loadBlockedEnts('ents'),
    atools = sv_PProtect.loadBlockedTools('antispam'),
    btools = sv_PProtect.loadBlockedTools('blocked')
}

MsgC(Color(255, 255, 0), '\n[PatchProtect]', Color(255, 255, 255), ' Successfully loaded.\n\n')

---------------------
--  SAVE SETTINGS  --
---------------------

net.Receive('pprotect_save', function(len, pl)
    if not pl:IsSuperAdmin() then return end

    local data = net.ReadTable()
    sv_PProtect.Settings[data[1]] = data[2]
    sv_PProtect.sendSettings()

    for setting, value in pairs(sv_PProtect.Settings[data[1]]) do
        sql.Query('UPDATE pprotect_' .. string.lower(data[1]) .. ' SET value = ' .. sql.SQLStr(tostring(value)) .. ' WHERE setting = ' .. sql.SQLStr(setting))
    end

    sv_PProtect.Notify(pl, 'Saved new ' .. data[1] .. '-Settings', 'info')
    print('[PatchProtect - ' .. data[1] .. '] ' .. pl:Nick() .. ' saved new ' .. data[1] .. '-Settings.')
end)

function sv_PProtect.saveBlockedEnts(typ, data)
    sql.Query('DROP TABLE IF EXISTS pprotect_blocked_' .. typ)
    sql.Query('CREATE TABLE IF NOT EXISTS pprotect_blocked_' .. typ .. ' (name TEXT, model TEXT)')

    for n, m in pairs(data) do
        sql.Query('INSERT INTO pprotect_blocked_' .. typ .. ' (name, model) VALUES (' .. sql.SQLStr(n) .. ', ' .. sql.SQLStr(m) .. ')')
    end
end

function sv_PProtect.saveBlockedTools(typ, data)
    sql.Query('DROP TABLE IF EXISTS pprotect_' .. typ .. '_tools')
    sql.Query('CREATE TABLE IF NOT EXISTS pprotect_' .. typ .. '_tools (tool TEXT, bool TEXT)')

    for tool, bool in pairs(data) do
        sql.Query('INSERT INTO pprotect_' .. typ .. '_tools (tool, bool) VALUES (' .. sql.SQLStr(tool) .. ', ' .. sql.SQLStr(tostring(bool)) .. ')')
    end
end

---------------
--  NETWORK  --
---------------

function sv_PProtect.sendSettings(ply, cmd, args)
    local new_settings = {
        AntiSpam = sv_PProtect.Settings.Antispam,
        PropProtection = sv_PProtect.Settings.Propprotection
    }

    net.Start('pprotect_new_settings')
    net.WriteTable(new_settings)
    if args and args[1] then
        net.WriteString(args[1])
    end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

hook.Add('PlayerInitialSpawn', 'pprotect_playersettings', sv_PProtect.sendSettings)
concommand.Add('pprotect_request_new_settings', sv_PProtect.sendSettings)

function sv_PProtect.Notify(ply, text, typ)
    net.Start('pprotect_notify')
    net.WriteTable({text, typ})
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end
