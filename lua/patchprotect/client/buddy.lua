-------------------------
--  BUDDY SQL SETTINGS --
-------------------------

-- Load Buddies
hook.Add('InitPostEntity', 'pprotect_load_buddies', function()
    if file.Exists('pprotect_buddies.txt', 'DATA') then
        local buds = util.JSONToTable(file.Read('pprotect_buddies.txt', 'DATA'))
        cl_PProtect.Buddies = buds

        net.Start('pprotect_buddy')
        net.WriteTable(cl_PProtect.Buddies)
        net.SendToServer()
    end
end)

-- Save Buddies
local function saveBuddies()
    file.Write('pprotect_buddies.txt', util.TableToJSON(cl_PProtect.Buddies))

    net.Start('pprotect_buddy')
    net.WriteTable(cl_PProtect.Buddies)
    net.SendToServer()
end

-- Reset Buddies
concommand.Add('pprotect_reset_buddies', function()
    cl_PProtect.Buddies = {}
    saveBuddies()
    print('[PProtect-Buddy] Successfully deleted all Buddies.')
end)

-- Initialize Buddy
local function initializeBuddy(bud)
    local id = bud:SteamID()
    if not cl_PProtect.Buddies[id] then
        cl_PProtect.Buddies[id] = {
            bud = false,
            perm = {phys = false, tool = false, use = false, prop = false, dmg = false}
        }
    end
    return id
end

-- Set Buddy
function cl_PProtect.setBuddy(bud, c)
    local id = initializeBuddy(bud)

    cl_PProtect.Buddies[id].bud = c

    if c then
        cl_PProtect.ClientNote('Added ' .. bud:Nick() .. ' to the Buddy-List.', 'info')

        -- Send message to buddy
        net.Start('pprotect_info_buddy')
        net.WriteEntity(bud)
        net.SendToServer()
    else
        cl_PProtect.ClientNote('Removed ' .. bud:Nick() .. ' from the Buddy-List.', 'info')
    end

    saveBuddies()
end

-- Set Buddy Permissions
function cl_PProtect.setBuddyPerm(bud, p, c)
    if not bud then return end
    local id = initializeBuddy(bud)

    cl_PProtect.Buddies[id].perm[p] = c

    saveBuddies()
end
