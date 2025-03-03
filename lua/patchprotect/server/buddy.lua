--  CHECK BUDDY  --
-------------------

function sv_PProtect.IsBuddy(ply, bud, mode)
  local buddySteamID = bud:SteamID()
  
  if not ply or not ply.Buddies or not bud:IsPlayer() or not ply.Buddies[buddySteamID] or not ply.Buddies[buddySteamID].bud then
    return false
  end
  
  local buddyData = ply.Buddies[buddySteamID]
  
  if not mode and buddyData.bud == true then
    return true
  elseif buddyData.bud == true and buddyData.perm[mode] == true then
    return true
  end
  
  return false
end

--------------------
--  SEND BUDDIES  --
--------------------

-- SEND BUDDY
net.Receive('pprotect_buddy', function(len, ply)
  ply.Buddies = net.ReadTable()
end)

-- NOTIFICATION
net.Receive('pprotect_info_buddy', function(len, ply)
  local bud = net.ReadEntity()
  sv_PProtect.Notify(bud, ply:Nick() .. ' added you as a buddy.', 'normal')
end)

-- SEND BUDDIES TO CLIENT
concommand.Add('pprotect_send_buddies', function(ply, cmd, args)
  local bud = player.GetByUniqueID(args[1])
  if not bud or not bud.Buddies then return end
  
  net.Start('pprotect_send_buddies')
    net.WriteBool(sv_PProtect.IsBuddy(ply, bud))
  net.Send(ply)
end)
