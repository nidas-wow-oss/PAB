-------------------------------------------------------------------------------
--  PAB  –  Party Ability Bars  v2.0
--  Author: Nidhaus  (rewrite – original concept by Kollektiv, Vendethiel, Lawz)
--  WotLK 3.3.5a
--  Core logic  –  UI lives in PAB_Options.lua
-------------------------------------------------------------------------------

-- Upvalues ---------------------------------------------------------------
local lower            = string.lower
local match            = string.match
local remove           = table.remove
local format           = string.format
local pairs, ipairs    = pairs, ipairs
local tonumber         = tonumber
local select           = select
local type             = type
local wipe             = wipe
local unpack           = unpack
local GetSpellInfo     = GetSpellInfo
local UnitClass        = UnitClass
local UnitGUID         = UnitGUID
local UnitName         = UnitName
local UnitRace         = UnitRace
local UnitIsDead       = UnitIsDead
local UnitIsConnected  = UnitIsConnected
local IsInInstance     = IsInInstance
local GetNumPartyMembers   = GetNumPartyMembers
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local InCombatLockdown = InCombatLockdown
local CanInspect       = CanInspect
local NotifyInspect    = NotifyInspect
local ClearInspectPlayer = ClearInspectPlayer
local GetTalentInfo    = GetTalentInfo
local GetActiveTalentGroup = GetActiveTalentGroup
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo      = GetItemInfo
local GetTime          = GetTime
local GetBattlefieldStatus = GetBattlefieldStatus

-------------------------------------------------------------------------------
--  Core frames
-------------------------------------------------------------------------------
local PAB        = CreateFrame("Frame", "PAB", UIParent)
local PABIcons   = CreateFrame("Frame", nil, UIParent)
local PABAnchor  = CreateFrame("Frame", nil, UIParent)

local db
local pGUID, pName
local iconlist    = {}
local anchors     = {}
local activeGUIDS = {}

-------------------------------------------------------------------------------
--  Chat helper
-------------------------------------------------------------------------------
local function print(...)
    for i = 1, select("#", ...) do
        ChatFrame1:AddMessage("|cff00d1ffPAB|r: " .. select(i, ...))
    end
end

local InArena = function()
    return (select(2, IsInInstance()) == "arena")
end

-------------------------------------------------------------------------------
--  SPELL DATA  –  Spec-gated abilities
-------------------------------------------------------------------------------
local specAbilities = {
    ["ROGUE"] = {
        [14185] = { talentGroup = 3, index = 14 },
        [51713] = { talentGroup = 3, index = 28 },
        [36554] = { talentGroup = 3, index = 25 },
        [51690] = { talentGroup = 2, index = 28 },
        [14177] = { talentGroup = 1, index = 13 },
        [13877] = { talentGroup = 2, index = 17 },  -- Blade Flurry
        [13750] = { talentGroup = 2, index = 21 },  -- Adrenaline Rush
    },
    ["PRIEST"] = {
        [47585] = { talentGroup = 3, index = 27 },
        [33206] = { talentGroup = 1, index = 25 },
        [15487] = { talentGroup = 3, index = 13 },
        [64044] = { talentGroup = 3, index = 23 },
        [10060] = { talentGroup = 1, index = 20 },  -- Power Infusion
        [47788] = { talentGroup = 2, index = 28 },  -- Guardian Spirit
    },
    ["DRUID"] = {
        [53201] = { talentGroup = 1, index = 28 },
        [61336] = { talentGroup = 2, index = 7  },
        [16979] = { talentGroup = 2, index = 14 },
        [50334] = { talentGroup = 2, index = 30 },
        [17116] = { talentGroup = 3, index = 12 },
        [18562] = { talentGroup = 3, index = 18 },
        [50516] = { talentGroup = 1, index = 26 },  -- Typhoon
    },
    ["HUNTER"] = {
        [19574] = { talentGroup = 1, index = 18 },
        [23989] = { talentGroup = 2, index = 14 },
        [34490] = { talentGroup = 2, index = 24 },
        [19503] = { talentGroup = 3, index = 9  },
        [49012] = { talentGroup = 3, index = 20 },
        [19577] = { talentGroup = 1, index = 12 },  -- Intimidation
    },
    ["MAGE"] = {
        [12043] = { talentGroup = 1, index = 16 },
        [11129] = { talentGroup = 2, index = 20 },
        [42950] = { talentGroup = 2, index = 25 },
        [11958] = { talentGroup = 3, index = 14 },
        [44572] = { talentGroup = 3, index = 28 },
        [12042] = { talentGroup = 1, index = 24 },  -- Arcane Power
        [11113] = { talentGroup = 2, index = 19 },  -- Blast Wave
        [12472] = { talentGroup = 3, index = 10 },  -- Icy Veins
    },
    ["PALADIN"] = {
        [31821] = { talentGroup = 1, index = 6  },
        [48825] = { talentGroup = 1, index = 18 },
        [64205] = { talentGroup = 2, index = 6  },
        [48827] = { talentGroup = 2, index = 22 },
        [66008] = { talentGroup = 3, index = 18 },
        [20216] = { talentGroup = 1, index = 12 },  -- Divine Favor
        [31842] = { talentGroup = 1, index = 22 },  -- Divine Illumination
    },
    ["SHAMAN"] = {
        [16188] = { talentGroup = 3, index = 13 },
        [16166] = { talentGroup = 1, index = 16 },
        [51490] = { talentGroup = 1, index = 25 },
        [30823] = { talentGroup = 2, index = 26 },
        [51533] = { talentGroup = 2, index = 30 },  -- Feral Spirit
        [16190] = { talentGroup = 3, index = 20 },  -- Mana Tide Totem
    },
    ["WARLOCK"] = {
        [47847] = { talentGroup = 3, index = 23 },
        [18708] = { talentGroup = 2, index = 10 },
        [59672] = { talentGroup = 2, index = 26 },  -- Metamorphosis
    },
    ["WARRIOR"] = {
        [46924] = { talentGroup = 1, index = 31 },
        [12809] = { talentGroup = 3, index = 14 },
        [46968] = { talentGroup = 3, index = 27 },
        [12292] = { talentGroup = 2, index = 13 },  -- Death Wish
        [12975] = { talentGroup = 3, index = 7  },  -- Last Stand
    },
    ["DEATHKNIGHT"] = {
        [49039] = { talentGroup = 2, index = 8  },
        [49203] = { talentGroup = 2, index = 20 },
        [51271] = { talentGroup = 2, index = 24 },
        [51052] = { talentGroup = 3, index = 22 },
        [49206] = { talentGroup = 3, index = 31 },
        [49016] = { talentGroup = 1, index = 23 },  -- Unholy Frenzy
        [48982] = { talentGroup = 1, index = 11 },  -- Rune Tap
        [55233] = { talentGroup = 1, index = 21 },  -- Vampiric Blood
    },
}

-------------------------------------------------------------------------------
--  Default abilities with BASE cooldowns
-------------------------------------------------------------------------------
local defaultAbilities = {
    ["DRUID"] = {
        [29166]=180, [22812]=60, [8983]=60, [53201]=60, [50334]=180,
        [61336]=180, [16979]=15, [18562]=13, [17116]=180,
        [1850]=300,  -- Dash
        [50516]=20,  -- Typhoon
    },
    ["HUNTER"] = {
        [19503]=30, [60192]=28, [13809]=28, [14311]=28, [19574]=120,
        [34490]=20, [23989]=180, [19263]=90, [67481]=60, [53271]=60, [49012]=60,
        [3045]=300,  -- Rapid Fire
        [34600]=28,  -- Snake Trap
        [19577]=60,  -- Intimidation
    },
    ["MAGE"] = {
        [1953]=15, [2139]=24, [44572]=30, [12051]=240, [45438]=300,
        [11958]=384, [12043]=60, [11129]=120, [42950]=20,
        [122]=25,    -- Frost Nova
        [12042]=180, -- Arcane Power
        [11113]=30,  -- Blast Wave
        [12472]=180, -- Icy Veins
    },
    ["PALADIN"] = {
        [10308]=60, [1044]=25, [54428]=60, [6940]=120, [10278]=180,
        [642]=300, [31821]=120, [66008]=60, [64205]=120, [48825]=6, [48827]=30,
        [31884]=180, -- Avenging Wrath
        [20216]=120, -- Divine Favor
        [31842]=180, -- Divine Illumination
    },
    ["PRIEST"] = {
        [10890]=30, [48158]=12, [47585]=120, [33206]=180, [15487]=45,
        [64044]=120, [34433]=300, [6346]=180,
        [10060]=96,  -- Power Infusion
        [47788]=180, -- Guardian Spirit
        [19236]=120, -- Desperate Prayer
        [64843]=480, -- Divine Hymn
        [64901]=360, -- Hymn of Hope
    },
    ["ROGUE"] = {
        [1766]=10, [8643]=20, [31224]=90, [51722]=60, [2094]=180,
        [26889]=180, [14185]=300, [51713]=60, [51690]=120, [14177]=180, [36554]=20,
        [5277]=180,  -- Evasion
        [13877]=120, -- Blade Flurry
        [13750]=180, -- Adrenaline Rush
    },
    ["SHAMAN"] = {
        [57994]=6, [51514]=45, [16188]=120, [8177]=15,
        [51490]=45, [30823]=60, [16166]=180,
        [51533]=180, -- Feral Spirit
        [16190]=300, -- Mana Tide Totem
    },
    ["WARLOCK"] = {
        [19647]=24, [17925]=120, [18708]=180, [48011]=8,
        [48020]=30, [47847]=20,
        [5484]=40,   -- Howl of Terror
        [59672]=180, -- Metamorphosis
    },
    ["WARRIOR"] = {
        [6552]=10, [72]=12, [11578]=15, [47996]=30, [46924]=90,
        [871]=300, [2565]=60, [676]=60, [12809]=30, [46968]=20,
        [1719]=300,  -- Recklessness
        [3411]=30,   -- Intervene
        [5246]=120,  -- Intimidating Shout
        [18499]=30,  -- Berserker Rage
        [23920]=10,  -- Spell Reflection
        [20230]=300, -- Retaliation
        [55694]=180, -- Enraged Regeneration
        [12292]=180, -- Death Wish
        [12975]=180, -- Last Stand
    },
    ["DEATHKNIGHT"] = {
        [47528]=10, [47481]=20, [48743]=120, [49206]=180, [51052]=120,
        [49576]=35, [48707]=45, [47476]=120, [49039]=120, [49203]=60,
        [51271]=60, [48792]=120,
        [49016]=180, -- Unholy Frenzy
        [48982]=40,  -- Rune Tap
        [55233]=60,  -- Vampiric Blood
    },
    -- Racials
    ["Scourge"]  = { [7744]=120,  [42292]=120 },
    ["BloodElf"] = { [28730]=120, [42292]=120 },
    ["Tauren"]   = { [20549]=120, [42292]=120 },
    ["Orc"]      = { [42292]=120, [20572]=120 },   -- Blood Fury
    ["Troll"]    = { [42292]=120, [26297]=180 },   -- Berserking
    ["NightElf"] = { [42292]=120, [58984]=120 },   -- Shadowmeld
    ["Draenei"]  = { [42292]=120, [28880]=180 },   -- Gift of the Naaru
    ["Human"]    = { [59752]=120 },
    ["Gnome"]    = { [42292]=120, [20589]=60 },    -- Escape Artist
    ["Dwarf"]    = { [20594]=120, [42292]=120 },
    -- Items
    ["Items"]    = { [71607]=120 },
}

-------------------------------------------------------------------------------
--  Cooldown Variants  –  talent/glyph-reducible spells
-------------------------------------------------------------------------------
local cooldownVariants = {
    [10308] = { base=60,  min=40,  talentTab=3, talentIndex=3,  talentPoints=2, reductionPerPoint=10,    desc="Improved HoJ (Ret)" },
    [51490] = { base=45,  min=35,  glyphID=63291, glyphReduction=10,                                    desc="Glyph of Thunder" },
    [33206] = { base=180, min=144, talentTab=1, talentIndex=19, talentPoints=2, reductionPctPerPoint=10, desc="Aspiration (Disc)" },
    [47585] = { base=120, min=75,  glyphID=63229, glyphReduction=45,                                    desc="Glyph of Dispersion" },
    [10890] = { base=30,  min=26,  talentTab=3, talentIndex=2,  talentPoints=2, reductionPerPoint=2,     desc="Imp. Psychic Scream" },
    [31224] = { base=90,  min=60,  talentTab=3, talentIndex=8,  talentPoints=2, reductionPerPoint=15,    desc="Elusiveness (Sub)" },
    [2094]  = { base=180, min=120, talentTab=3, talentIndex=8,  talentPoints=2, reductionPerPoint=30,    desc="Elusiveness (Sub)" },
    [26889] = { base=180, min=120, talentTab=3, talentIndex=8,  talentPoints=2, reductionPerPoint=30,    desc="Elusiveness (Sub)" },
    [19574] = { base=120, min=84,  talentTab=1, talentIndex=20, talentPoints=3, reductionPctPerPoint=10, desc="Longevity (BM)" },
    [19263] = { base=90,  min=60,  glyphID=56850, glyphReduction=10,                                    desc="Glyph of Deterrence" },
    [49576] = { base=35,  min=25,  talentTab=3, talentIndex=2,  talentPoints=2, reductionPerPoint=5,     desc="Unholy Command" },
    [57994] = { base=6,   min=1,   talentTab=1, talentIndex=5,  talentPoints=5, reductionPerPoint=1,     desc="Reverberation (Ele)" },
    [47476] = { base=120, min=100, glyphID=58618, glyphReduction=20,                                    desc="Glyph of Strangulate" },
    [48792] = { base=120, min=90,  glyphID=58625, glyphReduction=30,                                    desc="Glyph of IBF" },
    [46924] = { base=90,  min=75,  glyphID=63324, glyphReduction=15,                                    desc="Glyph of Bladestorm" },
    [47996] = { base=30,  min=15,  talentTab=2, talentIndex=6,  talentPoints=2, reductionPerPoint=5,     desc="Imp. Intercept (Fury)" },
}
for id, data in pairs(cooldownVariants) do data.spellID = id end

-------------------------------------------------------------------------------
--  Item-to-spell mapping
-------------------------------------------------------------------------------
local itemForSpell = {}
do
    local name = GetSpellInfo(71607)
    local item = GetItemInfo(50354)
    if name then itemForSpell[name] = item end
end

-------------------------------------------------------------------------------
--  Icon path cache
-------------------------------------------------------------------------------
local iconPaths = {}
do
    local n1 = GetSpellInfo(71607)
    if n1 then iconPaths[n1] = "Interface\\Icons\\inv_jewelcrafting_gem_28" end
    local n2 = GetSpellInfo(42292)
    if n2 then iconPaths[n2] = "Interface\\Icons\\Inv_jewelry_trinketpvp_02" end
end

-------------------------------------------------------------------------------
--  convertspellids  –  ID-keyed → spellName-keyed
-------------------------------------------------------------------------------
local function convertspellids(t, fillwith)
    local temp = {}
    for class, tbl in pairs(t) do
        temp[class] = {}
        for id, v in pairs(tbl) do
            local spellName, _, spellIcon = GetSpellInfo(id)
            if spellName then
                if not iconPaths[spellName] then iconPaths[spellName] = spellIcon end
                temp[class][spellName] = (fillwith ~= nil) and fillwith or v
            end
        end
    end
    return temp
end

local allCooldownIds = convertspellids(defaultAbilities, true)

-- New spells added from TPT: default to OFF so they don't spam
do
    local newSpellIds = {
        1850, 50516,                             -- Druid: Dash, Typhoon
        3045, 34600, 19577,                      -- Hunter: Rapid Fire, Snake Trap, Intimidation
        122, 12042, 11113, 12472,                -- Mage: Frost Nova, Arcane Power, Blast Wave, Icy Veins
        31884, 20216, 31842,                     -- Paladin: Avenging Wrath, Divine Favor, Divine Illumination
        10060, 47788, 19236, 64843, 64901,       -- Priest: Power Infusion, Guardian Spirit, Desperate Prayer, Divine Hymn, Hymn of Hope
        5277, 13877, 13750,                      -- Rogue: Evasion, Blade Flurry, Adrenaline Rush
        51533, 16190,                            -- Shaman: Feral Spirit, Mana Tide Totem
        5484, 59672,                             -- Warlock: Howl of Terror, Metamorphosis
        1719, 3411, 5246, 18499, 23920, 20230,   -- Warrior
        55694, 12292, 12975,                     -- Warrior: Enraged Regen, Death Wish, Last Stand
        49016, 48982, 55233,                     -- DK: Unholy Frenzy, Rune Tap, Vampiric Blood
        58984, 20589, 28880, 20572, 26297,       -- Racials: Shadowmeld, Escape Artist, Gift of Naaru, Blood Fury, Berserking
    }
    for _, id in ipairs(newSpellIds) do
        local spName = GetSpellInfo(id)
        if spName then
            for cls, tbl in pairs(allCooldownIds) do
                if tbl[spName] ~= nil then tbl[spName] = false end
            end
        end
    end
end
defaultAbilities     = convertspellids(defaultAbilities)
specAbilities        = convertspellids(specAbilities)

local groupedCooldowns = {
    ["DRUID"]  = { [16979]=1, [49376]=1 },
    ["SHAMAN"] = { [49231]=1, [49233]=1, [49236]=1 },
    ["HUNTER"] = { [60192]=1, [14311]=1, [13809]=1, [49067]=2, [49056]=2, [34600]=3 },
    ["MAGE"]   = { [43010]=1, [43012]=1 },
    ["WARRIOR"]= { [72]=1, [6552]=1, [871]=2, [20230]=2, [1719]=2 },
}
groupedCooldowns = convertspellids(groupedCooldowns)

local cooldownResetters = {
    [11958] = { -- Cold Snap
        [42931]=1,[42917]=1,[43012]=1,[43039]=1,[45438]=1,[31687]=1,[44572]=1,[12472]=1,
        [122]=1,    -- Frost Nova (base ID)
    },
    [14185] = { -- Preparation
        [14177]=1,[26669]=1,[11305]=1,[26889]=1,[36554]=1,[1766]=10,[51722]=60,
        [5277]=1,   -- Evasion
    },
    [23989] = { -- Readiness
        [19503]=1,[60192]=1,[13809]=1,[14311]=1,[19574]=1,[34490]=1,[19263]=1,[53271]=1,[49012]=1,
        [3045]=1,   -- Rapid Fire
        [34600]=1,  -- Snake Trap
    },
}
do
    local temp = {}
    for id, v in pairs(cooldownResetters) do
        local name = GetSpellInfo(id)
        if name then
            if type(v) == "table" then
                temp[name] = {}
                for subId in pairs(v) do
                    local sn = GetSpellInfo(subId)
                    if sn then temp[name][sn] = 1 end
                end
            else temp[name] = v end
        end
    end
    cooldownResetters = temp
end
convertspellids = nil

-------------------------------------------------------------------------------
--  GetEffectiveCooldown
-------------------------------------------------------------------------------
local function GetEffectiveCooldown(class, abilityName, baseCooldown)
    if db and db.customCooldowns and db.customCooldowns[class] then
        local custom = db.customCooldowns[class][abilityName]
        if custom and custom > 0 then return custom end
    end
    return baseCooldown
end

-------------------------------------------------------------------------------
--  ★  Expose shared data for PAB_Options.lua  ★
-------------------------------------------------------------------------------
PAB.cooldownVariants     = cooldownVariants
PAB.defaultAbilities     = defaultAbilities
PAB.itemForSpell         = itemForSpell
PAB.allCooldownIds       = allCooldownIds
PAB.GetEffectiveCooldown = GetEffectiveCooldown

-------------------------------------------------------------------------------
--  Position saving / loading
-------------------------------------------------------------------------------
function PAB:SavePositions()
    for k, anchor in ipairs(anchors) do
        local scale      = anchor:GetEffectiveScale()
        local worldscale = UIParent:GetEffectiveScale()
        local x = anchor:GetLeft() * scale
        local y = (anchor:GetTop() * scale) - (UIParent:GetTop() * worldscale)
        if not db.positions[k] then db.positions[k] = {} end
        db.positions[k].x = x; db.positions[k].y = y
    end
end

function PAB:LoadPositions()
    db.positions = db.positions or {}
    for k, anchor in ipairs(anchors) do
        anchor:ClearAllPoints()
        if db.positions[k] and db.movable then
            local x, y = db.positions[k].x, db.positions[k].y
            local scale = anchor:GetEffectiveScale()
            anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x/scale, y/scale)
        elseif not db.movable then
            anchor:SetPoint("TOPLEFT", "PartyMemberFrame"..k, "TOPLEFT", db.xanchor or -88, db.yanchor or 17)
        else
            -- No saved position yet, default to stacked center
            anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 50 - (k * 100))
        end
    end
end

-------------------------------------------------------------------------------
--  Anchors
-------------------------------------------------------------------------------
local backdrop = { bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="", tile=false }

function PAB:CreateAnchors()
    for i = 1, 4 do
        local anchor = CreateFrame("Frame", "PABAnchor"..i, PABAnchor)
        anchor:SetBackdrop(backdrop); anchor:SetHeight(15); anchor:SetWidth(15)
        anchor:SetBackdropColor(0, 0.82, 1, 0.8)
        anchor:EnableMouse(true); anchor:SetMovable(true)
        anchor:SetClampedToScreen(true)  -- prevent dragging off-screen
        anchor:Show()
        anchor.icons = {}
        anchor.HideIcons = function()
            for _, ic in ipairs(anchor.icons) do ic:Hide(); ic.shouldShow = nil end
        end
        anchor:SetScript("OnMouseDown", function(s, btn) if btn == "LeftButton" then s:StartMoving() end end)
        anchor:SetScript("OnMouseUp", function(s, btn) if btn == "LeftButton" then s:StopMovingOrSizing(); PAB:SavePositions() end end)
        anchors[i] = anchor
        local idx = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        idx:SetPoint("CENTER"); idx:SetText(i)
    end
end

-------------------------------------------------------------------------------
--  Icons
-------------------------------------------------------------------------------
local function CreateIcon(anchor)
    local icon = CreateFrame("Frame", anchor:GetName().."Icon".. (#anchor.icons+1), PABIcons)
    icon:SetHeight(30); icon:SetWidth(30)

    -- Spell texture (full icon area)
    local texture = icon:CreateTexture(nil,"ARTWORK")
    texture:SetAllPoints(); texture:SetTexCoord(0.07,0.9,0.07,0.90)
    icon.texture = texture

    -- Cooldown spiral
    local cd = CreateFrame("Cooldown", icon:GetName().."Cooldown", icon, "CooldownFrameTemplate")
    cd:SetAllPoints()
    icon.cd = cd

    -- Border: 4 thin edge lines (1px each)
    local BW = 1
    local edges = {}
    for _, info in ipairs({
        {"TOP",    "TOPLEFT","TOPRIGHT",    nil,nil,  BW,nil},
        {"BOTTOM", "BOTTOMLEFT","BOTTOMRIGHT", nil,nil, BW,nil},
        {"LEFT",   "TOPLEFT","BOTTOMLEFT",  nil,nil,  nil,BW},
        {"RIGHT",  "TOPRIGHT","BOTTOMRIGHT", nil,nil,  nil,BW},
    }) do
        local e = icon:CreateTexture(nil, "OVERLAY")
        e:SetTexture("Interface\\Buttons\\WHITE8X8")
        e:SetVertexColor(0, 0, 0, 0.9)
        e:SetPoint(info[2]); e:SetPoint(info[3])
        if info[6] then e:SetHeight(info[6]) end
        if info[7] then e:SetWidth(info[7]) end
        edges[#edges+1] = e
    end
    icon.edges = edges

    local function UpdateBorder()
        local show = db.iconBorder
        for _, e in ipairs(edges) do
            if show then e:Show() else e:Hide() end
        end
    end
    icon.UpdateBorder = UpdateBorder
    UpdateBorder()

    icon.Start = function(sentCD)
        icon.cooldown = tonumber(sentCD)
        CooldownFrame_SetTimer(cd, GetTime(), icon.cooldown, 1)
        icon:Show(); icon.active = true; icon.starttime = GetTime()+0.4
        texture:SetDesaturated(true)
        activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
        activeGUIDS[icon.GUID][icon.ability] = activeGUIDS[icon.GUID][icon.ability] or {}
        activeGUIDS[icon.GUID][icon.ability].starttime = icon.starttime
        activeGUIDS[icon.GUID][icon.ability].cooldown  = icon.cooldown
    end
    icon.Stop = function()
        CooldownFrame_SetTimer(cd,0,0,0); icon.starttime = 0
        texture:SetDesaturated(false)
    end
    icon.SetTimer = function(st, cd2)
        CooldownFrame_SetTimer(cd,st,cd2,1); icon.active=true; icon.starttime=st; icon.cooldown=cd2
        texture:SetDesaturated(true)
    end

    return icon
end

function PAB:AppendIcon(icons, anchor)
    local ni = CreateIcon(anchor)
    iconlist[#iconlist+1] = ni
    local spacing = db.iconSpacing or 1
    local grow = db.growDirection or "RIGHT"

    if #icons == 0 then
        if grow == "LEFT" then
            ni:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
        else
            ni:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
        end
    elseif db.iconsperline ~= 0 and (#icons % db.iconsperline) == 0 then
        local rowStart = icons[#icons - db.iconsperline + 1]
        if grow == "LEFT" then
            ni:SetPoint("TOPRIGHT", rowStart, "BOTTOMRIGHT", 0, -spacing)
        else
            ni:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -spacing)
        end
    else
        if grow == "LEFT" then
            ni:SetPoint("TOPRIGHT", icons[#icons], "TOPLEFT", -spacing, 0)
        else
            ni:SetPoint("TOPLEFT", icons[#icons], "TOPRIGHT", spacing, 0)
        end
    end
    icons[#icons+1] = ni
    return ni
end

function PAB:FindAbilityIcon(ability)
    if iconPaths[ability] then return iconPaths[ability] end
    local _, _, icon = GetSpellInfo(ability)
    if icon then iconPaths[ability] = icon; return icon end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function PAB:FormatAbility(s)
    s = s:gsub("(%a)(%a*)('*)(%a*)", function(a,b,c,d) return a:upper()..b:lower()..c..d:lower() end)
    s = s:gsub("(The)", lower); s = s:gsub("(Of)", lower)
    return s
end

-------------------------------------------------------------------------------
--  Show / Hide helpers
-------------------------------------------------------------------------------
function PAB:ShowUsedAnchors()   for i=1,GetNumPartyMembers() do anchors[i]:Show() end end
function PAB:HideUnusedAnchors() for k=GetNumPartyMembers()+1,#anchors do anchors[k]:Hide(); anchors[k].HideIcons() end end
function PAB:HideUnusedIcons(n, icons) for j=n,#icons do icons[j]:Hide(); icons[j].shouldShow=nil end end
function PAB:ResetAnchorsSpecAndItems() for i=1,#anchors do anchors[i].spec=nil; anchors[i].items=nil end end

local function array_contains(tab, val)
    if not tab then return false end
    for _,v in pairs(tab) do if v == val then return true end end
    return false
end

-------------------------------------------------------------------------------
--  UpdateAnchors
-------------------------------------------------------------------------------
function PAB:UpdateAnchors(updateIcons)
    if updateIcons then
        -- Wipe global iconlist to prevent frame leak
        wipe(iconlist)
    end
    for idx=1,GetNumPartyMembers() do
        local uName = "party"..idx
        local _, class = UnitClass(uName)
        if class then  -- skip instead of return if class is nil
            local anchor = anchors[idx]
            anchor.GUID = UnitGUID(uName); anchor.class = class; anchor.race = select(2,UnitRace(uName))
            if updateIcons then
                for _, ic in ipairs(anchor.icons) do ic:Hide(); ic:SetParent(nil); ic:ClearAllPoints() end
                anchor.icons = {}
            end
            local num = 1
            if anchor.race and db.abilities[anchor.race] then
                for ab, cd in pairs(db.abilities[anchor.race]) do
                    local t = db.enabledCooldowns[anchor.race]
                    if t and t[ab] then
                        self:UpdateAnchorIcon(anchor, num, ab, GetEffectiveCooldown(anchor.race, ab, cd)); num=num+1
                    end
                end
            end
            if anchor.items then
                for ab, cd in pairs(db.abilities["Items"] or {}) do
                    local iName = itemForSpell[ab]
                    local t = db.enabledCooldowns["Items"]
                    if t and t[ab] and array_contains(anchor.items, iName) then
                        self:UpdateAnchorIcon(anchor, num, ab, cd); num=num+1
                    end
                end
            end
            local specSpells = specAbilities[class] or {}
            for ab, cd in pairs(db.abilities[class] or {}) do
                local t = db.enabledCooldowns[class]
                if t and t[ab] then
                    if not specSpells[ab] or (anchor.spec and anchor.spec[ab]) then
                        self:UpdateAnchorIcon(anchor, num, ab, GetEffectiveCooldown(class, ab, cd)); num=num+1
                    end
                end
            end
            self:HideUnusedIcons(num, anchor.icons)
        end
    end
    -- Rebuild iconlist from all active anchors (prevents stale references)
    if updateIcons then
        for _, anch in ipairs(anchors) do
            for _, ic in ipairs(anch.icons) do
                iconlist[#iconlist+1] = ic
            end
        end
    end
    self:ShowUsedAnchors(); self:HideUnusedAnchors(); self:ApplyAnchorSettings()
end

function PAB:UpdateAnchorIcon(anchor, numIcons, ability, cooldown)
    local icons = anchor.icons
    local icon = icons[numIcons] or self:AppendIcon(icons, anchor)
    icon.texture:SetTexture(self:FindAbilityIcon(ability))
    icon.GUID=anchor.GUID; icon.ability=ability; icon.cooldown=cooldown; icon.shouldShow=true
    activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
    if activeGUIDS[icon.GUID][icon.ability] then
        icon.SetTimer(activeGUIDS[icon.GUID][ability].starttime, activeGUIDS[icon.GUID][ability].cooldown)
    else icon.Stop() end
end

function PAB:ApplyAnchorSettings()
    PABIcons:SetScale(db.scale or 1)
    if db.arena then (InArena() and PABIcons.Show or PABIcons.Hide)(PABIcons)
    else PABIcons:Show() end
    for _, anch in ipairs(anchors) do
        for _, ic in ipairs(anch.icons) do
            if db.hidden and not ic.active then ic:Hide()
            elseif ic.shouldShow then ic:Show() end
        end
    end
    if db.lock or not db.movable then PABAnchor:Hide() else PABAnchor:Show() end
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
function PAB:UPDATE_BATTLEFIELD_STATUS(idx)
    if idx ~= 1 then return end
    if GetBattlefieldStatus(idx) == "active" then self:UpdateAnchors(false); self:ResetAnchorsSpecAndItems() end
end

function PAB:PARTY_MEMBERS_CHANGED()
    if not pGUID then pGUID = UnitGUID("player") end
    if not pName then pName = UnitName("player") end
    self.inspectData = { throttle = 0 }
    self:UpdateAnchors(false); self:ResetAnchorsSpecAndItems()
end

function PAB:PLAYER_ENTERING_WORLD()
    if InArena() then self:StopAllIcons(); self.inspectData = { throttle = 0 } end
    if not pGUID then pGUID = UnitGUID("player") end
    if not pName then pName = UnitName("player") end
    self:UpdateAnchors(false); self:ResetAnchorsSpecAndItems()
end

function PAB:CheckAbility(anchor, ability, cooldown)
    if not cooldown then return end
    for _, icon in ipairs(anchor.icons) do
        if icon.ability == ability and icon.shouldShow then icon.Start(cooldown) end
        if groupedCooldowns[anchor.class] and groupedCooldowns[anchor.class][ability] then
            local castGroup = groupedCooldowns[anchor.class][ability]
            for grp, grpNum in pairs(groupedCooldowns[anchor.class]) do
                if grpNum == castGroup and grp == icon.ability and icon.shouldShow then
                    icon.Start(cooldown); break
                end
            end
        end
        if cooldownResetters[ability] then
            if type(cooldownResetters[ability]) == "table" then
                for k in pairs(cooldownResetters[ability]) do if k == icon.ability then icon.Stop(); break end end
            else icon.Stop() end
        end
    end
end

-- Spec swap spell names (cached once, locale-safe)
local specSwapSpells = {}
do
    local n1 = GetSpellInfo(63645); local n2 = GetSpellInfo(63644)
    if n1 then specSwapSpells[n1] = true end
    if n2 then specSwapSpells[n2] = true end
end

function PAB:UNIT_SPELLCAST_SUCCEEDED(unit, ability)
    if unit == "player" then return end
    local pIdx = match(unit, "party[pet]*([1-4])")
    if not pIdx then return end
    pIdx = tonumber(pIdx)
    local actualUnit = "party"..pIdx
    if ability and specSwapSpells[ability] then
        if anchors[pIdx] then anchors[pIdx].spec = nil end; return
    end
    if ability then
        local _, class = UnitClass(actualUnit)
        local _, race  = UnitRace(actualUnit)
        local cd
        if class and db.abilities[class] then
            cd = db.abilities[class][ability]
            if cd then cd = GetEffectiveCooldown(class, ability, cd) end
        end
        if not cd and race and db.abilities[race] then
            cd = db.abilities[race][ability]
            if cd then cd = GetEffectiveCooldown(race, ability, cd) end
        end
        if not cd and db.abilities["Items"] then cd = db.abilities["Items"][ability] end
        if cd and anchors[pIdx] then self:CheckAbility(anchors[pIdx], ability, cd) end
    end
end

function PAB:UNIT_INVENTORY_CHANGED(unit)
    if unit == "player" then return end
    local pIdx = match(unit, "party[pet]*([1-4])")
    if pIdx then pIdx = tonumber(pIdx); if anchors[pIdx] then anchors[pIdx].items = nil end end
end

function PAB:StopAllIcons()
    for _, v in ipairs(iconlist) do v.Stop() end; wipe(activeGUIDS)
end

-------------------------------------------------------------------------------
--  Timer / OnUpdate
-------------------------------------------------------------------------------
local timers, timerfuncs, timerargs = {}, {}, {}
function PAB:Schedule(dur, func, ...)
    timers[#timers+1]=dur; timerfuncs[#timerfuncs+1]=func; timerargs[#timerargs+1]={...}
end

local elapsed_acc = 0
local function PAB_OnUpdate(self, elapsed)
    elapsed_acc = elapsed_acc + elapsed
    if elapsed_acc < 0.05 then return end
    for _, icon in ipairs(iconlist) do
        if icon.active then
            icon.timeleft = icon.starttime + icon.cooldown - GetTime()
            if icon.timeleft <= 0 then
                if db.hidden then icon:Hide() end
                if icon.GUID and icon.ability and activeGUIDS[icon.GUID] then activeGUIDS[icon.GUID][icon.ability] = nil end
                icon.active = nil
                if icon.texture then icon.texture:SetDesaturated(false) end
            end
        end
    end
    for i = #timers,1,-1 do
        timers[i] = timers[i] - elapsed_acc
        if timers[i] <= 0 then
            local fn, args = timerfuncs[i], timerargs[i]
            remove(timers,i); remove(timerfuncs,i); remove(timerargs,i)
            fn(PAB, unpack(args))
        end
    end
    elapsed_acc = 0
    PAB:QuerySpecInfo(elapsed)
end

-------------------------------------------------------------------------------
--  Inspect system
-------------------------------------------------------------------------------
PAB.inspectData = { frame=nil, current=nil, throttle=0, lastQuery=nil }

function PAB:QuerySpecInfo(elapsed)
    local id = self.inspectData
    id.throttle = (id.throttle or 0) + elapsed
    if id.lastQuery then
        id.lastQuery = id.lastQuery + elapsed
        if id.lastQuery > 10 then id.current=nil; id.lastQuery=nil end
    end
    if id.throttle < 0.5 then return end
    id.throttle = 0
    if InCombatLockdown() or id.current or UnitIsDead("player") then return end
    if InspectFrame and InspectFrame:IsShown() then return end

    if not id.frame then
        id.frame = CreateFrame("Frame")
        id.frame:SetScript("OnEvent", function()
            if InCombatLockdown() then return end
            if InspectFrame and InspectFrame:IsShown() then return end
            if not id.current then return end
            local anchor = anchors[id.current]
            if not anchor or not anchor.class then id.current = nil; return end
            -- Spec talents
            local specSpells = specAbilities[anchor.class]
            if specSpells then
                anchor.spec = {}
                local found = false
                for ab, spell in pairs(specSpells) do
                    local has = select(5, GetTalentInfo(spell.talentGroup, spell.index, true, false, GetActiveTalentGroup(true))) > 0
                    found = found or has; anchor.spec[ab] = has
                end
                if not found then anchor.spec = nil end
            end
            -- Auto-detect CD reductions
            if anchor.class and db.autoCooldowns then
                local _, cls = UnitClass("party"..id.current)
                if cls then
                    for spID, vdata in pairs(cooldownVariants) do
                        local spName = GetSpellInfo(spID)
                        if spName and db.abilities[cls] and db.abilities[cls][spName] then
                            local rcd = vdata.base
                            if vdata.talentTab and vdata.talentIndex then
                                local _,_,_,_,pts = GetTalentInfo(vdata.talentTab, vdata.talentIndex, true, false, GetActiveTalentGroup(true))
                                if pts and pts > 0 then
                                    if vdata.reductionPerPoint then rcd = rcd - (pts * vdata.reductionPerPoint)
                                    elseif vdata.reductionPctPerPoint then rcd = rcd * (1 - (pts * vdata.reductionPctPerPoint / 100)) end
                                end
                            end
                            if vdata.glyphID and vdata.glyphReduction then
                                for slot=1,6 do
                                    local _,_,_,gid = GetGlyphSocketInfo(slot, nil, true)
                                    if gid == vdata.glyphID then rcd = rcd - vdata.glyphReduction; break end
                                end
                            end
                            if rcd < (vdata.min or 1) then rcd = vdata.min or 1 end
                            if not db.customCooldowns then db.customCooldowns = {} end
                            if not db.customCooldowns[cls] then db.customCooldowns[cls] = {} end
                            if not db.manualOverrides or not db.manualOverrides[cls] or not db.manualOverrides[cls][spName] then
                                db.customCooldowns[cls][spName] = math.floor(rcd + 0.5)
                            end
                        end
                    end
                end
            end
            -- Items
            anchor.items = {}
            for slot=13,14 do
                local link = GetInventoryItemLink("party"..id.current, slot)
                if link then anchor.items[slot] = GetItemInfo(link) end
            end
            PAB:UpdateAnchors(true); ClearInspectPlayer(); id.current = nil
        end)
        id.frame:RegisterEvent("INSPECT_TALENT_READY")
    end

    for i=1,GetNumPartyMembers() do
        local anchor = anchors[i]
        if not anchor then return end
        if (not anchor.spec or not anchor.items) and CanInspect("party"..i) and UnitIsConnected("party"..i) then
            id.current = i; id.lastQuery = 0; NotifyInspect("party"..i); break
        end
    end
end

-------------------------------------------------------------------------------
--  Initialization
-------------------------------------------------------------------------------
local function PAB_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    self:SetScript("OnEvent", function(s, event, ...) if PAB[event] then PAB[event](PAB, ...) end end)

    PABDB = PABDB or {
        scale=0.9, lock=true, arena=false, hidden=true, movable=false,
        iconsperline=0, xanchor=-88, yanchor=17, autoCooldowns=true,
        iconSpacing=1, iconBorder=true, growDirection="RIGHT",
        positions = { {x=1,y=-116},{x=1,y=-217},{x=1,y=-318},{x=1,y=-419} },
        enabledCooldowns = allCooldownIds,
        customCooldowns  = {},
        manualOverrides  = {},
    }
    PABDB.abilities        = defaultAbilities
    PABDB.enabledCooldowns = PABDB.enabledCooldowns or {}
    if not PABDB.enabledCooldowns["Items"] then
        PABDB.enabledCooldowns["Items"] = allCooldownIds["Items"] or {}
    end
    PABDB.customCooldowns = PABDB.customCooldowns or {}
    PABDB.manualOverrides = PABDB.manualOverrides or {}
    PABDB.xanchor         = PABDB.xanchor or -88
    PABDB.yanchor         = PABDB.yanchor or 17
    PABDB.autoCooldowns   = (PABDB.autoCooldowns ~= nil) and PABDB.autoCooldowns or true
    PABDB.iconSpacing     = PABDB.iconSpacing or 1
    PABDB.iconBorder      = (PABDB.iconBorder ~= nil) and PABDB.iconBorder or true
    PABDB.growDirection   = PABDB.growDirection or "RIGHT"
    PABDB.classSelected   = PABDB.classSelected or "WARRIOR"

    db     = PABDB
    PAB.db = db  -- ★ expose for PAB_Options.lua ★

    self:CreateAnchors()
    self:UpdateAnchors(false)
    self:LoadPositions()
    self:SetScript("OnUpdate", PAB_OnUpdate)

    print("v2.0 loaded. Type |cff00d1ff/pab|r to open settings.")
end

PAB:RegisterEvent("VARIABLES_LOADED")
PAB:SetScript("OnEvent", PAB_OnLoad)
