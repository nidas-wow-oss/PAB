local PAB = PAB
if not PAB then return end

local pairs, ipairs = pairs, ipairs
local format = string.format
local lower  = string.lower
local floor  = math.floor
local max    = math.max
local min    = math.min

local HDR   = "|cff4fc3f7"
local WHITE = "|cffffffff"
local GREEN = "|cff00ff00"
local GOLD  = "|cffFFD700"
local GRAY  = "|cffaaaaaa"
local RED   = "|cffff4444"
local R     = "|r"

local panelBg     = { 0.00, 0.03, 0.11, 0.96 }
local panelBorder = { 0.22, 0.48, 0.90, 1.00 }
local titleBg     = { 0.02, 0.07, 0.20, 0.97 }
local titleBorder = { 0.28, 0.52, 0.92, 0.95 }

local ROW_A = { 0.02, 0.05, 0.14, 0.45 }
local ROW_B = { 0.01, 0.04, 0.10, 0.45 }

local PANEL_W, PANEL_H = 610, 530
local ROW_H = 28

local bdPanel = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local bdTitle = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function ApplyPanel(f)
    f:SetBackdrop(bdPanel)
    f:SetBackdropColor(panelBg[1], panelBg[2], panelBg[3], panelBg[4])
    f:SetBackdropBorderColor(panelBorder[1], panelBorder[2], panelBorder[3], panelBorder[4])
end
local function ApplyTitle(f)
    f:SetBackdrop(bdTitle)
    f:SetBackdropColor(titleBg[1], titleBg[2], titleBg[3], titleBg[4])
    f:SetBackdropBorderColor(titleBorder[1], titleBorder[2], titleBorder[3], titleBorder[4])
end

local function Header(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    fs:SetText(HDR .. text .. R)
    return fs
end

local function Separator(parent, y, inset)
    inset = inset or 12
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, y)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.20, 0.42, 0.72, 0.55)
    return line
end

local function AddTooltip(frame, title, body)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1.0, 0.84, 0.0)
        if body then GameTooltip:AddLine(body, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local chkCount = 0
local function Checkbox(parent, x, y, label, fn)
    chkCount = chkCount + 1
    local name = "PABChk" .. chkCount
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local fs = _G[name .. "Text"]
    if fs then
        fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        fs:SetText(WHITE .. label .. R)
    end
    cb:SetScript("OnClick", function(self) fn(self) end)
    return cb
end

local slCount = 0
local function SetSliderLabel(sl, label, val)

    if sl.valText then sl.valText:SetText(WHITE .. tostring(val) .. R) end
end

local function Slider(parent, x, y, label, initVal, minV, maxV, step, w, fn)
    slCount = slCount + 1
    local name = "PABSlider" .. slCount
    local sl = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    sl:SetWidth(w); sl:SetHeight(14)

    local title = _G[name .. "Text"]
    title:ClearAllPoints(); title:SetPoint("BOTTOM", sl, "TOP", 0, 1)
    title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    title:SetText(HDR .. label .. R)

    local low = _G[name .. "Low"]; low:ClearAllPoints()
    low:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 2, -1)
    low:SetFont(low:GetFont(), 10)
    low:SetText(GRAY .. tostring(minV) .. R)

    local high = _G[name .. "High"]; high:ClearAllPoints()
    high:SetPoint("TOPRIGHT", sl, "BOTTOMRIGHT", -2, -1)
    high:SetFont(high:GetFont(), 10)
    high:SetText(GRAY .. tostring(maxV) .. R)

    local val = sl:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    val:SetPoint("TOP", sl, "BOTTOM", 0, -1)
    val:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    sl.valText = val

    SetSliderLabel(sl, label, initVal)
    sl:SetScript("OnValueChanged", function(self, v) fn(self, v) end)
    return sl
end

local bdBtnSmall = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function Btn(parent, text, x, y, w, h, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w or 100, h or 24); btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local small = (w or 100) <= 60
    local function ApplyBtnStyle(s)
        if small then
            s:SetBackdrop(bdBtnSmall)
            s:SetBackdropColor(titleBg[1], titleBg[2], titleBg[3], titleBg[4])
            s:SetBackdropBorderColor(titleBorder[1], titleBorder[2], titleBorder[3], titleBorder[4])
        else
            ApplyTitle(s)
        end
    end
    ApplyBtnStyle(btn)
    local t = btn:CreateFontString(nil, "ARTWORK", small and "GameFontNormalSmall" or "GameFontNormal")
    t:SetFont("Fonts\\FRIZQT__.TTF", small and 10 or 12, "")
    t:SetPoint("CENTER"); t:SetText(GOLD .. text .. R)
    btn:SetScript("OnEnter", function(s) s:SetBackdropColor(0.10, 0.15, 0.30, 0.90); t:SetText(WHITE .. text .. R) end)
    btn:SetScript("OnLeave", function(s) ApplyBtnStyle(s); t:SetText(GOLD .. text .. R) end)
    btn:SetScript("OnClick", onClick); return btn
end

local activePopup = nil

local function CloseActivePopup()
    if activePopup and activePopup:IsShown() then activePopup:Hide() end
    activePopup = nil
end

local function ClassColorCode(key)
    local t = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[key])
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[key])
    if not (t and t.r) then return WHITE end
    return string.format("|cff%02x%02x%02x",
        math.floor(t.r * 255 + 0.5),
        math.floor(t.g * 255 + 0.5),
        math.floor(t.b * 255 + 0.5))
end

local function DropDown(parent, label, x, y, w, items, getter, setter)
    w = w or 160
    local dd = CreateFrame("Frame", nil, parent); dd:SetSize(w, 24)
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); ApplyTitle(dd)
    local lbl = dd:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    lbl:SetPoint("BOTTOM", dd, "TOP", 0, 3); lbl:SetText(HDR .. label .. R)
    local sel = dd:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    sel:SetPoint("LEFT", 10, 0); sel:SetPoint("RIGHT", -20, 0); sel:SetJustifyH("LEFT")

    local arrowBtn = CreateFrame("Button", nil, dd)
    arrowBtn:SetSize(20, 24); arrowBtn:SetPoint("RIGHT", 0, 0)
    local arrowTex = arrowBtn:CreateTexture(nil, "ARTWORK")
    arrowTex:SetSize(16, 16); arrowTex:SetPoint("CENTER")
    arrowTex:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrowBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetWidth(w)
    ApplyPanel(popup); popup:Hide()

    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetAllPoints(UIParent); overlay:SetFrameStrata("FULLSCREEN")
    overlay:EnableMouse(true); overlay:Hide()
    overlay:SetScript("OnMouseDown", function()
        popup:Hide(); overlay:Hide(); activePopup = nil
    end)
    popup.overlay = overlay

    popup:SetScript("OnHide", function() overlay:Hide(); activePopup = nil end)

    local function Refresh()
        local cur = getter and getter() or ""
        for i = 1, #items, 2 do if items[i] == cur then sel:SetText(ClassColorCode(items[i]) .. (items[i+1] or items[i]) .. R); return end end
        sel:SetText(ClassColorCode(cur) .. cur .. R)
    end
    local function ShowPopup()
        CloseActivePopup()

        if not popup.built then
        popup.built = true
        popup:SetHeight(#items / 2 * 20 + 6); local yy = -3
        for i = 1, #items, 2 do
            local key, disp = items[i], items[i+1] or items[i]
            local row = CreateFrame("Button", nil, popup)
            row:SetSize(w - 6, 20); row:SetPoint("TOPLEFT", 3, yy); yy = yy - 20
            local rt = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            rt:SetPoint("LEFT", 8, 0); rt:SetText(ClassColorCode(key) .. disp .. R)
            row:SetHighlightTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            row:GetHighlightTexture():SetVertexColor(0.31, 0.76, 0.97, 0.12)
            row:SetScript("OnClick", function()
                if setter then setter(key) end; Refresh()
                popup:Hide(); overlay:Hide(); activePopup = nil
            end)
        end
        end
        popup:ClearAllPoints(); popup:SetPoint("TOP", dd, "BOTTOM", 0, -2)
        popup:Show(); overlay:Show(); activePopup = popup
    end
    local function Toggle()
        if popup:IsShown() then popup:Hide(); overlay:Hide(); activePopup = nil
        else ShowPopup() end
    end
    dd:EnableMouse(true)
    dd:SetScript("OnMouseDown", Toggle)
    arrowBtn:SetScript("OnClick", Toggle)
    Refresh(); dd.Refresh = Refresh; return dd
end

local optionsFrame

local function ToggleOptions()
    if not optionsFrame then PAB:CreateOptionsUI() end

    if PAB.optionsDocked and PAB.ioPanel then
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            HideUIPanel(InterfaceOptionsFrame)
        elseif InterfaceOptionsFrame_OpenToCategory then

            InterfaceOptionsFrame_OpenToCategory(PAB.ioPanel)
            InterfaceOptionsFrame_OpenToCategory(PAB.ioPanel)
        end
        return
    end

    if optionsFrame:IsShown() then optionsFrame:Hide()
    else optionsFrame:Show(); PAB:RefreshAbilityList() end
end
PAB.ToggleOptions = ToggleOptions

function PAB:CreateOptionsUI()
    if optionsFrame then return end
    local db = self.db

    local f = CreateFrame("Frame", "PABOptionsFrame", UIParent)
    f:SetSize(PANEL_W, PANEL_H); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
    ApplyPanel(f); f:Hide()
    optionsFrame = f

    if PAB.InstallDockGuard then PAB:InstallDockGuard() end

    f:SetScript("OnMouseDown", function(s, btn)
        if btn ~= "LeftButton" then return end
        CloseActivePopup()

        if PAB.optionsDocked then return end
        s:StartMoving()
    end)
    f:SetScript("OnMouseUp",   function(s) s:StopMovingOrSizing() end)
    f:SetScript("OnHide", function() CloseActivePopup() end)

    local tBar = CreateFrame("Frame", nil, f)
    tBar:SetHeight(26)
    tBar:SetPoint("LEFT", f, "TOP", -140, 0)
    tBar:SetPoint("RIGHT", f, "TOP", 140, 0)
    tBar:SetFrameLevel(f:GetFrameLevel() + 2)
    ApplyTitle(tBar)

    f.pabTitleBar = tBar

    local title = tBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 1)
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    title:SetText(GOLD .. "Party Ability Bars" .. R)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetFrameLevel(f:GetFrameLevel() + 5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    f.pabCloseBtn = closeBtn

    local cr = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    cr:SetPoint("BOTTOMRIGHT", -12, 8)
    cr:SetText(GRAY .. "v2.0  |  by Nidhaus" .. R)

    local gsH = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gsH:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
    gsH:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    gsH:SetText(HDR .. "General Settings" .. R)

    local gsD = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    gsD:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    gsD:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -31)
    gsD:SetText(WHITE .. "Basic options and frame positioning." .. R)

    local scaleS = Slider(f, 16, -58, "Scale", format("%.2f", db.scale), 0.5, 2.0, 0.01, 170,
        function(self, v)
            db.scale = v; SetSliderLabel(self, "Scale", format("%.2f", v))
            PAB:ApplyAnchorSettings()
        end)
    scaleS:SetValue(db.scale)

    local iplS = Slider(f, 16, -108, "Icons per line", tostring(db.iconsperline), 0, 10, 1, 170,
        function(self, v)
            v = floor(v + 0.5); db.iconsperline = v
            SetSliderLabel(self, "Icons per line", tostring(v))
            PAB:UpdateAnchors(true)
        end)
    iplS:SetValue(db.iconsperline)

    local spacS = Slider(f, 16, -158, "Icon Spacing", tostring(db.iconSpacing or 1), 0, 10, 1, 170,
        function(self, v)
            v = floor(v + 0.5); db.iconSpacing = v
            SetSliderLabel(self, "Icon Spacing", tostring(v))
            PAB:UpdateAnchors(true)
        end)
    spacS:SetValue(db.iconSpacing or 1)

    local rx = 200

    local c1 = Checkbox(f, rx, -40, "Arena Only", function(s)
        db.arena = s:GetChecked() and true or false; PAB:ApplyAnchorSettings() end)
    c1:SetChecked(db.arena)

    local c2 = Checkbox(f, rx, -64, "Hidden Until Cooldown", function(s)
        db.hidden = s:GetChecked() and true or false; PAB:ApplyAnchorSettings() end)
    c2:SetChecked(db.hidden)

    local c3 = Checkbox(f, rx, -88, "Movable Anchors", function(s)
        db.movable = s:GetChecked() and true or false; PAB:ApplyAnchorSettings(); PAB:LoadPositions() end)
    c3:SetChecked(db.movable)

    local c4 = Checkbox(f, rx, -112, "Lock Anchors", function(s)
        db.lock = s:GetChecked() and true or false; PAB:ApplyAnchorSettings() end)
    c4:SetChecked(db.lock)

    local c5 = Checkbox(f, rx, -136, "Auto-Detect CD Reductions", function(s)
        db.autoCooldowns = s:GetChecked() and true or false end)
    c5:SetChecked(db.autoCooldowns)
    AddTooltip(c5, "Auto-Detect CD Reductions",
        "Inspects party members to detect talents and glyphs that shorten their cooldowns.")

    local c6 = Checkbox(f, rx, -160, "Icon Border", function(s)
        db.iconBorder = s:GetChecked() and true or false; PAB:UpdateAnchors(true) end)
    c6:SetChecked(db.iconBorder)

    local growItems = { "RIGHT","Right", "LEFT","Left" }
    DropDown(f, "Grow Direction", rx, -202, 140, growItems,
        function() return db.growDirection or "RIGHT" end,
        function(v) db.growDirection = v; PAB:UpdateAnchors(true) end)

    local aeY = -248
    Separator(f, aeY + 12)
    Header(f, 16, aeY, "Ability Editor")

    local aeD = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    aeD:SetPoint("TOPLEFT", f, "TOPLEFT", 150, aeY)
    aeD:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    aeD:SetWidth(180); aeD:SetJustifyH("RIGHT")
    self.abilityCounterFS = aeD

    local classItems = {
        "WARRIOR","Warrior", "DEATHKNIGHT","Death Knight", "PALADIN","Paladin",
        "PRIEST","Priest", "SHAMAN","Shaman", "DRUID","Druid",
        "ROGUE","Rogue", "MAGE","Mage", "WARLOCK","Warlock", "HUNTER","Hunter",
        "Dwarf","Dwarf", "BloodElf","Blood Elf", "Scourge","Undead",
        "Tauren","Tauren", "NightElf","Night Elf", "Draenei","Draenei",
        "Human","Human", "Gnome","Gnome", "Orc","Orc", "Troll","Troll",
        "Items","Items",
    }
    db.classSelected = db.classSelected or "WARRIOR"

    local rxb = 338

    Btn(f, "All", rxb, aeY - 14, 50, 24, function()
        local cls = db.classSelected
        if not db.enabledCooldowns[cls] then db.enabledCooldowns[cls] = {} end
        for ab in pairs(db.abilities[cls] or {}) do db.enabledCooldowns[cls][ab] = true end
        PAB:RefreshAbilityList(); PAB:UpdateAnchors(true)
    end)
    Btn(f, "None", rxb + 55, aeY - 14, 50, 24, function()
        local cls = db.classSelected
        if not db.enabledCooldowns[cls] then db.enabledCooldowns[cls] = {} end
        for ab in pairs(db.abilities[cls] or {}) do db.enabledCooldowns[cls][ab] = false end
        PAB:RefreshAbilityList(); PAB:UpdateAnchors(true)
    end)

    DropDown(f, "Class", rxb, aeY - 60, 160, classItems,
        function() return db.classSelected end,
        function(v) db.classSelected = v; PAB:RefreshAbilityList() end)

    Btn(f, "Reset Positions", rxb, aeY - 98, 140, 24, function()
        db.positions = {}
        PAB:LoadPositions()
        PAB:UpdateAnchors(true)
        ChatFrame1:AddMessage(HDR .. "[PAB]" .. R .. " Positions reset.")
    end)

    local cdH = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    cdH:SetPoint("TOPLEFT", f, "TOPLEFT", rxb, aeY - 130); cdH:SetWidth(250); cdH:SetJustifyH("LEFT")
    cdH:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    cdH:SetText(GRAY .. "CD field = editable for talent/glyph spells.\nType a custom cooldown and press Enter." .. R)

    local listTop = aeY - 16
    local listBg = CreateFrame("Frame", nil, f)
    listBg:SetPoint("TOPLEFT", f, "TOPLEFT", 10, listTop)
    listBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 24)
    listBg:SetWidth(320)
    ApplyPanel(listBg)
    listBg:SetBackdropColor(panelBg[1] * 0.7, panelBg[2] * 0.7, panelBg[3] * 0.7, 0.70)

    local maxVis = 14

    local scrollFrame = CreateFrame("ScrollFrame", "PABScrollFrame", listBg, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4); scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)
    self.scrollFrame = scrollFrame

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, function()
            PAB:RefreshAbilityList()
        end)
    end)

    self.listBg = listBg

    local listInner = CreateFrame("Frame", nil, listBg)
    listInner:SetPoint("TOPLEFT", 4, -4); listInner:SetPoint("TOPRIGHT", -24, -4)
    listInner:SetHeight(maxVis * ROW_H)
    self.listInner = listInner

    self.abilityRows = {}

    for i = 1, maxVis do
        local row = CreateFrame("Frame", nil, listInner)
        row:SetHeight(ROW_H); row:SetPoint("TOPLEFT", 0, -(i-1)*ROW_H); row:SetPoint("RIGHT", 0, 0)
        local rbg = row:CreateTexture(nil, "BACKGROUND"); rbg:SetAllPoints()
        rbg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        rbg:SetVertexColor(unpack(i % 2 == 0 and ROW_B or ROW_A))
        row.bg = rbg

        local hl = row:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
        hl:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        hl:SetVertexColor(0.31, 0.76, 0.97, 0.16)
        row:EnableMouse(true)

        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            if scrollFrame then scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta) end
        end)

        local cbName = "PABRowChk" .. i
        local cb = CreateFrame("CheckButton", cbName, row, "UICheckButtonTemplate")
        cb:SetSize(22, 22); cb:SetPoint("LEFT", 0, 0)
        local cbText = _G[cbName .. "Text"]; if cbText then cbText:SetText("") end
        row.cb = cb

        local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(20, 20)
        icon:SetPoint("LEFT", cb, "RIGHT", 2, 0); icon:SetTexCoord(0.07, 0.9, 0.07, 0.90)
        row.icon = icon

        local nm = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nm:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        nm:SetPoint("LEFT", icon, "RIGHT", 5, 0); nm:SetWidth(140); nm:SetJustifyH("LEFT")
        row.name = nm

        local cdTxt = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        cdTxt:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        cdTxt:SetPoint("LEFT", nm, "RIGHT", 2, 0); cdTxt:SetWidth(36); cdTxt:SetJustifyH("RIGHT")
        row.cdTxt = cdTxt

        local eb = CreateFrame("EditBox", nil, row)
        eb:SetSize(38, 18); eb:SetPoint("LEFT", cdTxt, "RIGHT", 4, 0)
        eb:SetFontObject(GameFontNormal); eb:SetAutoFocus(false)
        eb:SetNumeric(true); eb:SetMaxLetters(4); eb:SetTextInsets(3, 3, 0, 0)
        local eBg = eb:CreateTexture(nil, "BACKGROUND"); eBg:SetAllPoints()
        eBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        eBg:SetVertexColor(titleBg[1], titleBg[2], titleBg[3], 1)
        local eBrd = CreateFrame("Frame", nil, eb)
        eBrd:SetPoint("TOPLEFT", -1, 1); eBrd:SetPoint("BOTTOMRIGHT", 1, -1)
        eBrd:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Background", tile=false, edgeSize=1,
            insets={left=0,right=0,top=0,bottom=0} })
        eBrd:SetBackdropColor(0, 0, 0, 0)
        eBrd:SetBackdropBorderColor(titleBorder[1], titleBorder[2], titleBorder[3], 0.5)
        row.editbox = eb
        row.zebra = (i % 2 == 0) and ROW_B or ROW_A

        eb:SetScript("OnEnterPressed", function(s)
            s:ClearFocus(); local val = tonumber(s:GetText())
            local cls, abName = row.cls, row.abName
            if not cls then return end
            if not db.customCooldowns[cls] then db.customCooldowns[cls] = {} end
            if not db.manualOverrides[cls] then db.manualOverrides[cls] = {} end
            if val and val > 0 then
                db.customCooldowns[cls][abName] = val
                db.manualOverrides[cls][abName] = true
            else
                db.customCooldowns[cls][abName] = nil
                db.manualOverrides[cls][abName] = nil; s:SetText("")
            end
            PAB:UpdateAnchors(false); PAB:RefreshAbilityList()
        end)
        eb:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)

        cb:SetScript("OnClick", function(s)
            local cls, abName = row.cls, row.abName
            if not cls then return end
            local on = s:GetChecked() and true or false
            db.enabledCooldowns[cls][abName] = on
            PAB:TintRow(row, on)
            PAB:UpdateAbilityCounter()
            PAB:UpdateAnchors(false)
        end)

        row:Hide(); self.abilityRows[i] = row
    end

    tinsert(UISpecialFrames, "PABOptionsFrame")
    self:RefreshAbilityList()
end

local variantByName = {}
local sortedCache = {}
do
    local defs = PAB.defaultAbilities
    for spID, vdata in pairs(PAB.cooldownVariants) do
        local spName = GetSpellInfo(spID)
        if spName then
            for cls, abs in pairs(defs) do
                if abs[spName] then variantByName[cls .. ":" .. spName] = vdata; break end
            end
        end
    end
end

local relayout = CreateFrame("Frame")
relayout:Hide()
relayout:SetScript("OnUpdate", function(self)
    self:Hide()
    PAB:LayoutDockedOptions()
end)

function PAB:LayoutDockedOptions()
    if not self.optionsDocked or not optionsFrame then return end
    local f = optionsFrame

    local box = f:GetParent()
    if not box then return end

    local pw, ph = box:GetWidth(), box:GetHeight()
    if not pw or not ph or pw <= 0 or ph <= 0 then return end

    f:SetScale(1)
    f:ClearAllPoints()
    f:SetAllPoints(box)

    self:RefreshAbilityList()
end

function PAB:DockOptions(host)
    if not optionsFrame then self:CreateOptionsUI() end
    if self.optionsDocked then return end
    local f = optionsFrame
    self.optionsDocked = true

    f:SetBackdrop(nil)
    if f.pabTitleBar then f.pabTitleBar:Hide() end
    if f.pabCloseBtn then f.pabCloseBtn:Hide() end
    f:SetMovable(false)

    f:SetParent(host)
    f:SetFrameStrata(host:GetFrameStrata())
    f:SetFrameLevel(host:GetFrameLevel() + 1)

    self:LayoutDockedOptions()
    relayout:Show()

    f:Show()
    self:RefreshAbilityList()
end

function PAB:RestoreWindowChrome()
    if not optionsFrame then return end
    local f = optionsFrame
    self.optionsDocked = false
    relayout:Hide()

    ApplyPanel(f)
    if f.pabTitleBar then f.pabTitleBar:Show() end
    if f.pabCloseBtn then f.pabCloseBtn:Show() end
    f:SetMovable(true)
    f:SetScale(1)

    f:SetParent(UIParent)
    f:ClearAllPoints()

    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
end

function PAB:UndockOptions()
    if not optionsFrame or not self.optionsDocked then return end
    self:RestoreWindowChrome()
    optionsFrame:Hide()
end

function PAB:InstallDockGuard()
    local f = optionsFrame
    if not f or f.pabDockGuard then return end
    f.pabDockGuard = true

    local settle = CreateFrame("Frame")
    settle:Hide()
    settle:SetScript("OnUpdate", function(self)
        self:Hide()
        if not PAB.optionsDocked then return end
        local iof = _G.InterfaceOptionsFrame
        if iof and iof:IsShown() then return end

        PAB:UndockOptions()
    end)

    f:HookScript("OnShow", function(self)
        if not PAB.optionsDocked then return end
        local iof = _G.InterfaceOptionsFrame
        if iof and iof:IsShown() then return end
        settle:Show()
    end)
end

function PAB:UpdateAbilityCounter()
    local fs = self.abilityCounterFS; if not fs then return end
    local db = self.db; if not db then return end
    local cls = db.classSelected
    local abilities = db.abilities[cls]; if not abilities then return end

    local enabledTbl = db.enabledCooldowns[cls]
    local on, total = 0, 0
    for ab in pairs(abilities) do
        total = total + 1
        if enabledTbl and enabledTbl[ab] then on = on + 1 end
    end

    fs:SetText(GRAY .. "tracked: " .. R
        .. (on > 0 and "|cff00ff99" or GRAY) .. on .. R
        .. GRAY .. " / " .. total .. R)
end

function PAB:RefreshAbilityList()
    local rows = self.abilityRows; if not rows then return end
    local db = self.db; if not db then return end
    local cls = db.classSelected
    local abilities = db.abilities[cls]; if not abilities then return end

    local sorted = sortedCache[cls]
    if not sorted then
        sorted = {}
        for ab in pairs(abilities) do sorted[#sorted + 1] = ab end
        table.sort(sorted)
        sortedCache[cls] = sorted
    end

    self:UpdateAbilityCounter()

    local rowsFit = #rows
    local lb = self.listBg
    if lb then
        local h = lb:GetHeight()
        if h and h > 0 then
            rowsFit = math.floor((h - 8) / ROW_H)
            if rowsFit < 3      then rowsFit = 3      end
            if rowsFit > #rows  then rowsFit = #rows  end
        end
    end
    if self.listInner then self.listInner:SetHeight(rowsFit * ROW_H) end

    local total = #sorted; local maxVis = rowsFit
    if self.scrollFrame then FauxScrollFrame_Update(self.scrollFrame, total, maxVis, ROW_H) end
    local off = self.scrollFrame and FauxScrollFrame_GetOffset(self.scrollFrame) or 0

    if not db.enabledCooldowns[cls] then db.enabledCooldowns[cls] = {} end
    if not db.customCooldowns then db.customCooldowns = {} end
    if not db.manualOverrides then db.manualOverrides = {} end

    for i, row in ipairs(rows) do
        local di = i + off

        if i <= maxVis and di <= total then
            local abName = sorted[di]; local baseCd = abilities[abName]
            row.cls = cls; row.abName = abName
            row.icon:SetTexture(PAB:FindAbilityIcon(abName))
            row.name:SetText(WHITE .. (self.itemForSpell[abName] or abName) .. R)
            local variant = variantByName[cls .. ":" .. abName]
            row.cdTxt:SetText(GRAY .. format("%ds", baseCd) .. R)

            if variant then
                row.editbox:Show()
                local custom = db.customCooldowns[cls] and db.customCooldowns[cls][abName]
                row.editbox:SetText(custom and custom > 0 and tostring(custom) or "")
            else
                row.editbox:Hide(); row.editbox:SetText("")
            end

            local checked = db.enabledCooldowns[cls][abName]
            if checked == nil then checked = false; db.enabledCooldowns[cls][abName] = false end
            row.cb:SetChecked(checked)
            self:TintRow(row, checked)
            row:Show()
        else row.cls = nil; row.abName = nil; row:Hide() end
    end
end

function PAB:TintRow(row, on)
    if not row.bg then return end
    if on then
        row.bg:SetVertexColor(0.06, 0.16, 0.28, 0.55)
    else
        local z = row.zebra
        row.bg:SetVertexColor(z[1], z[2], z[3], z[4])
    end
end

SLASH_PAB1 = "/pab"
SlashCmdList["PAB"] = function(msg)
    msg = lower(msg or "")
    if msg == "reset" then PABDB = nil; ReloadUI()
    else ToggleOptions() end
end

local ioPanel = CreateFrame("Frame", "PABInterfacePanel", UIParent)
ioPanel.name = "Party Ability Bars"

PAB.ioPanel = ioPanel

local ioHost = CreateFrame("Frame", nil, ioPanel)
do
    local box = _G.InterfaceOptionsFramePanelContainer or ioPanel
    ioHost:SetPoint("TOPLEFT",     box, "TOPLEFT",      6, -6)
    ioHost:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -6,  6)
end

ioPanel:SetScript("OnShow", function() PAB:DockOptions(ioHost) end)
ioPanel:SetScript("OnHide", function() PAB:UndockOptions() end)

InterfaceOptions_AddCategory(ioPanel)

if _G.InterfaceOptionsFrame then
    _G.InterfaceOptionsFrame:HookScript("OnHide", function()
        if PAB.optionsDocked then PAB:UndockOptions() end
    end)
end
