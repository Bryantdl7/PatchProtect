local Owner
local IsBuddy
local IsWorld
local IsDisconnected
local lastid
cl_PProtect.Note = { msg = "", typ = "", time = 0, alpha = 0 }



-------------
--  FONTS  --
-------------

surface.CreateFont( "pprotect_roboto", {
	font 		= "Roboto",
	size 		= 15,
	weight 		= 750,
	antialias 	= true,
	shadow 		= false
} )

surface.CreateFont( "pprotect_roboto_small", {
	font 		= "Roboto",
	size 		= 14,
	weight 		= 500,
	antialias 	= true,
	shadow 		= false
} )

surface.CreateFont( "pprotect_note", {
	font 		= "Roboto",
	size 		= 18,
	weight 		= 500,
	antialias 	= true,
	shadow 		= false
} )

surface.CreateFont( "pprotect_note_big", {
	font 		= "Roboto",
	size 		= 36,
	weight 		= 1000,
	antialias 	= true,
	shadow 		= false
} )



------------------
--  PROP OWNER  --
------------------

-- SHOW OWNER
function cl_PProtect.showOwner()
	
	if cl_PProtect.Settings.Propprotection[ "enabled" ] == 0 or !LocalPlayer():Alive() then return end
	if cl_PProtect.Settings.CSettings[ "OwnerHUD" ] == 0 then return end

	-- Check Entity
	local ent = LocalPlayer():GetEyeTrace().Entity
	if !ent or ent:IsPlayer() then return end
	
	if lastid != ent:EntIndex() then

		net.Start( "pprotect_get_owner" )
			net.WriteEntity( ent )
		net.SendToServer()

		lastid = ent:EntIndex()
		
	end

	-- Check Owner ( Owner is set at the bottom of the file! )
	if Owner == nil or IsWorld == nil or !ent:IsValid() then return end
	
	local ownerText
	if IsWorld then

		ownerText = "Owner: World"

	else

		if Owner:IsPlayer() and Owner:IsValid() then
			ownerText = "Owner: " .. Owner:Nick()
		elseif IsDisconnected != nil then
			ownerText = "Owner: " .. IsDisconnected .. " (disconnected)"
		end

	end

	if ownerText == nil then return end

	-- Get textsize
	surface.SetFont( "pprotect_roboto_small" )
	local OW, OH = surface.GetTextSize( ownerText )
	OW = OW + 10
	OH = OH + 10

	-- Set color
	local col
	if Owner == LocalPlayer() or IsBuddy or LocalPlayer():IsAdmin() or LocalPlayer():IsSuperAdmin() or IsWorld and cl_PProtect.Settings.Propprotection[ "worldprops" ] == 1 then
		col = Color( 128, 255, 0, 200 )
	elseif cl_PProtect.Settings.Propprotection[ "worldbutton" ] == 1 and IsWorld then
		col = Color( 0, 161, 222, 200 )
	else
		col = Color( 176, 0, 0, 200 )
	end
	
	-- Check Draw-Mode ( FPP-Mode or not )
	if cl_PProtect.Settings.Propprotection[ "fppmode" ] == 0 then

		--Border
		draw.RoundedBox( 0, ScrW() - OW - 15, ScrH() / 2 - (OH / 2), 5, OH, col )
		--Textbox
		draw.RoundedBox( 0, ScrW() - OW - 10, ScrH() / 2 - (OH / 2), OW, OH, Color( 240, 240, 240, 200 ) )
		--Text
		draw.SimpleText( ownerText, "pprotect_roboto_small", ScrW() - 15, ScrH() / 2 , Color( 75, 75, 75, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	
	else

		ownerText = string.Replace( ownerText, "Owner: ", "" )
		local w, h = surface.GetTextSize( ownerText )

		--Textbox
		draw.RoundedBox( 2, ScrW() / 2 - ( w / 2 ) - 3, ScrH() / 2 + 19 - 2, w + 6, h + 4, Color( 0, 0, 0, 100 ) )
		--Text
		draw.SimpleText( ownerText, "pprotect_roboto_small", ScrW() / 2, ScrH() / 2 + 20, col, TEXT_ALIGN_CENTER, 0 )

	end

end
hook.Add( "HUDPaint", "ShowingOwner", cl_PProtect.showOwner )



------------------------
--  PHYSGUN BEAM FIX  --
------------------------

function cl_PProtect.SetClientBeam( ply, ent )
	return false
end
hook.Add( "PhysgunPickup", "SetClientPhysBeam", cl_PProtect.SetClientBeam )



------------------------
--  ADD BLOCKED PROP  --
------------------------

-- ADD TO BLOCKED PROPS
properties.Add( "addblockedprop", {

	MenuLabel = "Add to blocked Props",
	Order = 2002,
	MenuIcon = "icon16/page_white_edit.png",

	Filter = function( self, ent, ply )

		if cl_PProtect.Settings.Antispam[ "enabled" ] == 0 or cl_PProtect.Settings.Antispam[ "propblock" ] == 0 then return false end
		if !LocalPlayer():IsAdmin() or !LocalPlayer():IsSuperAdmin() then return false end
		if !ent:IsValid() or ent:IsPlayer() then return false end
		return true

	end,

	Action = function( self, ent )

		net.Start( "pprotect_send_blocked_props_cpanel" )
			net.WriteString( ent:GetModel() )
		net.SendToServer()
		
	end

} )



---------------------
--  SHARED ENTITY  --
---------------------

cl_PProtect.shared = nil
cl_PProtect.sharedEnt = {
	phys = false,
	tool = false,
	use = false
}

properties.Add( "shareentity", {

	MenuLabel = "Share entity",
	Order = 2003,
	MenuIcon = "icon16/group.png",

	Filter = function( self, ent, ply )

		if !ent:IsValid() or cl_PProtect.Settings.Propprotection[ "enabled" ] == 0 or ent:IsPlayer() then return false end
		if LocalPlayer():IsSuperAdmin() or Owner == LocalPlayer() then return true else return false end

	end,

	Action = function( self, ent )

		net.Start( "pprotect_get_sharedEntity" )
			net.WriteEntity( ent )
		net.SendToServer()

		cl_PProtect.shared = ent
		
	end

} )

-- SHARE ENTITY PANEL
net.Receive( "pprotect_send_sharedEntity", function( len )

	-- Receive Table
	local entity = cl_PProtect.shared
	local info = net.ReadTable()
	local model = entity:GetModel()

	if table.Count( info ) != 0 then
		cl_PProtect.sharedEnt = info
	else
		cl_PProtect.sharedEnt = {
			phys = false,
			use = false,
			tool = false
		}
	end

	-- Frame
	local frame = cl_PProtect.addfrm( 175, 175, "Share Prop: " .. model, false, true, false, "Save", cl_PProtect.sharedEnt, "pprotect_save_sharedEntity" )

	-- Checkboxes
	cl_PProtect.addchk( frame, "Physgun", "share", "phys" )
	cl_PProtect.addchk( frame, "Toolgun", "share", "tool" )
	cl_PProtect.addchk( frame, "Use", "share", "use" )
	cl_PProtect.addchk( frame, "Damage", "share", "dmg" )
	
end )



----------------
--  MESSAGES  --
----------------

-- DRAW NOTE
local function DrawNote()

	-- Check Note
	if cl_PProtect.Note.msg == "" or cl_PProtect.Note.time + 5 < SysTime() then return end

	-- Animation
	if cl_PProtect.Note.time + 0.5 > SysTime() then
		cl_PProtect.Note.alpha = math.Clamp( cl_PProtect.Note.alpha + 10, 0, 255 )
	elseif SysTime() > cl_PProtect.Note.time + 4.5 then
		cl_PProtect.Note.alpha = math.Clamp( cl_PProtect.Note.alpha - 10, 0, 255 )
	end

	surface.SetFont( "pprotect_note" )
	local tw, th = surface.GetTextSize( cl_PProtect.Note.msg )
	local w = tw + 20
	local h = th + 20
	local x = ScrW() - w - 20
	local y = ScrH() - h - 20
	local alpha = cl_PProtect.Note.alpha
	local backcol = Color( 88, 144, 222, alpha )

	--Textbox
	if cl_PProtect.Note.typ == "info" then
		backcol = Color( 128, 255, 0, alpha )
	elseif cl_PProtect.Note.typ == "admin" then
		backcol = Color( 176, 0, 0, alpha )
	end
	draw.RoundedBox( 0, x - h, y, h, h, backcol )
	draw.RoundedBox( 0, x, y, w, h, Color( 240, 240, 240, alpha ) )
	draw.SimpleText( "i", "pprotect_note_big", x - 23, y + 2, Color( 255, 255, 255, alpha ), 0, 0 )

	local triangle = { { x = x, y = y + ( h / 2 ) - 6 }, { x = x + 5, y = y + ( h / 2 ) }, { x = x, y = y + ( h / 2 ) + 6 } }
	surface.SetDrawColor( backcol )
	draw.NoTexture()
	surface.DrawPoly( triangle )

	--Text
	draw.SimpleText( cl_PProtect.Note.msg, "pprotect_note", x + 10, y + 10, Color( 75, 75, 75, alpha ), 0, 0 )

end
hook.Add( "HUDPaint", "pprotect_drawnote", DrawNote )

function cl_PProtect.ClientNote( msg, typ )

	local al = 0
	if cl_PProtect.Note.alpha > 0 then al = 255 end
	cl_PProtect.Note = { msg = msg, typ = typ, time = SysTime(), alpha = al }
	

	if cl_PProtect.Note.typ == "info" then
		LocalPlayer():EmitSound( "buttons/button9.wav", 100, 100 )
	elseif cl_PProtect.Note.typ == "admin" and cl_PProtect.Settings.Antispam[ "adminalertsound" ] == 1 then
		LocalPlayer():EmitSound( "ambient/alarms/klaxon1.wav", 100, 100 )
	end

end



------------------
--  NETWORKING  --
------------------

-- NOTIFY
net.Receive( "pprotect_notify", function( len )

	local note = net.ReadTable()
	if note[2] == "admin" and !LocalPlayer():IsAdmin() then return end

	cl_PProtect.ClientNote( note[1], note[2] )

end )

-- OWNER
net.Receive( "pprotect_send_owner", function( len )

	Owner = net.ReadEntity()
	local info = net.ReadString()
	if info == "buddy" then IsBuddy = true else IsBuddy = false end
	if info == "world" then IsWorld = true else IsWorld = false end
	if info != "" and info != "buddy" and info != "world" then IsDisconnected = info else IsDisconnected = nil end
	
end )
