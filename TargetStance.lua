local ADDON = ...

local DEFAULTS = {
    warrior  = true,
    dk       = true,
    showText = true,
    locked   = true,
    scale    = 1,
    point    = "CENTER",
    x        = 0,
    y        = 200,
}

local db = DEFAULTS

local f = CreateFrame("Frame", "TargetStanceFrame", UIParent)
f:SetSize(40, 40)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
f:SetMovable(true)
f:SetClampedToScreen(true)
f:Hide()

f.texture = f:CreateTexture(nil, "BACKGROUND")
f.texture:SetAllPoints()
f.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
f.text:SetPoint("BOTTOM", f, "TOP", 0, 2)

local stanceSpells = {
    [2457]  = "warrior",
    [2458]  = "warrior",
    [71]    = "warrior",
    [48266] = "dk",
    [48263] = "dk",
    [48265] = "dk",
}

local stanceNames, stanceIcons = {}, {}
for id in pairs(stanceSpells) do
    local name, _, icon = GetSpellInfo(id)
    stanceNames[id] = name
    stanceIcons[id] = icon
end

local stanceGUIDs = {}

local function ScanBuffs(unit)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
        if not name then return nil end
        if spellId and stanceSpells[spellId] then return spellId end
    end
end

local function ShowStance(stanceId)
    f.texture:SetTexture(stanceIcons[stanceId])
    f.text:SetText(stanceNames[stanceId])
    if db.showText then f.text:Show() else f.text:Hide() end
    f:Show()
end

local function UpdateStanceDisplay()

    if not db.locked then ShowStance(2457) return end

    local unit = "target"
    if not UnitExists(unit) then f:Hide() return end

    local guid = UnitGUID(unit)
    local fromBuff = ScanBuffs(unit)
    if fromBuff then stanceGUIDs[guid] = fromBuff end

    local stanceId = stanceGUIDs[guid]
    if not stanceId or not db[stanceSpells[stanceId]] then f:Hide() return end

    ShowStance(stanceId)
end

local function ApplyLayout()
    f:SetScale(db.scale)
    f:ClearAllPoints()
    f:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    f:EnableMouse(not db.locked)
end

f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function(self)
    if not db.locked then self:StartMoving() end
end)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    db.point, db.x, db.y = point, x, y
end)

local menu = CreateFrame("Frame", "TargetStanceMenu", UIParent)
menu:SetSize(220, 250)
menu:SetPoint("CENTER")
menu:SetFrameStrata("DIALOG")
menu:SetMovable(true)
menu:EnableMouse(true)
menu:RegisterForDrag("LeftButton")
menu:SetScript("OnDragStart", menu.StartMoving)
menu:SetScript("OnDragStop", menu.StopMovingOrSizing)
menu:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
})
menu:Hide()

local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -18)
title:SetText("TargetStance")

local close = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local checks = {}
local function Check(key, label, y)
    local name = "TargetStanceMenuCheck_" .. key
    local cb = CreateFrame("CheckButton", name, menu, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 18, y)
    _G[name .. "Text"]:SetText(label)
    cb:SetScript("OnClick", function(self)
        db[key] = self:GetChecked() and true or false
        ApplyLayout()
        UpdateStanceDisplay()
    end)
    checks[key] = cb
end

Check("warrior",  "Warrior stances",  -40)
Check("dk",       "DK presences",     -66)
Check("showText", "Show name",        -92)
Check("locked",   "Lock position",    -118)

local slider = CreateFrame("Slider", "TargetStanceMenuScale", menu, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", 24, -168)
slider:SetWidth(172)
slider:SetMinMaxValues(0.5, 2)
slider:SetValueStep(0.05)
TargetStanceMenuScaleLow:SetText("0.5")
TargetStanceMenuScaleHigh:SetText("2")
slider:SetScript("OnValueChanged", function(self, v)
    v = math.floor(v * 20 + 0.5) / 20
    db.scale = v
    TargetStanceMenuScaleText:SetText(string.format("Scale: %.2f", v))
    f:SetScale(v)
end)

local reset = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
reset:SetSize(120, 22)
reset:SetPoint("BOTTOM", 0, 20)
reset:SetText("Reset position")
reset:SetScript("OnClick", function()
    db.point, db.x, db.y, db.scale = DEFAULTS.point, DEFAULTS.x, DEFAULTS.y, DEFAULTS.scale
    slider:SetValue(db.scale)
    ApplyLayout()
end)

menu:SetScript("OnShow", function()
    for key, cb in pairs(checks) do cb:SetChecked(db[key]) end
    slider:SetValue(db.scale)
end)

SLASH_TARGETSTANCE1 = "/ts"
SLASH_TARGETSTANCE2 = "/targetstance"
SlashCmdList["TARGETSTANCE"] = function()
    if menu:IsShown() then menu:Hide() else menu:Show() end
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, sourceGUID, _, _, _, _, _, spellId = ...
        if subEvent == "SPELL_CAST_SUCCESS" and stanceSpells[spellId] then
            stanceGUIDs[sourceGUID] = spellId
            if UnitGUID("target") == sourceGUID then
                UpdateStanceDisplay()
            end
        end
    elseif event == "UNIT_AURA" then
        if ... == "target" then UpdateStanceDisplay() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateStanceDisplay()
    elseif event == "ADDON_LOADED" and ... == ADDON then
        if type(TargetStanceDB) ~= "table" then TargetStanceDB = {} end
        for k, v in pairs(DEFAULTS) do
            if TargetStanceDB[k] == nil then TargetStanceDB[k] = v end
        end
        db = TargetStanceDB
        ApplyLayout()
        UpdateStanceDisplay()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_AURA")
