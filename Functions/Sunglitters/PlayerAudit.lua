local AUDIT_ICON = 'Interface\\Icons\\INV_Misc_Book_06'
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
local INSPECT_ANCHOR_X = 35
local INSPECT_ANCHOR_Y = 68
local CLEAR_DEBT_ANCHOR_X = 35
local CLEAR_DEBT_ANCHOR_Y = 20
local CLEAR_DEBT_ICON = 'Interface\\Icons\\INV_Misc_Coin_16'
local CLEAR_DEBT_ICON_HIGHLIGHT = { 1, 0.9, 0.45 }

local ICON_POS_X = BORDER_OUTSET + ICON_INSET + ICON_OFFSET_X - BORDER_OFFSET_X
local ICON_POS_Y = -(BORDER_OUTSET + ICON_INSET) + ICON_OFFSET_Y - BORDER_OFFSET_Y

local auditButton
local clearDebtButton
local isInitialized = false

local function shouldShowInspectDeathTaxButtons()
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

local function updateInspectDeathTaxButtonVisibility()
  if not auditButton and not clearDebtButton then
    return
  end

  if shouldShowInspectDeathTaxButtons() then
    if auditButton then
      auditButton:Show()
    end
    if clearDebtButton then
      clearDebtButton:Show()
    end
  else
    if auditButton then
      auditButton:Hide()
    end
    if clearDebtButton then
      clearDebtButton:Hide()
    end
  end
end

local function createCircularInspectButton(parent, iconTexture, tooltipText, onClick)
  local button = CreateFrame('Button', nil, parent)
  button:SetSize(BORDER_SIZE, BORDER_SIZE)
  button:SetFrameLevel(parent:GetFrameLevel() + 20)
  button:EnableMouse(true)

  local icon = button:CreateTexture(nil, 'ARTWORK')
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint('TOPLEFT', button, 'TOPLEFT', ICON_POS_X, ICON_POS_Y)
  icon:SetTexture(iconTexture)
  button.icon = icon

  local mask = button:CreateMaskTexture()
  mask:SetTexture(PORTRAIT_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
  mask:SetAllPoints(icon)
  icon:AddMaskTexture(mask)

  local border = button:CreateTexture(nil, 'OVERLAY')
  border:SetSize(BORDER_SIZE, BORDER_SIZE)
  border:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
  border:SetTexture(BORDER_TEXTURE)

  button:SetScript('OnClick', onClick)

  button:SetScript('OnEnter', function(self)
    if self.iconHighlightColor then
      self.icon:SetVertexColor(
        self.iconHighlightColor[1],
        self.iconHighlightColor[2],
        self.iconHighlightColor[3]
      )
    end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText(tooltipText)
    GameTooltip:Show()
  end)

  button:SetScript('OnLeave', function(self)
    self.icon:SetVertexColor(1, 1, 1)
    GameTooltip:Hide()
  end)

  button:Hide()
  return button
end

local function getInspectTargetName()
  if not InspectFrame or not InspectFrame.unit then
    return nil
  end

  return GetUnitName(InspectFrame.unit, true)
end

local function createClearDebtButton(inspectParent)
  if clearDebtButton then
    return
  end

  clearDebtButton = createCircularInspectButton(inspectParent, CLEAR_DEBT_ICON, 'Clear debt', function()
    local targetName = getInspectTargetName()
    if targetName then
      FreshSoD_SendDeathTaxClearDebt(targetName)
    end
  end)
  clearDebtButton.iconHighlightColor = CLEAR_DEBT_ICON_HIGHLIGHT
  clearDebtButton:SetPoint('BOTTOMRIGHT', inspectParent, 'BOTTOMRIGHT', -CLEAR_DEBT_ANCHOR_X, CLEAR_DEBT_ANCHOR_Y)
end

local function createAuditButton()
  if auditButton or not InspectPaperDollFrame or not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    return
  end

  local inspectParent = InspectPaperDollFrame or InspectFrame

  auditButton = createCircularInspectButton(inspectParent, AUDIT_ICON, 'Audit', function()
    FreshSoD_StartDeathAudit()
  end)
  auditButton:SetPoint('TOPRIGHT', inspectParent, 'TOPRIGHT', -INSPECT_ANCHOR_X, -INSPECT_ANCHOR_Y)

  createClearDebtButton(inspectParent)
end

local function ensureInspectDeathTaxButtons()
  if not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    if auditButton then
      auditButton:Hide()
    end
    if clearDebtButton then
      clearDebtButton:Hide()
    end
    return
  end

  createAuditButton()
  updateInspectDeathTaxButtonVisibility()
end

local function initializeInspectAudit()
  if isInitialized or not InspectPaperDollFrame then
    return
  end

  isInitialized = true
  ensureInspectDeathTaxButtons()

  InspectPaperDollFrame:HookScript('OnShow', updateInspectDeathTaxButtonVisibility)
  InspectPaperDollFrame:HookScript('OnHide', function()
    if auditButton then
      auditButton:Hide()
    end
    if clearDebtButton then
      clearDebtButton:Hide()
    end
  end)

  if InspectFrame then
    InspectFrame:HookScript('OnShow', updateInspectDeathTaxButtonVisibility)
    InspectFrame:HookScript('OnHide', function()
      if auditButton then
        auditButton:Hide()
      end
      if clearDebtButton then
        clearDebtButton:Hide()
      end
    end)
  end

  updateInspectDeathTaxButtonVisibility()
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
    ensureInspectDeathTaxButtons()
  end
end)

if InspectPaperDollFrame then
  initializeInspectAudit()
end

hooksecurefunc('InspectUnit', function()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      initializeInspectAudit()
      ensureInspectDeathTaxButtons()
    end)
  else
    initializeInspectAudit()
    ensureInspectDeathTaxButtons()
  end
end)
