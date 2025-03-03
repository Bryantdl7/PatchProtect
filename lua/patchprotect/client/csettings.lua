-----------------------
--  CLIENT SETTINGS  --
-----------------------

-- Delete old settings version
if sql.QueryValue("SELECT value FROM pprotect_csettings WHERE setting = 'OwnerHUD'") == '1' then
    sql.Query('DROP TABLE IF EXISTS pprotect_csettings')
end

-- Create SQL-CSettings-Table
if not sql.TableExists('pprotect_csettings') then
    sql.Query('CREATE TABLE IF NOT EXISTS pprotect_csettings (setting TEXT, value TEXT)')
end

-- Set default CSettings
local csettings_default = {
    ownerhud = true,
    fppmode = false,
    notes = true
}

-- Check/Load SQL-CSettings
for setting, value in pairs(csettings_default) do
    local v = sql.QueryValue("SELECT value FROM pprotect_csettings WHERE setting = " .. sql.SQLStr(setting))
    if not v then
        sql.Query("INSERT INTO pprotect_csettings (setting, value) VALUES (" .. sql.SQLStr(setting) .. ", " .. sql.SQLStr(tostring(value)) .. ")")
        cl_PProtect.Settings.CSettings[setting] = value
    else
        cl_PProtect.Settings.CSettings[setting] = tobool(v)
    end
end

-- Update CSettings
function cl_PProtect.update_csetting(setting, value)
    sql.Query("UPDATE pprotect_csettings SET value = " .. sql.SQLStr(tostring(value)) .. " WHERE setting = " .. sql.SQLStr(setting))
    cl_PProtect.Settings.CSettings[setting] = value
end

-- Reset CSettings
concommand.Add('pprotect_reset_csettings', function(ply, cmd, args)
    sql.Query('DROP TABLE IF EXISTS pprotect_csettings')
    print('[PProtect-CSettings] Successfully deleted all Client Settings.')
    print('[PProtect-CSettings] PLEASE RECONNECT TO GET A NEW TABLE.')
end)
