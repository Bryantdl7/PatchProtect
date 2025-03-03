--  NETWORK STRINGS  --
----------------------

-- SETTINGS
local networkStrings = {
    'pprotect_new_settings',
    'pprotect_save',
    'pprotect_cleanup',
    'pprotect_new_counts',
    'pprotect_buddy',
    'pprotect_info_buddy',
    'pprotect_send_buddies',
    'pprotect_request_ents',
    'pprotect_send_ents',
    'pprotect_save_ents',
    'pprotect_save_cent',
    'pprotect_request_tools',
    'pprotect_send_tools',
    'pprotect_save_tools',
    'pprotect_notify'
}

for _, v in ipairs(networkStrings) do
    util.AddNetworkString(v)
end

----------------------
--  DEFAULT CONFIG  --
----------------------

sv_PProtect.Config = {
    Antispam = {
        enabled = true,
        admins = false,
        alert = true,
        prop = true,
        tool = true,
        toolblock = true,
        propblock = true,
        entblock = true,
        propinprop = true,
        cooldown = 0.3,
        spam = 2,
        spamaction = 'Nothing',
        bantime = 10,
        concommand = 'Put your command here'
    },
    Propprotection = {
        enabled = true,
        superadmins = true,
        admins = false,
        adminscleanup = false,
        use = true,
        reload = true,
        damage = true,
        damageinvehicle = true,
        gravgun = true,
        proppickup = true,
        creator = false,
        propdriving = false,
        worldpick = false,
        worlduse = true,
        worldtool = false,
        worldgrav = true,
        propdelete = true,
        adminprops = false,
        delay = 120
    }
}
