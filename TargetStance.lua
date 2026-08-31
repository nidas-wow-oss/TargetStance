local f = CreateFrame("Frame", "TargetStanceFrame", UIParent)
f:SetSize(40, 40)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
f:Hide()

f.texture = f:CreateTexture(nil, "BACKGROUND")
f.texture:SetAllPoints()
f.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
f.text:SetPoint("BOTTOM", f, "TOP", 0, 2)

local stanceSpells = {
    [2457] = "Battle Stance",
    [2458] = "Berserker Stance",
    [71]   = "Defensive Stance",
}

local stanceIcons = {}
for id, _ in pairs(stanceSpells) do
    local _, _, icon = GetSpellInfo(id)
    stanceIcons[id] = icon
end

local stanceGUIDs = {}

local function UpdateStanceDisplay()
    local unit = "target"
    if not UnitExists(unit) then f:Hide() return end

    local guid = UnitGUID(unit)
    local stanceId = stanceGUIDs[guid]
    if not stanceId then f:Hide() return end

    f.texture:SetTexture(stanceIcons[stanceId])
    f.text:SetText(stanceSpells[stanceId])
    f:Show()
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, sourceGUID, _, _, destGUID, _, _, spellId = ...
        if subEvent == "SPELL_CAST_SUCCESS" and stanceSpells[spellId] then
            stanceGUIDs[sourceGUID] = spellId
            if UnitGUID("target") == sourceGUID then
                UpdateStanceDisplay()
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateStanceDisplay()
    end
end)

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
