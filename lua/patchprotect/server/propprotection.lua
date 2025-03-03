----------------------
--  GENERAL CHECKS  --
----------------------

-- CHECK FOR PROP PROTECTION ADMIN CONDITIONS
function sv_PProtect.CheckPPAdmin(ply)
  -- allow if PatchProtect is disabled or for SuperAdmins (if enabled) or for Admins (if enabled)
  return not sv_PProtect.Settings.Propprotection['enabled'] or 
         (sv_PProtect.Settings.Propprotection['superadmins'] and ply:IsSuperAdmin()) or 
         (sv_PProtect.Settings.Propprotection['admins'] and ply:IsAdmin())
end

-- Checks if the given entity is a world prop and if players are allowed to interact with them for the given setting
-- ent: valid entity to check
-- sett: PatchProtect setting to use to check for world-premissions
function sv_PProtect.CheckWorld(ent, sett)
  -- if an entity has no owner, then set that entity as a world entity
  if not sh_PProtect.GetOwner(ent) and not ent:GetNWBool('pprotect_world') then
    ent:SetNWBool('pprotect_world', true)
  end

  return sv_PProtect.Settings.Propprotection['world' .. sett] and 
         (ent:IsWorld() or ent:GetNWBool('pprotect_world'))
end

-----------------
--  OWNERSHIP  --
-----------------

-- Set the owner for an entity
-- ent: valid entity which probably gets a new owner
-- ply: valid player which probably gets the new owner of ent
function sv_PProtect.SetOwner(ent, ply)
  -- Check if another addon may want to block the owner assignment
  if hook.Run('CPPIAssignOwnership', ply, ent, ply:UniqueID()) == false then return false end

  ent:SetNWEntity('pprotect_owner', ply)

  -- get all constrained entities and do the same for them
  for _, cent in pairs(constraint.GetAllConstrainedEntities(ent)) do
    -- if there is already an owner on a constrained entity set, don't overwrite it
    if not sh_PProtect.GetOwner(cent) then
      cent:SetNWEntity('pprotect_owner', ply)
    end
  end

  return true
end

-- Set the owner for multiple entities
-- ply: probably invalid player which probably gets the new owner of all ents
-- typ: defines, why given entities are existing
-- ents: table of valid entities which should get the new owner, or nil
function sv_PProtect.SetOwnerForEnts(ply, typ, ents)
  if not ents or not IsValid(ply) or not ply:IsPlayer() then return end

  -- if this is a duplication, we need to temporarily disable the AntiSpam feature
  -- as soon as there is not a duplicated entity, disable the duplication exception
  if ply.duplicate == true and typ != 'Duplicator' and not string.find(typ, 'AdvDupe') then
    ply.duplicate = false
  end

  -- set the new owner for all entities
  for _, ent in pairs(ents) do
    sv_PProtect.SetOwner(ent, ply)

    -- if the entity is a duplication or the PropInProp protection is disabled or the spawner is an admin (and accepted by PatchProtect) or it is not a physics prop, then don't check for penetrating props
    if ply.duplicate or not sv_PProtect.Settings.Antispam['propinprop'] or sv_PProtect.CheckPPAdmin(ply) or ent:GetClass() != 'prop_physics' then return end

    -- PropInProp-Protection
    if ent:GetPhysicsObject():IsPenetrating() then
      sv_PProtect.Notify(ply, 'You are not allowed to spawn a prop in another prop.')
      ent:Remove()
    end
  end
end

-- GET DATA
local en, uc, ue, up, uf = nil, undo.Create, undo.AddEntity, undo.SetPlayer, undo.Finish
function undo.Create(typ)
  en = {
    t = typ,
    e = {},
    o = nil
  }
  uc(typ)
end
function undo.AddEntity(ent)
  if IsValid(ent) and ent:GetClass() != 'phys_constraint' then
    table.insert(en.e, ent)
  end
  ue(ent)
end
function undo.SetPlayer(ply)
  en.o = ply
  up(ply)
end
function undo.Finish()
  sv_PProtect.SetOwnerForEnts(en.o, en.t, en.e)
  en = nil
  uf()
end

-------------------------------
--  PHYSGUN PROP PROTECTION  --
-------------------------------

function sv_PProtect.CanPhysgun(ply, ent)
  -- Check Entity
  if not IsValid(ent) then return false end

  -- Check Admin
  if sv_PProtect.CheckPPAdmin(ply) then return end

  -- Check Entity 2
  if ent:IsPlayer() then return false end

  -- Check World
  if sv_PProtect.CheckWorld(ent, 'pick') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'phys') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sv_PProtect.IsBuddy(owner, ply, 'phys') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to hold this object.')
  return false
end
hook.Add('PhysgunPickup', 'pprotect_touch', sv_PProtect.CanPhysgun)

----------------------------
--  TOOL PROP PROTECTION  --
----------------------------

function sv_PProtect.CanTool(ply, ent, tool)
  -- Check Entity
  if not IsValid(ent) then return false end

  -- Check Admin
  if sv_PProtect.CheckPPAdmin(ply) then return end

  -- Check Protection
  if tool == 'creator' and not sv_PProtect.Settings.Propprotection['creator'] then
    sv_PProtect.Notify(ply, 'You are not allowed to use the creator tool on this server.')
    return false
  end

  -- Check World
  if sv_PProtect.CheckWorld(ent, 'tool') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'tool') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sv_PProtect.IsBuddy(owner, ply, 'tool') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to use ' .. tool .. ' on this object.')
  return false
end

function sv_PProtect.CanToolTrace(ply, trace, tool)
  return sv_PProtect.CanTool(ply, trace.Entity, tool)
end
hook.Add('CanTool', 'pprotect_tool', sv_PProtect.CanToolTrace)

---------------------------
--  USE PROP PROTECTION  --
---------------------------

function sv_PProtect.CanUse(ply, ent)
  -- Check Protection and GameMode
  if not sv_PProtect.Settings.Propprotection['use'] or engine.ActiveGamemode() == 'prop_hunt' then return end

  -- Check Entity
  if not IsValid(ent) then return false end

  -- Check Admin
  if sv_PProtect.CheckPPAdmin(ply) then return end

  -- Check World
  if sv_PProtect.CheckWorld(ent, 'use') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'use') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sv_PProtect.IsBuddy(owner, ply, 'use') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to use this object.')
  return false
end
hook.Add('PlayerUse', 'pprotect_use', sv_PProtect.CanUse)

------------------------------
--  PROP PICKUP PROTECTION  --
------------------------------

function sv_PProtect.CanPickup(ply, ent)
  -- Check Protection
  if not sv_PProtect.Settings.Propprotection['proppickup'] then return end

  -- Check Entity
  if not IsValid(ent) then return false end

  -- Check Admin
  if sv_PProtect.CheckPPAdmin(ply) then return end

  -- Check World
  if sv_PProtect.CheckWorld(ent, 'use') then return end

  -- Check Shared
  if sh_PProtect.IsShared(ent, 'use') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if ply == owner or sv_PProtect.IsBuddy(owner, ply, 'use') then return end

  sv_PProtect.Notify(ply, 'You are not allowed to pick up this object.')
  return false
end
hook.Add('AllowPlayerPickup', 'pprotect_proppickup', sv_PProtect.CanPickup)

--------------------------------
--  PROPERTY PROP PROTECTION  --
--------------------------------

function sv_PProtect.CanProperty(ply, property, ent)
  -- Check Entity
  if not IsValid(ent) then return false end

  -- Check Admin
  if sv_PProtect.CheckPPAdmin(ply) then return end

  -- Check Persist
  if property == 'persist' then
    sv_PProtect.Notify(ply, 'You are not allowed to persist this object.')
    return false
  end

  -- Check World
  if sv_PProtect.CheckWorld(ent, 'pick') then return end

  -- Check Owner and Buddy
  local owner = sh_PProtect.GetOwner(ent)
  if
