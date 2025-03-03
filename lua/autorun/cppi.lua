CPPI = CPPI or {}

CPPI.CPPI_DEFER = 8080 -- PP (PathProtect)
CPPI.CPPI_NOTIMPLEMENTED = 012019 -- month/year of newest version

local PLAYER = FindMetaTable('Player')
local ENTITY = FindMetaTable('Entity')

-- Get name of prop protection
function CPPI:GetName()
  return 'PatchProtect'
end

-- Get version of prop protection
function CPPI:GetVersion()
  return '1.4.0'
end

-- Get interface version of CPPI
function CPPI:GetInterfaceVersion()
  return 1.3
end

-- Get name of player from UID
function CPPI:GetNameFromUID(uid)
  local ply = player.GetByUniqueID(uid)
  return ply and ply:Nick() or nil
end

-- Get friends from a player
function PLAYER:CPPIGetFriends()
  if CLIENT then return CPPI.CPPI_NOTIMPLEMENTED end -- TODO: add this for client side (maybe only for local player)
  return self.Buddies or {}
end

-- Get the owner of an entity
function ENTITY:CPPIGetOwner()
  local ply = sh_PProtect.GetOwner(self)
  if IsValid(ply) and ply:IsPlayer() then
    return ply, ply:UniqueID()
  end
  return nil, nil
end

if CLIENT then return end

-- Set owner of an entity
function ENTITY:CPPISetOwner(ply)
  if IsValid(ply) and ply:IsPlayer() then
    return sv_PProtect.SetOwner(self, ply)
  end
  return false
end

-- Set owner of an entity by UID
function ENTITY:CPPISetOwnerUID(uid)
  local ply = player.GetByUniqueID(uid)
  return ply and self:CPPISetOwner(ply) or false
end

-- Set entity to no world (true) or not even world (false)
function ENTITY:CPPISetOwnerless(bool)
  if not IsValid(self) then return false end

  self:SetNWEntity('pprotect_owner', nil)
  self:SetNWBool('pprotect_world', bool)

  return true
end

-- Define entity permission check functions
local function definePermissionCheck(name, func)
  ENTITY[name] = function(self, ply, ...)
    return func(ply, self, ...)
  end
end

definePermissionCheck('CPPICanTool', sv_PProtect.CanTool)
definePermissionCheck('CPPICanPhysgun', sv_PProtect.CanPhysgun)
definePermissionCheck('CPPICanPickup', sv_PProtect.CanPickup)
definePermissionCheck('CPPICanPunt', sv_PProtect.CanGravPunt)
definePermissionCheck('CPPICanUse', sv_PProtect.CanUse)
definePermissionCheck('CPPICanDamage', sv_PProtect.CanDamage)
definePermissionCheck('CPPICanDrive', sv_PProtect.CanDrive)
definePermissionCheck('CPPICanProperty', sv_PProtect.CanProperty)

-- Can edit variable
function ENTITY:CPPICanEditVariable(ply, key, val, edit)
  return CPPI.CPPI_NOTIMPLEMENTED -- TODO
end
