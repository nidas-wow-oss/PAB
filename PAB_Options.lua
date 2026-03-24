-------------------------------------------------------------------------------
--  PAB  –  Options Panel  (Arcane Style)
--  Author: Nidhaus
--  Colors from NidhausUI.lua Arcane palette
-------------------------------------------------------------------------------
local PAB = PAB
if not PAB then return end

local pairs, ipairs = pairs, ipairs
local format = string.format
local lower  = string.lower
local floor  = math.floor
local max    = math.max
local min    = math.min

-------------------------------------------------------------------------------
--  NidhausUI Arcane palette (exact values from NidhausUI.lua)
-------------------------------------------------------------------------------
local HDR   = "|cff4fc3f7"   -- cyan header
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

local PANEL_W, PANEL_H = 620, 560
local ROW_H = 28

-------------------------------------------------------------------------------
--  Backdrops (from NidhausUI.lua)
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
--  Header (cyan, like NidhausUI.Header)
-------------------------------------------------------------------------------
local function Header(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    fs:SetText(HDR .. text .. R)
    return fs
end

-------------------------------------------------------------------------------
--  Checkbox (InterfaceOptionsCheckButtonTemplate, like NidhausUI.Checkbox)
-------------------------------------------------------------------------------
local chkCount = 0
local function Checkbox(parent, x, y, label, fn)
    chkCount = chkCount + 1
    local name = "PABChk" .. chkCount
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local fs = _G[name .. "Text"]
    if fs then
        fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        fs:SetText(WHITE .. label .. R)
    end
    cb:SetScript("OnClick", function(self) fn(self) end)
    return cb
end

-------------------------------------------------------------------------------
--  Slider (OptionsSliderTemplate, green label + gold value like NidhausUI)
-------------------------------------------------------------------------------
local slCount = 0
local function SetSliderLabel(sl, label, val)
    local name = sl:GetName()
    if name and _G[name .. "Text"] then
        _G[name .. "Text"]:SetText(HDR .. label .. ": " .. val .. R)
    end
end

local function Slider(parent, x, y, label, initVal, minV, maxV, step, w, fn)
    slCount = slCount + 1
    local name = "PABSlider" .. slCount
    local sl = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    sl:SetWidth(w)
    _G[name .. "Low"]:SetText(GRAY .. tostring(minV) .. R)
    _G[name .. "High"]:SetText(GRAY .. tostring(maxV) .. R)
    SetSliderLabel(sl, label, initVal)
    sl:SetScript("OnValueChanged", function(self, v) fn(self, v) end)
    return sl
end

-------------------------------------------------------------------------------
--  Button
-------------------------------------------------------------------------------
local function Btn(parent, text, x, y, w, h, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w or 100, h or 24); btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    ApplyTitle(btn)
    local t = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    t:SetPoint("CENTER"); t:SetText(GOLD .. text .. R)
    btn:SetScript("OnEnter", function(s) s:SetBackdropColor(0.10, 0.15, 0.30, 0.90); t:SetText(WHITE .. text .. R) end)
    btn:SetScript("OnLeave", function(s) ApplyTitle(s); t:SetText(GOLD .. text .. R) end)
    btn:SetScript("OnClick", onClick); return btn
end

-------------------------------------------------------------------------------
--  DropDown (closes on outside click, Blizzard arrow texture)
-------------------------------------------------------------------------------
local activePopup = nil  -- track which popup is open

local function CloseActivePopup()
    if activePopup and activePopup:IsShown() then activePopup:Hide() end
    activePopup = nil
end

local function DropDown(parent, label, x, y, w, items, getter, setter)
    w = w or 160
    local dd = CreateFrame("Frame", nil, parent); dd:SetSize(w, 24)
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); ApplyTitle(dd)
    local lbl = dd:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetPoint("BOTTOM", dd, "TOP", 0, 3); lbl:SetText(HDR .. label .. R)
    local sel = dd:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sel:SetPoint("LEFT", 10, 0); sel:SetPoint("RIGHT", -20, 0); sel:SetJustifyH("LEFT")

    -- Blizzard dropdown arrow button
    local arrowBtn = CreateFrame("Button", nil, dd)
    arrowBtn:SetSize(20, 24); arrowBtn:SetPoint("RIGHT", 0, 0)
    local arrowTex = arrowBtn:CreateTexture(nil, "ARTWORK")
    arrowTex:SetSize(16, 16); arrowTex:SetPoint("CENTER")
    arrowTex:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrowBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetWidth(w)
    ApplyPanel(popup); popup:Hide()

    -- Close-on-outside-click overlay
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
        for i = 1, #items, 2 do if items[i] == cur then sel:SetText(WHITE .. (items[i+1] or items[i]) .. R); return end end
        sel:SetText(WHITE .. cur .. R)
    end
    local function ShowPopup()
        CloseActivePopup()
        -- Rebuild children
        for _, k in ipairs({popup:GetChildren()}) do k:Hide(); k:SetParent(nil) end
        popup:SetHeight(#items / 2 * 20 + 6); local yy = -3
        for i = 1, #items, 2 do
            local key, disp = items[i], items[i+1] or items[i]
            local row = CreateFrame("Button", nil, popup)
            row:SetSize(w - 6, 20); row:SetPoint("TOPLEFT", 3, yy); yy = yy - 20
            local rt = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            rt:SetPoint("LEFT", 8, 0); rt:SetText(WHITE .. disp .. R)
            row:SetHighlightTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            row:GetHighlightTexture():SetVertexColor(0.31, 0.76, 0.97, 0.12)
            row:SetScript("OnClick", function()
                if setter then setter(key) end; Refresh()
                popup:Hide(); overlay:Hide(); activePopup = nil
            end)
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

-------------------------------------------------------------------------------
--  MAIN FRAME
-------------------------------------------------------------------------------
local optionsFrame

local function ToggleOptions()
    if not optionsFrame then PAB:CreateOptionsUI() end
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

    f:SetScript("OnMouseDown", function(s, btn) if btn == "LeftButton" then CloseActivePopup(); s:StartMoving() end end)
    f:SetScript("OnMouseUp",   function(s) s:StopMovingOrSizing() end)
    f:SetScript("OnHide", function() CloseActivePopup() end)

    -- Title bar (overlapping top border, like NUF)
    local tBar = CreateFrame("Frame", nil, f)
    tBar:SetHeight(26)
    tBar:SetPoint("LEFT", f, "TOP", -140, 0)
    tBar:SetPoint("RIGHT", f, "TOP", 140, 0)
    tBar:SetFrameLevel(f:GetFrameLevel() + 2)
    ApplyTitle(tBar)

    local title = tBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 1)
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    title:SetText(GOLD .. "Party Ability Bars" .. R)

    -- Close X (top right corner of frame)
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(24, 24); closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -4)
    closeBtn:SetFrameLevel(f:GetFrameLevel() + 5)
    local ct = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ct:SetPoint("CENTER"); ct:SetText(RED .. "X" .. R)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function() ct:SetText("|cffff6666X|r") end)
    closeBtn:SetScript("OnLeave", function() ct:SetText(RED .. "X" .. R) end)

    -- Version next to X
    local ver = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ver:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0); ver:SetText(GOLD .. "v2.0" .. R)

    local cr = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cr:SetPoint("BOTTOMRIGHT", -12, 8); cr:SetText(GRAY .. "by Nidhaus" .. R)

    ---------------------------------------------------------------------------
    --  GENERAL SETTINGS
    ---------------------------------------------------------------------------
    -- "General Settings" in green to match NUF style
    local gsH = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gsH:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
    gsH:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    gsH:SetText(GREEN .. "General Settings" .. R)

    local gsD = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    gsD:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -30)
    gsD:SetText(WHITE .. "Basic options and frame positioning." .. R)

    -- Left column: sliders
    local scaleS = Slider(f, 16, -62, "Scale", format("%.2f", db.scale), 0.5, 2.0, 0.01, 170,
        function(self, v)
            db.scale = v; SetSliderLabel(self, "Scale", format("%.2f", v))
            PAB:ApplyAnchorSettings()
        end)
    scaleS:SetValue(db.scale)

    local iplS = Slider(f, 16, -116, "Icons per line", tostring(db.iconsperline), 0, 10, 1, 170,
        function(self, v)
            v = floor(v + 0.5); db.iconsperline = v
            SetSliderLabel(self, "Icons per line", tostring(v))
            PAB:UpdateAnchors(true)
        end)
    iplS:SetValue(db.iconsperline)

    local spacS = Slider(f, 16, -170, "Icon Spacing", tostring(db.iconSpacing or 1), 0, 10, 1, 170,
        function(self, v)
            v = floor(v + 0.5); db.iconSpacing = v
            SetSliderLabel(self, "Icon Spacing", tostring(v))
            PAB:UpdateAnchors(true)
        end)
    spacS:SetValue(db.iconSpacing or 1)

    -- Right column: checkboxes
    local rx = 310

    local c1 = Checkbox(f, rx, -50, "Arena Only", function(s)
        db.arena = s:GetChecked() and true or false; PAB:ApplyAnchorSettings() end)
    c1:SetChecked(db.arena)

    local c2 = Checkbox(f, rx, -76, "Hidden Until Cooldown", function(s)
        db.hidden = s:GetChecked() and true or false; PAB:ApplyAnchorSettings() end)
    c2:SetChecked(db.hidden)

    local c3 = Checkbox(f, rx, -102, "Movable Anchors", function(s)
        db.movable = s:GetChecked() and true or false; PAB:ApplyAnchorSettings(); PAB:LoadPositions() end)
    c3:SetChecked(db.movable)

    local c4 = Checkbox(f, rx, -128, "Lock Anchors", function(s)
        db.lock = s:GetChecked() and true or false; PAB:ApplyAnchorSettings() end)
    c4:SetChecked(db.lock)

    local c5 = Checkbox(f, rx, -154, "Auto-Detect CD Reductions", function(s)
        db.autoCooldowns = s:GetChecked() and true or false end)
    c5:SetChecked(db.autoCooldowns)

    local c6 = Checkbox(f, rx, -180, "Icon Border", function(s)
        db.iconBorder = s:GetChecked() and true or false; PAB:UpdateAnchors(true) end)
    c6:SetChecked(db.iconBorder)

    -- Grow Direction
    local growItems = { "RIGHT","Right", "LEFT","Left" }
    DropDown(f, "Grow Direction", rx, -218, 140, growItems,
        function() return db.growDirection or "RIGHT" end,
        function(v) db.growDirection = v; PAB:UpdateAnchors(true) end)

    local hint = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", f, "TOPLEFT", rx + 150, -218); hint:SetWidth(140); hint:SetJustifyH("LEFT")
    hint:SetText(GREEN .. "Inspects party\nmembers for CD\nreductions." .. R)

    ---------------------------------------------------------------------------
    --  ABILITY EDITOR
    ---------------------------------------------------------------------------
    local aeY = -256
    Header(f, 16, aeY, "Ability Editor")

    local aeD = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    aeD:SetPoint("TOPLEFT", f, "TOPLEFT", 16, aeY - 14)
    aeD:SetText(GREEN .. "Abilities tracked :" .. R)

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

    DropDown(f, "Class", rx, aeY - 14, 160, classItems,
        function() return db.classSelected end,
        function(v) db.classSelected = v; PAB:RefreshAbilityList() end)

    Btn(f, "All", rx + 170, aeY - 14, 50, 24, function()
        local cls = db.classSelected
        if not db.enabledCooldowns[cls] then db.enabledCooldowns[cls] = {} end
        for ab in pairs(db.abilities[cls] or {}) do db.enabledCooldowns[cls][ab] = true end
        PAB:RefreshAbilityList(); PAB:UpdateAnchors(true)
    end)
    Btn(f, "None", rx + 225, aeY - 14, 50, 24, function()
        local cls = db.classSelected
        if not db.enabledCooldowns[cls] then db.enabledCooldowns[cls] = {} end
        for ab in pairs(db.abilities[cls] or {}) do db.enabledCooldowns[cls][ab] = false end
        PAB:RefreshAbilityList(); PAB:UpdateAnchors(true)
    end)

    Btn(f, "Reset Positions", rx, aeY - 52, 140, 24, function()
        db.positions = {}
        PAB:LoadPositions()
        PAB:UpdateAnchors(true)
        ChatFrame1:AddMessage(HDR .. "PAB" .. R .. ": Positions reset.")
    end)

    local cdH = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    cdH:SetPoint("TOPLEFT", f, "TOPLEFT", rx, aeY - 84); cdH:SetWidth(270); cdH:SetJustifyH("LEFT")
    cdH:SetText(GRAY .. "CD field = editable for talent/glyph spells.\nType a custom cooldown and press Enter." .. R)

    ---------------------------------------------------------------------------
    --  Spell list (Blizzard FauxScrollFrame)
    ---------------------------------------------------------------------------
    local listTop = aeY - 30
    local listBg = CreateFrame("Frame", nil, f)
    listBg:SetPoint("TOPLEFT", f, "TOPLEFT", 10, listTop)
    listBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 30)
    listBg:SetWidth(300)
    ApplyPanel(listBg)
    listBg:SetBackdropColor(panelBg[1] * 0.7, panelBg[2] * 0.7, panelBg[3] * 0.7, 0.70)

    local maxVis = 8

    local scrollFrame = CreateFrame("ScrollFrame", "PABScrollFrame", listBg, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4); scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)
    self.scrollFrame = scrollFrame

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, function()
            PAB:RefreshAbilityList()
        end)
    end)

    local listInner = CreateFrame("Frame", nil, listBg)
    listInner:SetPoint("TOPLEFT", 4, -4); listInner:SetPoint("TOPRIGHT", -24, -4)
    listInner:SetHeight(maxVis * ROW_H)

    self.abilityRows = {}

    for i = 1, maxVis do
        local row = CreateFrame("Frame", nil, listInner)
        row:SetHeight(ROW_H); row:SetPoint("TOPLEFT", 0, -(i-1)*ROW_H); row:SetPoint("RIGHT", 0, 0)
        local rbg = row:CreateTexture(nil, "BACKGROUND"); rbg:SetAllPoints()
        rbg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        rbg:SetVertexColor(unpack(i % 2 == 0 and ROW_B or ROW_A))

        local cbName = "PABRowChk" .. i
        local cb = CreateFrame("CheckButton", cbName, row, "UICheckButtonTemplate")
        cb:SetSize(22, 22); cb:SetPoint("LEFT", 0, 0)
        local cbText = _G[cbName .. "Text"]; if cbText then cbText:SetText("") end
        row.cb = cb

        local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(20, 20)
        icon:SetPoint("LEFT", cb, "RIGHT", 2, 0); icon:SetTexCoord(0.07, 0.9, 0.07, 0.90)
        row.icon = icon

        local nm = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nm:SetPoint("LEFT", icon, "RIGHT", 5, 0); nm:SetWidth(140); nm:SetJustifyH("LEFT")
        row.name = nm

        local cdTxt = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
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

        row:Hide(); self.abilityRows[i] = row
    end

    tinsert(UISpecialFrames, "PABOptionsFrame")
    self:RefreshAbilityList()
end

-------------------------------------------------------------------------------
--  Variant lookup
-------------------------------------------------------------------------------
local variantByName = {}
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

-------------------------------------------------------------------------------
--  Refresh
-------------------------------------------------------------------------------
function PAB:RefreshAbilityList()
    local rows = self.abilityRows; if not rows then return end
    local db = self.db; if not db then return end
    local cls = db.classSelected
    local abilities = db.abilities[cls]; if not abilities then return end

    local sorted = {}
    for ab, cd in pairs(abilities) do sorted[#sorted + 1] = { name = ab, cd = cd } end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    local total = #sorted; local maxVis = #rows
    if self.scrollFrame then FauxScrollFrame_Update(self.scrollFrame, total, maxVis, ROW_H) end
    local off = self.scrollFrame and FauxScrollFrame_GetOffset(self.scrollFrame) or 0

    if not db.enabledCooldowns[cls] then db.enabledCooldowns[cls] = {} end
    if not db.customCooldowns then db.customCooldowns = {} end
    if not db.manualOverrides then db.manualOverrides = {} end

    for i, row in ipairs(rows) do
        local di = i + off
        if di <= total then
            local e = sorted[di]; local abName = e.name; local baseCd = e.cd
            row.icon:SetTexture(PAB:FindAbilityIcon(abName))
            row.name:SetText(WHITE .. (self.itemForSpell[abName] or abName) .. R)
            local variant = variantByName[cls .. ":" .. abName]
            row.cdTxt:SetText(GRAY .. format("%ds", baseCd) .. R)

            if variant then
                row.editbox:Show()
                local custom = db.customCooldowns[cls] and db.customCooldowns[cls][abName]
                row.editbox:SetText(custom and custom > 0 and tostring(custom) or "")
                row.editbox.cls = cls; row.editbox.abName = abName
                row.editbox:SetScript("OnEnterPressed", function(s)
                    s:ClearFocus(); local val = tonumber(s:GetText())
                    if not db.customCooldowns[s.cls] then db.customCooldowns[s.cls] = {} end
                    if not db.manualOverrides[s.cls] then db.manualOverrides[s.cls] = {} end
                    if val and val > 0 then
                        db.customCooldowns[s.cls][s.abName] = val
                        db.manualOverrides[s.cls][s.abName] = true
                    else
                        db.customCooldowns[s.cls][s.abName] = nil
                        db.manualOverrides[s.cls][s.abName] = nil; s:SetText("")
                    end
                    PAB:UpdateAnchors(true); PAB:RefreshAbilityList()
                end)
                row.editbox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
            else
                row.editbox:Hide(); row.editbox:SetText("")
            end

            local checked = db.enabledCooldowns[cls][abName]
            if checked == nil then checked = false; db.enabledCooldowns[cls][abName] = false end
            row.cb:SetChecked(checked)
            row.cb:SetScript("OnClick", function(s)
                db.enabledCooldowns[cls][abName] = s:GetChecked() and true or false
                PAB:UpdateAnchors(true)
            end)
            row:Show()
        else row:Hide() end
    end
end

-------------------------------------------------------------------------------
--  Slash
-------------------------------------------------------------------------------
SLASH_PAB1 = "/pab"
SlashCmdList["PAB"] = function(msg)
    msg = lower(msg or "")
    if msg == "reset" then PABDB = nil; ReloadUI()
    else ToggleOptions() end
end

-------------------------------------------------------------------------------
--  InterfaceOptions registration (so it shows in ESC → Interface → AddOns)
-------------------------------------------------------------------------------
local ioPanel = CreateFrame("Frame", "PABInterfacePanel", UIParent)
ioPanel.name = "Party Ability Bars"
local ioTitle = ioPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
ioTitle:SetPoint("TOPLEFT", 16, -16)
ioTitle:SetText("|cff4fc3f7Party Ability Bars|r  v2.0")
local ioDesc = ioPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
ioDesc:SetPoint("TOPLEFT", ioTitle, "BOTTOMLEFT", 0, -12)
ioDesc:SetText("Type  |cff00d1ff/pab|r  to open the options panel.\nType  |cff00d1ff/pab reset|r  to reset all settings.")
local ioBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
ioBtn:SetSize(180, 26); ioBtn:SetPoint("TOPLEFT", ioDesc, "BOTTOMLEFT", 0, -16)
ioBtn:SetText("Open PAB Options")
ioBtn:SetScript("OnClick", function()
    HideUIPanel(InterfaceOptionsFrame)
    if GameMenuFrame and GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
    if not optionsFrame then PAB:CreateOptionsUI() end
    optionsFrame:Show()
    PAB:RefreshAbilityList()
end)
InterfaceOptions_AddCategory(ioPanel)