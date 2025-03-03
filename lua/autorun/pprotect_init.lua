--------------------------------
--  LOAD SERVER/CLIENT FILES  --
--------------------------------

-- Create shared table
sh_PProtect = {}

-- Include shared files
include('patchprotect/shared/patchprotect.lua')

if SERVER then
  -- Create server table
  sv_PProtect = {
    Settings = {}
  }

  -- Include server files
  local serverFiles = {
    'patchprotect/server/config.lua',
    'patchprotect/server/settings.lua',
    'patchprotect/server/antispam.lua',
    'patchprotect/server/propprotection.lua',
    'patchprotect/server/cleanup.lua',
    'patchprotect/server/buddy.lua'
  }

  for _, file in ipairs(serverFiles) do
    include(file)
  end

  -- Force clients to download all client files
  AddCSLuaFile()

  local clientFiles = {
    'patchprotect/client/csettings.lua',
    'patchprotect/client/fonts.lua',
    'patchprotect/client/hud.lua',
    'patchprotect/client/derma.lua',
    'patchprotect/client/panel.lua',
    'patchprotect/client/buddy.lua'
  }

  for _, file in ipairs(clientFiles) do
    AddCSLuaFile(file)
  end

  -- Force clients to download all shared files
  AddCSLuaFile('patchprotect/shared/patchprotect.lua')
else
  -- Create client table
  cl_PProtect = {
    Settings = {
      Antispam = {},
      Propprotection = {},
      CSettings = {}
    },
    Buddies = {}
  }

  -- Include client files
  local clientFiles = {
    'patchprotect/client/csettings.lua',
    'patchprotect/client/fonts.lua',
    'patchprotect/client/hud.lua',
    'patchprotect/client/derma.lua',
    'patchprotect/client/panel.lua',
    'patchprotect/client/buddy.lua'
  }

  for _, file in ipairs(clientFiles) do
    include(file)
  end
end
