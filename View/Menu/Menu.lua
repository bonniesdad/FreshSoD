-- Settings frame and the toggle. Nicked the same patterns off UltraHardcore, no point reinventing the wheel big shoutout too the goat Bonniesdad.
local ADDON_NAME = 'FreshSoD'
local TEXTURE_PATH = 'Interface\\AddOns\\FreshSoD\\Textures'

local CLASS_BACKGROUND_MAP = {
  WARRIOR = TEXTURE_PATH .. '\\bg_warrior.png',
  PALADIN = TEXTURE_PATH .. '\\bg_pally.png',
  HUNTER = TEXTURE_PATH .. '\\bg_hunter.png',
  ROGUE = TEXTURE_PATH .. '\\bg_rogue.png',
  PRIEST = TEXTURE_PATH .. '\\bg_priest.png',
  MAGE = TEXTURE_PATH .. '\\bg_mage.png',
  WARLOCK = TEXTURE_PATH .. '\\bg_warlock.png',
  DRUID = TEXTURE_PATH .. '\\bg_druid.png',
  SHAMAN = TEXTURE_PATH .. '\\bg_shaman.png',
}

local TITLE_BAR_HEIGHT = 60
local MENU_BORDER_TEXTURE = 'Interface\\DialogFrame\\UI-DialogBox-Border'
local MENU_BORDER_EDGE_SIZE = 32
local MENU_BORDER_OUTSET = 10
local MENU_BORDER_INSETS = { left = 0, right = 0, top = 0, bottom = 0 }

local function getClassBackgroundTexture()
  local _, classFileName = UnitClass('player')
  if classFileName and CLASS_BACKGROUND_MAP[classFileName] then
    return CLASS_BACKGROUND_MAP[classFileName]
  end
  return 'Interface\\DialogFrame\\UI-DialogBox-Background'
end

local settingsFrame =
  CreateFrame('Frame', 'FreshSoDSettingsFrame', UIParent, 'BackdropTemplate')
tinsert(UISpecialFrames, 'FreshSoDSettingsFrame')
settingsFrame:SetSize(300, 400)
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag('LeftButton')
settingsFrame:SetScript('OnDragStart', function(self)
  self:StartMoving()
end)
settingsFrame:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
end)
settingsFrame:SetScript('OnHide', function(self)
  if _G.HideConfirmationDialog then
    _G.HideConfirmationDialog()
  end
end)
settingsFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 30)

local function ResetFreshSoDMenuPosition()
  settingsFrame:ClearAllPoints()
  settingsFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 30)
  print('|cfff44336[SoD Guild Found]|r Menu position reset to default.')
end

_G.ResetFreshSoDMenuPosition = ResetFreshSoDMenuPosition
settingsFrame:Hide()
settingsFrame:SetFrameStrata('DIALOG')
settingsFrame:SetFrameLevel(15)
settingsFrame:SetClipsChildren(false)

local settingsFrameBackground = settingsFrame:CreateTexture(nil, 'BACKGROUND')
settingsFrameBackground:SetTexCoord(0, 1, 0, 1)

local settingsFrameBorder = CreateFrame('Frame', nil, settingsFrame, 'BackdropTemplate')
settingsFrameBorder:SetFrameLevel(settingsFrame:GetFrameLevel() + 10)
settingsFrameBorder:EnableMouse(false)

local function updateSettingsFrameBorderLayout()
  settingsFrameBorder:ClearAllPoints()
  settingsFrameBorder:SetPoint(
    'TOPLEFT',
    settingsFrame,
    'TOPLEFT',
    -MENU_BORDER_OUTSET,
    MENU_BORDER_OUTSET
  )
  settingsFrameBorder:SetPoint(
    'BOTTOMRIGHT',
    settingsFrame,
    'BOTTOMRIGHT',
    MENU_BORDER_OUTSET,
    -MENU_BORDER_OUTSET
  )
end
updateSettingsFrameBorderLayout()

local titleBar = CreateFrame('Frame', nil, settingsFrame, 'BackdropTemplate')
titleBar:SetSize(settingsFrame:GetWidth(), TITLE_BAR_HEIGHT)
titleBar:SetPoint('TOP', settingsFrame, 'TOP')
titleBar:SetFrameStrata('DIALOG')
titleBar:SetFrameLevel(20)
titleBar:SetBackdropBorderColor(0, 0, 0, 1)
titleBar:SetBackdropColor(0, 0, 0, 0.95)
local titleBarBackground = titleBar:CreateTexture(nil, 'BACKGROUND')
titleBarBackground:SetAllPoints()
titleBarBackground:SetTexture(TEXTURE_PATH .. '\\header.png')
titleBarBackground:SetTexCoord(0, 1, 0, 1)
local settingsTitleLabel = titleBar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightHuge')
settingsTitleLabel:SetPoint('CENTER', titleBar, 'CENTER', 0, 4)
settingsTitleLabel:SetText('SoD Guild Found')
settingsTitleLabel:SetTextColor(0.922, 0.871, 0.761)

local dividerFrame = CreateFrame('Frame', nil, settingsFrame)
dividerFrame:SetSize(settingsFrame:GetWidth() + 10, 24)
dividerFrame:SetPoint('BOTTOM', titleBar, 'BOTTOM', 0, -10)
dividerFrame:SetFrameStrata('DIALOG')
dividerFrame:SetFrameLevel(20)
local dividerTexture = dividerFrame:CreateTexture(nil, 'ARTWORK')
dividerTexture:SetAllPoints()
dividerTexture:SetTexture(TEXTURE_PATH .. '\\divider.png')
dividerTexture:SetTexCoord(0, 1, 0, 1)

local function updateSettingsFrameBackdrop()
  settingsFrameBackground:SetTexture(getClassBackgroundTexture())
  settingsFrameBackground:ClearAllPoints()
  settingsFrameBackground:SetPoint('TOPLEFT', titleBar, 'BOTTOMLEFT', 0, 0)
  settingsFrameBackground:SetPoint('BOTTOMRIGHT', settingsFrame, 'BOTTOMRIGHT', 0, 0)
  updateSettingsFrameBorderLayout()
  settingsFrame:SetBackdrop(nil)
  settingsFrameBorder:SetBackdrop({
    bgFile = nil,
    edgeFile = MENU_BORDER_TEXTURE,
    tile = true,
    tileSize = MENU_BORDER_EDGE_SIZE,
    edgeSize = MENU_BORDER_EDGE_SIZE,
    insets = MENU_BORDER_INSETS,
  })
  settingsFrameBorder:SetBackdropBorderColor(1, 1, 1, 1)
end
updateSettingsFrameBackdrop()

local closeButton = CreateFrame('Button', nil, titleBar, 'UIPanelCloseButton')
closeButton:SetPoint('RIGHT', titleBar, 'RIGHT', -15, 4)
closeButton:SetSize(12, 12)
closeButton:SetScript('OnClick', function()
  if FreshSoD_ResetTabState then
    FreshSoD_ResetTabState()
  end
  if _G.HideConfirmationDialog then
    _G.HideConfirmationDialog()
  end
  settingsFrame:Hide()
end)
closeButton:SetNormalTexture(TEXTURE_PATH .. '\\header-x.png')
closeButton:SetPushedTexture(TEXTURE_PATH .. '\\header-x.png')
closeButton:SetHighlightTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight', 'ADD')
local closeButtonTex = closeButton:GetNormalTexture()
if closeButtonTex then
  closeButtonTex:SetTexCoord(0, 1, 0, 1)
end
local closeButtonPushed = closeButton:GetPushedTexture()
if closeButtonPushed then
  closeButtonPushed:SetTexCoord(0, 1, 0, 1)
end

function FreshSoD_ToggleFreshSoDSettings()
  if settingsFrame:IsShown() then
    if FreshSoD_ResetTabState then
      FreshSoD_ResetTabState()
    end
    if _G.HideConfirmationDialog then
      _G.HideConfirmationDialog()
    end
    settingsFrame:Hide()
  else
    updateSettingsFrameBackdrop()
    if FreshSoD_InitializeTabs then
      FreshSoD_InitializeTabs(settingsFrame)
    end
    if FreshSoD_HideAllTabs and FreshSoD_SetDefaultTab then
      FreshSoD_HideAllTabs()
      FreshSoD_SetDefaultTab()
    elseif FreshSoD_SwitchToTab then
      FreshSoD_SwitchToTab(1)
    end
    settingsFrame:Show()
  end
end

function OpenFreshSoDSettingsToTab(tabIndex)
  updateSettingsFrameBackdrop()
  if FreshSoD_InitializeTabs then
    FreshSoD_InitializeTabs(settingsFrame)
  end
  if FreshSoD_HideAllTabs and FreshSoD_SwitchToTab then
    FreshSoD_HideAllTabs()
    FreshSoD_SwitchToTab(tabIndex)
  end
  settingsFrame:Show()
end

SLASH_FRESHSOD1 = '/freshsod'
SLASH_FRESHSOD2 = '/sgf'
SLASH_FRESHSOD3 = '/sodguildfound'
SlashCmdList['FRESHSOD'] = FreshSoD_ToggleFreshSoDSettings
