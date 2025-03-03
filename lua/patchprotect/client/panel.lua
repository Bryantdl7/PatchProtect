-- Optimization for Anti-Spam Menu and other settings

-- Helper Function
local function addSettingsCheckbox(p, label, setting_key, tooltip)
  p:addchk(label, tooltip or nil, cl_PProtect.Settings.Antispam[setting_key], function(c)
    cl_PProtect.Settings.Antispam[setting_key] = c
  end)
end

-- Anti-Spam Menu
function cl_PProtect.as_menu(p)
  -- clear Panel
  p:ClearControls()

  -- Main Settings
  p:addlbl('General Settings:', true)
  addSettingsCheckbox(p, 'Enable AntiSpam', 'enabled')

  if cl_PProtect.Settings.Antispam.enabled then
    -- General
    addSettingsCheckbox(p, 'Ignore Admins', 'admins')
    addSettingsCheckbox(p, 'Admin-Alert Sound', 'alert')

    -- Anti-Spam features
    p:addlbl('\nEnable/Disable antispam features:', true)
    local features = {'prop', 'tool', 'toolblock', 'propblock', 'entblock', 'propinprop'}
    for _, feature in ipairs(features) do
      addSettingsCheckbox(p, feature:gsub("^%l", string.upper) .. '-AntiSpam', feature)
    end

    -- Tool Protection
    if cl_PProtect.Settings.Antispam.tool then
      p:addbtn('Set antispamed Tools', 'pprotect_request_tools', {'antispam'})
    end

    -- Tool Block
    if cl_PProtect.Settings.Antispam.toolblock then
      p:addbtn('Set blocked Tools', 'pprotect_request_tools', {'blocked'})
    end

    -- Prop Block
    if cl_PProtect.Settings.Antispam.propblock then
      p:addbtn('Set blocked Props', 'pprotect_request_ents', {'props'})
    end

    -- Ent Block
    if cl_PProtect.Settings.Antispam.entblock then
      p:addbtn('Set blocked Entities', 'pprotect_request_ents', {'ents'})
    end

    -- Cooldown and Spam Action
    p:addlbl('\nDuration till the next prop-spawn/tool-fire:', true)
    p:addsld(0, 10, 'Cooldown (Seconds)', cl_PProtect.Settings.Antispam.cooldown, 'Antispam', 'cooldown', 1)
    p:addlbl('Number of props till admins get warned:')
    p:addsld(0, 40, 'Amount', cl_PProtect.Settings.Antispam.spam, 'Antispam', 'spam', 0)
    p:addlbl('Automatic action after spamming:')
    p:addcmb({'Nothing', 'Cleanup', 'Kick', 'Ban', 'Command'}, 'spamaction', cl_PProtect.Settings.Antispam.spamaction)

    -- Spam action details
    if cl_PProtect.Settings.Antispam.spamaction == 'Ban' then
      p:addsld(0, 60, 'Ban (Minutes)', cl_PProtect.Settings.Antispam.bantime, 'Antispam', 'bantime', 0)
    elseif cl_PProtect.Settings.Antispam.spamaction == 'Command' then
      p:addlbl("Use '<player>' to use the spamming player.")
      p:addlbl("Some commands need sv_cheats 1 to run,\nlike 'kill <player>'")
      p:addtxt(cl_PProtect.Settings.Antispam.concommand)
    end
  end

  -- Save Settings
  p:addbtn('Save Settings', 'pprotect_save', {'Antispam'})
end

-- Other menus...

-- Create Menus function
local function CreateMenus()
  local menus = {
    {name='AntiSpam', func='as'},
    {name='PropProtection', func='pp'},
    {name='Buddy', func='b'},
    {name='Cleanup', func='cu'},
    {name='Client Settings', func='cs'}
  }
  for _, menu in ipairs(menus) do
    spawnmenu.AddToolMenuOption('Utilities', 'PatchProtect', 'PP'..menu.name, menu.name, '', '', function(p)
      cl_PProtect.UpdateMenus(menu.func, p)
    end)
  end
end
hook.Add('PopulateToolMenu', 'pprotect_make_menus', CreateMenus)

-- Define UpdateMenus function in a scope where it is accessible
local function showErrorMessage(p, msg)
  p:ClearControls()
  p:addlbl(msg)
end

local pans = {}
function cl_PProtect.UpdateMenus(p_type, panel)
  -- add Panel
  if p_type and not pans[p_type] then
    pans[p_type] = panel
  end

  -- load Panel
  for t, p in pairs(pans) do
    if t == 'as' or t == 'pp' then
      if LocalPlayer():IsSuperAdmin() then
        RunConsoleCommand('pprotect_request_new_settings', t)
      else
        showErrorMessage(pans[t], 'Sorry, you need to be a SuperAdmin to change\nthe settings.')
      end
    elseif t == 'cu' then
      if LocalPlayer():IsSuperAdmin() or (LocalPlayer():IsAdmin() and cl_PProtect.Settings.Propprotection.adminscleanup) then
        RunConsoleCommand('pprotect_request_new_counts')
      else
        showErrorMessage(pans[t], 'Sorry, you need to be a Admin/SuperAdmin to\nchange the settings.')
      end
    else
      cl_PProtect[t .. '_menu'](pans[t])
    end
  end
end
hook.Add('SpawnMenuOpen', 'pprotect_update_menus', cl_PProtect.UpdateMenus)
