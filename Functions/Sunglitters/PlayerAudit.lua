local TEXTURE_PATH = 'Interface\\AddOns\\' .. addonName .. '\\Textures\\Sunglitters'
local AUDIT_TEXTURE = TEXTURE_PATH .. '\\sunglitters-audit-1.png'
local AUDIT_TEXTURE_HIGHLIGHT = TEXTURE_PATH .. '\\sunglitters-audit-2.png'
local PORTRAIT_MASK = 'Interface\\CHARACTERFRAME\\TempPortraitAlphaMask'
local BORDER_TEXTURE = 'Interface\\Minimap\\MiniMap-TrackingBorder'

-- MiniMap-TrackingBorder inner hole matches ~20px icon at 53px border.
local ICON_SIZE = 20
local BORDER_SIZE = 53
local BUTTON_SIZE = 36
local ICON_INSET = (BUTTON_SIZE - ICON_SIZE) / 2
local BORDER_OUTSET = (BORDER_SIZE - BUTTON_SIZE) / 2
local BORDER_OFFSET_X = 20
local BORDER_OFFSET_Y = 20
local ICON_OFFSET_X = 10
local ICON_OFFSET_Y = 30
local INSPECT_ANCHOR_X = 50
local INSPECT_ANCHOR_Y = 80

local ICON_POS_X = BORDER_OUTSET + ICON_INSET + ICON_OFFSET_X - BORDER_OFFSET_X
local ICON_POS_Y = -(BORDER_OUTSET + ICON_INSET) + ICON_OFFSET_Y - BORDER_OFFSET_Y

local auditButton
local isInitialized = false

local function shouldShowAuditButton()
  if not FreshSoD_IsDeathTaxGuild() then
    return false
  end

  if not FreshSoD_AmIOfficerGuildRank() then
    return false
  end

  if not InspectFrame or not InspectFrame:IsShown() then
    return false
  end

  local unit = InspectFrame.unit
  if not unit or not UnitIsPlayer(unit) then
    return false
  end

  if UnitIsUnit(unit, 'player') then
    return false
  end

  if not FreshSoD_IsUnitInDeathTaxGuild(unit) then
    return false
  end

  return true
end

local function updateAuditButtonVisibility()
  if not auditButton then
    return
  end

  if shouldShowAuditButton() then
    auditButton:Show()
  else
    auditButton:Hide()
  end
end

local function createAuditButton()
  if auditButton or not InspectPaperDollFrame or not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    return
  end

  local inspectParent = InspectPaperDollFrame or InspectFrame

  auditButton = CreateFrame('Button', 'FreshSoDAuditButton', inspectParent)
  auditButton:SetSize(BORDER_SIZE, BORDER_SIZE)
  auditButton:SetPoint('TOPRIGHT', inspectParent, 'TOPRIGHT', -INSPECT_ANCHOR_X, -INSPECT_ANCHOR_Y)
  auditButton:SetFrameLevel(inspectParent:GetFrameLevel() + 20)
  auditButton:EnableMouse(true)

  local icon = auditButton:CreateTexture(nil, 'ARTWORK')
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint('TOPLEFT', auditButton, 'TOPLEFT', ICON_POS_X, ICON_POS_Y)
  icon:SetTexture(AUDIT_TEXTURE)
  auditButton.icon = icon

  local mask = auditButton:CreateMaskTexture()
  mask:SetTexture(PORTRAIT_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
  mask:SetAllPoints(icon)
  icon:AddMaskTexture(mask)

  local border = auditButton:CreateTexture(nil, 'OVERLAY')
  border:SetSize(BORDER_SIZE, BORDER_SIZE)
  border:SetPoint('TOPLEFT', auditButton, 'TOPLEFT', 0, 0)
  border:SetTexture(BORDER_TEXTURE)

  auditButton:SetScript('OnClick', function()
    FreshSoD_StartDeathAudit()
  end)

  auditButton:SetScript('OnEnter', function(self)
    self.icon:SetTexture(AUDIT_TEXTURE_HIGHLIGHT)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText('Audit')
    GameTooltip:Show()
  end)

  auditButton:SetScript('OnLeave', function(self)
    self.icon:SetTexture(AUDIT_TEXTURE)
    GameTooltip:Hide()
  end)

  auditButton:Hide()
end

local function ensureAuditButton()
  if not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    if auditButton then
      auditButton:Hide()
    end
    return
  end

  createAuditButton()
  updateAuditButtonVisibility()
end

local function initializeInspectAudit()
  if isInitialized or not InspectPaperDollFrame then
    return
  end

  isInitialized = true
  ensureAuditButton()

  InspectPaperDollFrame:HookScript('OnShow', updateAuditButtonVisibility)
  InspectPaperDollFrame:HookScript('OnHide', function()
    if auditButton then
      auditButton:Hide()
    end
  end)

  if InspectFrame then
    InspectFrame:HookScript('OnShow', updateAuditButtonVisibility)
    InspectFrame:HookScript('OnHide', function()
      if auditButton then
        auditButton:Hide()
      end
    end)
  end

  updateAuditButtonVisibility()
end

local auditFrame = CreateFrame('Frame')
auditFrame:RegisterEvent('ADDON_LOADED')
auditFrame:RegisterEvent('GUILD_ROSTER_UPDATE')
auditFrame:RegisterEvent('PLAYER_GUILD_UPDATE')

auditFrame:SetScript('OnEvent', function(_, event, loadedAddon)
  if event == 'ADDON_LOADED' then
    if loadedAddon == 'Blizzard_InspectUI' then
      initializeInspectAudit()
    end
    return
  end

  if event == 'GUILD_ROSTER_UPDATE' or event == 'PLAYER_GUILD_UPDATE' then
    ensureAuditButton()
  end
end)

if InspectPaperDollFrame then
  initializeInspectAudit()
end

hooksecurefunc('InspectUnit', function()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      initializeInspectAudit()
      ensureAuditButton()
    end)
  else
    initializeInspectAudit()
    ensureAuditButton()
  end
end)
