local warningFrame

local FRAME_WIDTH = 360
local TOP_OFFSET = -50
local HEADER_HEIGHT = 34
local CONTENT_HORIZONTAL_INSET = 14
local CONTENT_TOP_GAP = 6
local CONTENT_BOTTOM_PADDING = 8
local BORDER_TEXTURE = 'Interface\\DialogFrame\\UI-DialogBox-Border'
local BORDER_EDGE_SIZE = 32
local BORDER_OUTSET = 10
local PANEL_BACKGROUND_ALPHA = 0.5
local HEADER_BACKGROUND_ALPHA = 0.55
local BORDER_ALPHA = 0.7
local DIVIDER_ALPHA = 0.55

local TITLE_COLOR = { 0.92, 0.22, 0.18 }
local BORDER_COLOR = { 0.78, 0.48, 0.12 }
local BODY_COLOR = { 0.9, 0.88, 0.84 }
local PHASE_COLOR = { 1, 0.82, 0 }

-- Unlock times: 11:00 Europe/London (BST = UTC+1)
local PHASE_UNLOCK_SERVER_TIME = {
  [5] = 1785405600, -- 30 July 2026 11:00
  [6] = 1786356000, -- 10 August 2026 11:00
}

local PHASE_UNLOCK_DISPLAY_DATE = {
  [5] = '30 July 2026',
  [6] = '10 August 2026',
}

-- Instance map IDs from GetInstanceInfo(); phase when content is allowed.
local PHASE_LOCKED_INSTANCE_MAP_IDS = {
  [2875] = 5, -- Karazhan Crypts
  [509] = 5, -- Ruins of Ahn'Qiraj
  [531] = 5, -- Temple of Ahn'Qiraj
  [533] = 6, -- Naxxramas
  [2856] = 6, -- Scarlet Enclave
}

-- Locale-safe fallback if map ID differs on a client build.
local PHASE_LOCKED_INSTANCE_NAMES = {
  ["Karazhan Crypts"] = 5,
  ["Ruins of Ahn'Qiraj"] = 5,
  ["Ahn'Qiraj Temple"] = 5,
  ["Temple of Ahn'Qiraj"] = 5,
  ["Naxxramas"] = 6,
  ["Scarlet Enclave"] = 6,
}

local function colorCode(color)
  return string.format('|cff%02x%02x%02x', color[1] * 255, color[2] * 255, color[3] * 255)
end

local function getNow()
  if GetServerTime then
    return GetServerTime()
  end
  return time()
end

local function isPhaseUnlocked(phase)
  local unlockAt = PHASE_UNLOCK_SERVER_TIME[phase]
  if not unlockAt then
    return true
  end
  return getNow() >= unlockAt
end

local function getRequiredPhaseForCurrentInstance()
  local inInstance, instanceType = IsInInstance()
  if not inInstance then
    return nil
  end

  if instanceType ~= 'party' and instanceType ~= 'raid' then
    return nil
  end

  local name, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()

  if instanceMapID and PHASE_LOCKED_INSTANCE_MAP_IDS[instanceMapID] then
    return PHASE_LOCKED_INSTANCE_MAP_IDS[instanceMapID]
  end

  if name and PHASE_LOCKED_INSTANCE_NAMES[name] then
    return PHASE_LOCKED_INSTANCE_NAMES[name]
  end

  return nil
end

local function buildWarningMessage(phase)
  local unlockDate = PHASE_UNLOCK_DISPLAY_DATE[phase] or ''
  return string.format(
    '%sYou should not be in this instance until phase %s%d|r%s which begins on %s%s|r%s.|r',
    colorCode(BODY_COLOR),
    colorCode(PHASE_COLOR),
    phase,
    colorCode(BODY_COLOR),
    colorCode(PHASE_COLOR),
    unlockDate,
    colorCode(BODY_COLOR)
  )
end

local function ensureWarningFrame()
  if warningFrame then
    return
  end

  warningFrame = CreateFrame('Frame', 'FreshSoDPhaseLockAnnouncement', UIParent, 'BackdropTemplate')
  warningFrame:SetSize(FRAME_WIDTH, 1)
  warningFrame:SetPoint('TOP', UIParent, 'TOP', 0, TOP_OFFSET)
  warningFrame:SetFrameStrata('HIGH')
  warningFrame:SetFrameLevel(100)
  warningFrame:SetClipsChildren(false)
  warningFrame:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
    tile = true,
    tileSize = 32,
  })
  warningFrame:SetBackdropColor(0.08, 0.03, 0.03, PANEL_BACKGROUND_ALPHA)
  warningFrame:Hide()

  warningFrame.border = CreateFrame('Frame', nil, warningFrame, 'BackdropTemplate')
  warningFrame.border:SetFrameLevel(warningFrame:GetFrameLevel() + 10)
  warningFrame.border:EnableMouse(false)
  warningFrame.border:SetPoint('TOPLEFT', warningFrame, 'TOPLEFT', -BORDER_OUTSET, BORDER_OUTSET)
  warningFrame.border:SetPoint('BOTTOMRIGHT', warningFrame, 'BOTTOMRIGHT', BORDER_OUTSET, -BORDER_OUTSET)
  warningFrame.border:SetBackdrop({
    edgeFile = BORDER_TEXTURE,
    tile = true,
    tileSize = BORDER_EDGE_SIZE,
    edgeSize = BORDER_EDGE_SIZE,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  warningFrame.border:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_ALPHA)

  warningFrame.headerBar = CreateFrame('Frame', nil, warningFrame, 'BackdropTemplate')
  warningFrame.headerBar:SetPoint('TOPLEFT', warningFrame, 'TOPLEFT', 0, 0)
  warningFrame.headerBar:SetPoint('TOPRIGHT', warningFrame, 'TOPRIGHT', 0, 0)
  warningFrame.headerBar:SetHeight(HEADER_HEIGHT)
  warningFrame.headerBar:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    tile = true,
    tileSize = 8,
  })
  warningFrame.headerBar:SetBackdropColor(0.18, 0.05, 0.05, HEADER_BACKGROUND_ALPHA)

  warningFrame.headerTitle = warningFrame.headerBar:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  warningFrame.headerTitle:SetPoint('CENTER', warningFrame.headerBar, 'CENTER', 0, 1)
  warningFrame.headerTitle:SetText('PHASE LOCKED')
  warningFrame.headerTitle:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])

  warningFrame.divider = warningFrame:CreateTexture(nil, 'ARTWORK')
  warningFrame.divider:SetPoint('TOPLEFT', warningFrame.headerBar, 'BOTTOMLEFT', 0, 0)
  warningFrame.divider:SetPoint('TOPRIGHT', warningFrame.headerBar, 'BOTTOMRIGHT', 0, 0)
  warningFrame.divider:SetHeight(1)
  warningFrame.divider:SetColorTexture(0.45, 0.18, 0.12, DIVIDER_ALPHA)

  warningFrame.text = warningFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  warningFrame.text:SetPoint('TOPLEFT', warningFrame.divider, 'BOTTOMLEFT', CONTENT_HORIZONTAL_INSET, -CONTENT_TOP_GAP)
  warningFrame.text:SetPoint('TOPRIGHT', warningFrame.divider, 'BOTTOMRIGHT', -CONTENT_HORIZONTAL_INSET, -CONTENT_TOP_GAP)
  warningFrame.text:SetWidth(FRAME_WIDTH - (CONTENT_HORIZONTAL_INSET * 2))
  warningFrame.text:SetWordWrap(true)
  warningFrame.text:SetJustifyH('CENTER')
  warningFrame.text:SetSpacing(2)
end

local function hidePhaseLockWarning()
  if warningFrame then
    warningFrame:Hide()
  end
end

local function showPhaseLockWarning(phase)
  ensureWarningFrame()

  warningFrame.text:SetText(buildWarningMessage(phase))
  local textHeight = warningFrame.text:GetStringHeight()
  warningFrame:SetHeight(
    HEADER_HEIGHT + 1 + CONTENT_TOP_GAP + textHeight + CONTENT_BOTTOM_PADDING
  )
  warningFrame:SetAlpha(1)
  warningFrame:Show()
end

local function checkPhaseLockWarning()
  -- Phase 6 unlocks all content; never warn afterwards.
  if isPhaseUnlocked(6) then
    hidePhaseLockWarning()
    return
  end

  local requiredPhase = getRequiredPhaseForCurrentInstance()
  if requiredPhase and not isPhaseUnlocked(requiredPhase) then
    showPhaseLockWarning(requiredPhase)
    return
  end

  hidePhaseLockWarning()
end

local phaseLockFrame = CreateFrame('Frame')
phaseLockFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
phaseLockFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
phaseLockFrame:RegisterEvent('ZONE_CHANGED')
phaseLockFrame:RegisterEvent('ZONE_CHANGED_INDOORS')

phaseLockFrame:SetScript('OnEvent', function()
  checkPhaseLockWarning()

  -- GetInstanceInfo can lag briefly after zoning.
  if C_Timer and C_Timer.After then
    C_Timer.After(1, checkPhaseLockWarning)
  end
end)
