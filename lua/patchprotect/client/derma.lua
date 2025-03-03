local pan = FindMetaTable('Panel')

-------------
--  FRAME  --
-------------

function cl_PProtect.addfrm(w, h, title, hor)
    -- Frame
    local t = SysTime()
    local frm = vgui.Create('DPanel')
    frm:SetPos(surface.ScreenWidth() / 2 - (w / 2), surface.ScreenHeight() / 2 - (h / 2))
    frm:SetSize(w, h)
    frm:MakePopup()

    function frm:Paint(w, h)
        Derma_DrawBackgroundBlur(self, t)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 128))
        draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(255, 150, 30))
        draw.RoundedBoxEx(4, 1, 50, w - 2, h - 51, Color(255, 255, 255), false, false, true, true)
    end

    -- Title
    frm.title = vgui.Create('DLabel', frm)
    frm.title:SetText(title)
    frm.title:SetPos(15, 12.5)
    frm.title:SetFont(cl_PProtect.setFont('roboto', 25, 750, true))
    frm.title:SetColor(Color(0, 0, 0, 192))
    frm.title:SizeToContents()

    -- Close-Button
    frm.close = vgui.Create('DButton', frm)
    frm.close:SetPos(w - 40, 10)
    frm.close:SetSize(30, 30)
    frm.close:SetText('')

    function frm.close:DoClick()
        frm:Remove()
    end

    function frm.close:Paint(w, h)
        local color = self.Depressed and Color(135, 50, 50) or self.Hovered and Color(200, 60, 60) or Color(200, 80, 80)
        draw.RoundedBox(4, 0, 0, w, h, color)
        draw.SimpleText('r', cl_PProtect.setFont('marlett', 14, 0, false, false, true), 9, 8, Color(255, 255, 255))
    end

    frm.list = vgui.Create('DPanelList', frm)
    frm.list:SetPos(10, 60)
    frm.list:SetSize(w - 20, h - 70)
    frm.list:SetSpacing(5)
    frm.list:EnableHorizontal(hor)
    frm.list:EnableVerticalScrollbar(true)
    frm.list.VBar.btnUp:SetVisible(false)
    frm.list.VBar.btnDown:SetVisible(false)

    function frm.list.VBar:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
    end

    function frm.list.VBar.btnGrip:Paint(w, h)
        draw.RoundedBox(0, 8, 0, 5, h, Color(0, 0, 0, 150))
    end

    return frm.list
end

-------------
--  LABEL  --
-------------

function pan:addlbl(text, header)
    local headerWeight = header and 750 or 0
    local lbl = vgui.Create('DLabel')
    lbl:SetText(text)
    lbl:SetDark(true)
    lbl:SetFont(cl_PProtect.setFont('roboto', 14, headerWeight, true))
    lbl:SizeToContents()
    self:AddItem(lbl)

    return lbl
end

----------------
--  CHECKBOX  --
----------------

function pan:addchk(text, tip, check, cb)
    local chk = vgui.Create('DCheckBoxLabel')
    chk:SetText(text)
    chk:SetDark(true)
    chk:SetChecked(check)
    if tip then chk:SetTooltip(tip) end
    chk.Label:SetFont(cl_PProtect.setFont('roboto', 14, 500, true))

    function chk:OnChange()
        cb(self:GetChecked())
    end

    function chk:PerformLayout()
        local x = self.m_iIndent or 0
        self:SetHeight(20)
        self.Button:SetSize(36, 20)
        self.Button:SetPos(x, 0)
        if self.Label then
            self.Label:SizeToContents()
            self.Label:SetPos(x + 45, self.Button:GetTall() / 2 - 7)
        end
    end

    local curx = chk:GetChecked() and 18 or 2

    local function smooth(goal)
        local speed = math.abs(goal - curx) / 3
        curx = curx > goal and curx - speed or curx < goal and curx + speed or curx
        return curx
    end

    function chk:PaintOver(w, h)
        draw.RoundedBox(0, 0, 0, 36, 20, Color(255, 255, 255))
        local bgColor = chk:GetChecked() and Color(255, 150, 0) or Color(100, 100, 100)
        draw.RoundedBox(8, 0, 0, 36, 20, bgColor)
        draw.RoundedBox(8, smooth(chk:GetChecked() and 18 or 2), 2, 16, 16, Color(255, 255, 255))
    end

    self:AddItem(chk)

    return chk
end

----------------
--   BUTTON   --
----------------

function pan:addbtn(text, nettext, args)
    local btn = vgui.Create('DButton')
    btn:Center()
    btn:SetTall(25)
    btn:SetText(text)
    btn:SetDark(true)
    btn:SetFont(cl_PProtect.setFont('roboto', 14, 500, true))
    btn:SetColor(Color(50, 50, 50))

    function btn:DoClick()
        if self:GetDisabled() then return end
        if type(args) == 'function' then
            args()
        else
            net.Start(nettext)
            net.WriteTable(type(args) == 'table' and args or {})
            net.SendToServer()
        end
        if nettext == 'pprotect_save' then
            cl_PProtect.UpdateMenus()
        end
    end

    function btn:Paint(w, h)
        local color = self:GetDisabled() and Color(240, 240, 240) or self.Depressed and Color(250, 150, 0) or self.Hovered and Color(220, 220, 220) or Color(200, 200, 200)
        draw.RoundedBox(0, 0, 0, w, h, color)
        self:SetCursor(self:GetDisabled() and 'arrow' or 'hand')
    end

    self:AddItem(btn)

    return btn
end

--------------
--  SLIDER  --
--------------

local sldnum = 0
function pan:addsld(min, max, text, value, t1, t2, decimals)
    local sld = vgui.Create('DNumSlider')
    sld:SetMin(min)
    sld:SetMax(max)
    sld:SetDecimals(decimals)
    sld:SetText(text)
    sld:SetDark(true)
    sld:SetValue(value)
    sld.TextArea:SetFont(cl_PProtect.setFont('roboto', 14, 500, true))
    sld.Label:SetFont(cl_PProtect.setFont('roboto', 14, 500, true))
    sld.Scratch:SetVisible(false)

    sld.OnValueChanged = function(self, number)
        local newVal = math.Round(number, decimals)
        if sldnum ~= newVal then
            sldnum = newVal
            cl_PProtect.Settings[t1][t2] = sldnum
        end
    end

    function sld.Slider.Knob:Paint(w, h)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, Color(255, 150, 0))
    end

    function sld.Slider:Paint(w, h)
        draw.RoundedBox(2, 8, h / 2 - 1, w - 16, 2, Color(200, 200, 200))
    end

    self:AddItem(sld)
end

----------------
--  COMBOBOX  --
----------------

function pan:addcmb(items, setting, value)
    local cmb = vgui.Create('DComboBox')
    for _, choice in ipairs(items) do
        cmb:AddChoice(choice)
    end
    cmb:SetValue(value)

    function cmb:OnSelect(index, value, data)
        cl_PProtect.Settings.Antispam[setting] = index
    end

    self:AddItem(cmb)
end

----------------
--  LISTVIEW  --
----------------

local pressed = {}
function pan:addplp(ply, bud, cb, cb2)
    local plp = vgui.Create('DPanel')
    plp:SetHeight(40)
    plp:SetCursor('hand')

    plp.av = vgui.Create('AvatarImage', plp)
    plp.av:SetSize(32, 32)
    plp.av:SetPlayer(ply, 32)
    plp.av:SetPos(4, 4)

