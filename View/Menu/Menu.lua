-- Settings frame and toggle - same patterns as UltraHardcore
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

_G.FreshSoD_MenuTitleBar = titleBar

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

local SUNGLITTERS_TEXTURE_PATH = 'Interface\\AddOns\\FreshSoD\\Textures\\Sunglitters'
local AUDIT_TEXTURE = SUNGLITTERS_TEXTURE_PATH .. '\\sunglitters-audit-1.png'
local AUDIT_TEXTURE_HIGHLIGHT = SUNGLITTERS_TEXTURE_PATH .. '\\sunglitters-audit-2.png'
local PORTRAIT_MASK = 'Interface\\CHARACTERFRAME\\TempPortraitAlphaMask'
local BORDER_TEXTURE = 'Interface\\Minimap\\MiniMap-TrackingBorder'

local ICON_SIZE = 20
local BORDER_SIZE = 53
local BUTTON_SIZE = 36
local ICON_INSET = (BUTTON_SIZE - ICON_SIZE) / 2
local BORDER_OUTSET = (BORDER_SIZE - BUTTON_SIZE) / 2
local BORDER_OFFSET_X = 20
local BORDER_OFFSET_Y = 20
local ICON_OFFSET_X = 10
local ICON_OFFSET_Y = 30
local ICON_POS_X = BORDER_OUTSET + ICON_INSET + ICON_OFFSET_X - BORDER_OFFSET_X
local ICON_POS_Y = -(BORDER_OUTSET + ICON_INSET) + ICON_OFFSET_Y - BORDER_OFFSET_Y

local deathTaxHeaderButton = CreateFrame('Button', nil, titleBar)
deathTaxHeaderButton:SetSize(BORDER_SIZE, BORDER_SIZE)
deathTaxHeaderButton:SetPoint('LEFT', titleBar, 'LEFT', 6, -8)
deathTaxHeaderButton:Hide()

local deathTaxHeaderIcon = deathTaxHeaderButton:CreateTexture(nil, 'ARTWORK')
deathTaxHeaderIcon:SetSize(ICON_SIZE, ICON_SIZE)
deathTaxHeaderIcon:SetPoint('TOPLEFT', deathTaxHeaderButton, 'TOPLEFT', ICON_POS_X, ICON_POS_Y)
deathTaxHeaderIcon:SetTexture(AUDIT_TEXTURE)
deathTaxHeaderButton.icon = deathTaxHeaderIcon

local deathTaxHeaderMask = deathTaxHeaderButton:CreateMaskTexture()
deathTaxHeaderMask:SetTexture(PORTRAIT_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
deathTaxHeaderMask:SetAllPoints(deathTaxHeaderIcon)
deathTaxHeaderIcon:AddMaskTexture(deathTaxHeaderMask)

local deathTaxHeaderBorder = deathTaxHeaderButton:CreateTexture(nil, 'OVERLAY')
deathTaxHeaderBorder:SetSize(BORDER_SIZE, BORDER_SIZE)
deathTaxHeaderBorder:SetPoint('TOPLEFT', deathTaxHeaderButton, 'TOPLEFT', 0, 0)
deathTaxHeaderBorder:SetTexture(BORDER_TEXTURE)

local function updateDeathTaxHeaderButton()
  if not FreshSoD_IsDeathTaxGuild or not FreshSoD_IsDeathTaxGuild() then
    deathTaxHeaderButton:Hide()
    return
  end

  deathTaxHeaderButton:Show()
end

deathTaxHeaderButton:SetScript('OnEnter', function(self)
  self.icon:SetTexture(AUDIT_TEXTURE_HIGHLIGHT)
  GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
  GameTooltip:SetText('Death Tax', nil, nil, nil, nil, true)
  GameTooltip:Show()
end)

deathTaxHeaderButton:SetScript('OnLeave', function(self)
  self.icon:SetTexture(AUDIT_TEXTURE)
  GameTooltip:Hide()
end)

deathTaxHeaderButton:SetScript('OnClick', function()
  if FreshSoD_ToggleDeathTaxPanel then
    FreshSoD_ToggleDeathTaxPanel()
  end
end)

local deathTaxHeaderFrame = CreateFrame('Frame')
deathTaxHeaderFrame:RegisterEvent('GUILD_ROSTER_UPDATE')
deathTaxHeaderFrame:RegisterEvent('PLAYER_GUILD_UPDATE')
deathTaxHeaderFrame:SetScript('OnEvent', updateDeathTaxHeaderButton)

function FreshSoD_OpenDeathTaxTab()
  if FreshSoD_ToggleDeathTaxPanel then
    FreshSoD_ToggleDeathTaxPanel()
  end
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
    updateDeathTaxHeaderButton()
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
  updateDeathTaxHeaderButton()
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
