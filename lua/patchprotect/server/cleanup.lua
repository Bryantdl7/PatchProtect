--  COUNT PROPS  --
-------------------

local function countProps(ply, dels)
    local result = { global = 0, players = {} }
    for _, ent in ipairs(ents.GetAll()) do
        if not ent:IsValid() then continue end
        local o = sh_PProtect.GetOwner(ent)
        if ent:GetNWBool('pprotect_world') or not o or isnumber(o) or not o:IsValid() then continue end
        if istable(dels) and table.HasValue(dels, ent:EntIndex()) then continue end

        -- Global-Count
        result.global = result.global + 1

        -- Player-Count
        result.players[o] = (result.players[o] or 0) + 1
    end
    net.Start('pprotect_new_counts')
    net.WriteTable(result)
    net.Send(ply)
end
concommand.Add('pprotect_request_new_counts', countProps)

---------------------
--  CLEANUP PROPS  --
---------------------

-- Cleanup Map
local function cleanupMap(typ, ply)
    game.CleanUpMap()  -- cleanup map
    sv_PProtect.setWorldProps()  -- set world props
    if typ then countProps(ply) end  -- count props
    if not ply:IsValid() then
        print('[PatchProtect - Cleanup] Removed all props.')
    else
        sv_PProtect.Notify(ply, 'Cleaned Map.', 'info')
        print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed all props.')
    end
end

-- Cleanup Disconnected Players Props
local function cleanupDisc(ply)
    local del_ents = {}
    for _, ent in ipairs(ents.GetAll()) do
        if ent.pprotect_cleanup then
            ent:Remove()
            table.insert(del_ents, ent:EntIndex())
        end
    end
    sv_PProtect.Notify(ply, 'Removed all props from disconnected players.', 'info')
    print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed all props from disconnected players.')
end

-- Cleanup Players Props
local function cleanupPly(pl, c, ply)
    local del_ents = {}
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetNWEntity('pprotect_owner') == pl then
            ent:Remove()
            table.insert(del_ents, ent:EntIndex())
        end
    end
    sv_PProtect.Notify(ply, 'Cleaned ' .. pl:Nick() .. "'s props. (" .. tostring(c) .. ')', 'info')
    print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed ' .. tostring(c) .. ' props from ' .. pl:Nick() .. '.')
    countProps(pl, del_ents)
end

-- Cleanup Unowned Props
local function cleanupUnowned(ply)
    for _, ent in ipairs(ents.GetAll()) do
        if ent:IsValid() and not sh_PProtect.GetOwner(ent) and not ent:GetNWBool('pprotect_world') and string.find(ent:GetClass(), 'prop_') then
            ent:Remove()
        end
    end
    sv_PProtect.Notify(ply, 'Removed all unowned props.', 'info')
    print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' removed all unowned props.')
end

-- General Cleanup-Function
function sv_PProtect.Cleanup(typ, ply)
    -- check permissions
    if ply:IsValid() and (not sv_PProtect.Settings.Propprotection['adminscleanup'] or not ply:IsAdmin()) and not ply:IsSuperAdmin() then
        sv_PProtect.Notify(ply, 'You are not allowed to clean the map.')
        return
    end
    -- get cleanup-type
    local d = not isstring(typ) and net.ReadTable() or {}
    typ = isstring(typ) and typ or d[1]
    if typ == 'all' then cleanupMap(d[1], ply)
    elseif typ == 'disc' then cleanupDisc(ply)
    elseif typ == 'ply' then cleanupPly(d[2], d[3], ply)
    elseif typ == 'unowned' then cleanupUnowned(ply)
    end
end

net.Receive('pprotect_cleanup', sv_PProtect.Cleanup)
concommand.Add('gmod_admin_cleanup', function(ply, cmd, args)
    sv_PProtect.Cleanup('all', ply)
end)

----------------------------------------
--  CLEAR DISCONNECTED PLAYERS PROPS  --
----------------------------------------

-- PLAYER LEFT SERVER
local function setCleanup(ply)
    if not sv_PProtect.Settings.Propprotection['enabled'] or not sv_PProtect.Settings.Propprotection['propdelete'] then return end
    if sv_PProtect.Settings.Propprotection['adminprops'] and (ply:IsSuperAdmin() or ply:IsAdmin()) then return end

    print('[PatchProtect - Cleanup] ' .. ply:Nick() .. ' left the server. Props will be deleted in ' .. tostring(sv_PProtect.Settings.Propprotection['delay']) .. ' seconds.')
    for _, v in ipairs(ents.GetAll()) do
        if v:CPPIGetOwner() and v:CPPIGetOwner():UniqueID() == ply:UniqueID() then
            v.pprotect_cleanup = ply:Nick()
        end
    end
    local nick = ply:Nick()
    timer.Create('pprotect_cleanup_' .. nick, sv_PProtect.Settings.Propprotection['delay'], 1, function()
        for _, v in ipairs(ents.GetAll()) do
            if v.pprotect_cleanup == nick then
                v:Remove()
            end
        end
        print('[PatchProtect - Cleanup] Removed ' .. nick .. 's Props. (Reason: Left the Server)')
    end)
end

hook.Add('PlayerDisconnected', 'pprotect_playerdisconnected', setCleanup)

-- PLAYER CAME BACK
local function abortCleanup(ply)
    if not timer.Exists('pprotect_cleanup_' .. ply:Nick()) then return end

    print('[PatchProtect - Cleanup] Abort Cleanup. ' .. ply:Nick() .. ' came back.')
    timer.Destroy('pprotect_cleanup_' .. ply:Nick())
    for _, v in ipairs(ents.GetAll()) do
        if v:CPPIGetOwner() and v:CPPIGetOwner():UniqueID() == ply:UniqueID() then
            v.pprotect_cleanup = nil
            v:CPPISetOwner(ply)
        end
    end
end

hook.Add('PlayerSpawn', 'pprotect_abortcleanup', abortCleanup)
