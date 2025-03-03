local Owner, IsWorld, IsShared, IsBuddy, LastID
local Note = { msg = '', typ = '', time = 0, alpha = 0 }
local scr_w, scr_h = ScrW(), ScrH()

------------------
--  PROP OWNER  --
------------------

function cl_PProtect.showOwner()
    if not cl_PProtect.Settings.Propprotection['enabled'] or not cl_PProtect.Settings.CSettings['ownerhud'] or not LocalPlayer():Alive() then return end

    local ent = LocalPlayer():GetEyeTrace().Entity
    if not ent or not ent:IsValid() or ent:IsWorld() or ent:IsPlayer() then return end

    if LastID ~= ent:EntIndex() or (not Owner and not IsWorld) then
        Owner, IsWorld, IsShared, IsBuddy = ent:GetNWEntity('pprotect_owner'), ent:GetNWBool('pprotect_world'), false, false
        if Owner and Owner:IsValid() and Owner ~= LocalPlayer() and not IsWorld then
            RunConsoleCommand('pprotect_send_buddies', Owner:UniqueID())
        end

        for _, v in ipairs({'phys', 'tool', 'use', 'dmg'}) do
            if ent:GetNWBool('pprotect_shared_' .. v) then
                IsShared = true
            end
        end

        LastID = ent:EntIndex()
    end

    local txt = 'No Owner'
    if IsWorld then
        txt = 'World'
    elseif Owner and Owner:IsValid() and Owner:IsPlayer() then
        txt = Owner:Nick()
        if not table.HasValue(player.GetAll(), Owner) then
            txt = txt .. ' (disconnected)'
        elseif IsBuddy then
            txt = txt .. ' (Buddy)'
        elseif IsShared then
            txt = txt .. ' (Shared)'
        end
    end

    surface.SetFont(cl_PProtect.setFont('roboto', 14, 500, true))
    local w = surface.GetTextSize(txt) + 10
    local l, t = scr_w - w - 20, scr_h * 0.5

    local col = (Owner == LocalPlayer() or LocalPlayer():IsAdmin() or LocalPlayer():IsSuperAdmin() or IsBuddy or IsShared or 
                (IsWorld and cl_PProtect.Settings.Propprotection['worldpick']) or txt == 'No Owner') and 
                Color(128, 255, 0, 200) or 
                (IsWorld and (cl_PProtect.Settings.Propprotection['worlduse'] or cl_PProtect.Settings.Propprotection['worldtool'])) and 
                Color(0, 161, 222, 200) or 
                Color(176, 0, 0, 200)

    if not cl_PProtect.Settings.CSettings['fppmode'] then
        draw.RoundedBoxEx(4, l - 5, t - 12, 5, 24, col, true, false, true, false)
        draw.RoundedBoxEx(4, l, t - 12, w, 24, Color(240, 240, 240, 200), false, true, false, true)
        draw.SimpleText(txt, cl_PProtect.setFont('roboto', 14, 500, true), l + 5, t - 6, Color(75, 75, 75))
    else
        draw.RoundedBox(4, scr_w * 0.5 - (w * 0.5), t + 16, w, 20, Color(0, 0, 0, 150))
        draw.SimpleText(txt, cl_PProtect.setFont('roboto', 14, 500, true), scr_w * 0.5, t + 20, col, TEXT_ALIGN_CENTER, 0)
    end
end
hook.Add('HUDPaint', 'pprotect_owner', cl_PProtect.showOwner)

------------------------
--  PHYSGUN BEAM FIX  --
------------------------

local function PhysBeam(ply, ent)
    return false
end
hook.Add('PhysgunPickup', 'pprotect_physbeam', PhysBeam)

----------------------------
--  ADD BLOCKED PROP/ENT  --
----------------------------

properties.Add('addblockedprop', {
    MenuLabel = 'Add to Blocked-List',
    Order = 2002,
    MenuIcon = 'icon16/page_white_edit.png',
    Filter = function(self, ent, ply)
        local typ = ent:GetClass() ~= 'prop_physics' and 'ent' or 'prop'
        return cl_PProtect.Settings.Antispam['enabled'] and cl_PProtect.Settings.Antispam[typ .. 'block'] and LocalPlayer():IsSuperAdmin() and ent:IsValid() and not ent:IsPlayer()
    end,
    Action = function(self, ent)
        net.Start('pprotect_save_cent')
        net.WriteTable({
            typ = ent:GetClass() == 'prop_physics' and 'props' or 'ents',
            name = ent:GetClass() == 'prop_physics' and ent:GetModel() or ent:GetClass(),
            model = ent:GetModel()
        })
        net.SendToServer()
    end
})

---------------------
--  SHARED ENTITY  --
---------------------

properties.Add('shareentity', {
    MenuLabel = 'Share entity',
    Order = 2003,
    MenuIcon = 'icon16/group.png',
    Filter = function(self, ent, ply)
        return ent:IsValid() and cl_PProtect.Settings.Propprotection['enabled'] and not ent:IsPlayer() and (LocalPlayer():IsSuperAdmin() or Owner == LocalPlayer())
    end,
    Action = function(self, ent)
        local shared_info = {}
        for _, v in ipairs({'phys', 'tool', 'use', 'dmg'}) do
            shared_info[v] = ent:GetNWBool('pprotect_shared_' .. v)
        end

        local frm = cl_PProtect.addfrm(180, 165, 'share prop:', false)
        frm:addchk('Physgun', nil, shared_info['phys'], function(c) ent:SetNWBool('pprotect_shared_phys', c) end)
        frm:addchk('Toolgun', nil, shared_info['tool'], function(c) ent:SetNWBool('pprotect_shared_tool', c) end)
        frm:addchk('Use', nil, shared_info['use'], function(c) ent:SetNWBool('pprotect_shared_use', c) end)
        frm:addchk('Damage', nil, shared_info['dmg'], function(c) ent:SetNWBool('pprotect_shared_dmg', c) end)
    end
})

----------------
--  MESSAGES  --
----------------

local function DrawNote()
    if Note.msg == '' or Note.time + 5 < SysTime() then return end

    Note.alpha = Note.time + 0.5 > SysTime() and math.Clamp(Note.alpha + 10, 0, 255) or 
                SysTime() > Note.time + 4.5 and math.Clamp(Note.alpha - 10, 0, 255) or 
                Note.alpha

    surface.SetFont(cl_PProtect.setFont('roboto', 18, 500, true))
    local tw, th = surface.GetTextSize(Note.msg)
    local w, h, x, y = tw + 20, th + 20, ScrW() - tw - 40, ScrH() - th - 20
    local alpha, bcol = Note.alpha, Note.typ == 'info' and Color(128, 255, 0, alpha) or Note.typ == 'admin' and Color(176, 0, 0, alpha) or Color(88, 144, 222, alpha)

    draw.RoundedBox(0, x - h, y, h, h, bcol)
    draw.RoundedBox(0, x, y, w, h, Color(240, 240, 240, alpha))
    draw.SimpleText('i', cl_PProtect.setFont('roboto', 36, 1000, true), x - 23, y + 2, Color(255, 255, 255, alpha))
    
    local tri = {
        { x = x, y = y + (h * 0.5) - 6 },
        { x = x + 5, y = y + (h * 0.5) },
        { x = x, y = y + (h * 0.5) + 6 }
    }
    surface.SetDrawColor(bcol)
    draw.NoTexture()
    surface.DrawPoly(tri)
    draw.SimpleText(Note.msg, cl_PProtect.setFont('roboto', 18, 500, true), x + 10, y + 10, Color(75, 75, 75, alpha))
end
hook.Add('HUDPaint', 'pprotect_drawnote', DrawNote)

function cl_PProtect.ClientNote(msg, typ)
    if not cl_PProtect.Settings.CSettings['notes'] then return end

    local al = Note.alpha > 0 and 255 or 0
    Note = { msg = msg, typ = typ, time = SysTime(), alpha = al }

    LocalPlayer():EmitSound(Note.typ == 'info' and 'buttons/button9.wav' or 'ambient/alarms/klaxon1.wav', 100, 100)
end

---------------
--  NETWORK  --
---------------
