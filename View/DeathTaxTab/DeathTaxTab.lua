local CONTENT_HORIZONTAL_MARGIN = 10
local CONTENT_BOTTOM_MARGIN = 10
local TAB_CONTENT_TOP_OFFSET = -50
local CONTENT_DROP = 50
local CONTENT_TOP_OFFSET = TAB_CONTENT_TOP_OFFSET - CONTENT_DROP
local CHECKBOX_TOP_OFFSET = -4
local LEADERBOARD_GAP = 10
local TITLE_LIST_GAP = 8
local LIST_LEFT_OFFSET = 8
local ROW_HEIGHT = 16
local MAX_ROWS = 10

local RANK_COLOR = { 0.78, 0.48, 0.12 }
local NAME_COLOR = { 0.92, 0.87, 0.76 }
local AMOUNT_COLOR = { 1, 0.82, 0 }

local deathTaxPanel
local deathTaxPanelVisible = false

local updateDeathTaxPanelDisplay

local function setTextColor(fontString, color)
  fontString:SetTextColor(color[1], color[2], color[3])
end

local function ensureRow(content, index)
  if content.rows[index] then
    return content.rows[index]
  end

  local row = {}
  local parent = content.listFrame

  row.rankText = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.rankText:SetPoint('TOPLEFT', parent, 'TOPLEFT', 4, -((index - 1) * ROW_HEIGHT))
  row.rankText:SetWidth(24)
  row.rankText:SetJustifyH('LEFT')

  row.nameText = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.nameText:SetPoint('TOPLEFT', row.rankText, 'TOPRIGHT', 4, 0)
  row.nameText:SetWidth(120)
  row.nameText:SetJustifyH('LEFT')
  setTextColor(row.nameText, NAME_COLOR)

  row.amountText = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.amountText:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -4, -((index - 1) * ROW_HEIGHT))
  row.amountText:SetWidth(90)
  row.amountText:SetJustifyH('RIGHT')
  setTextColor(row.amountText, AMOUNT_COLOR)

  content.rows[index] = row
  return row
end

updateDeathTaxPanelDisplay = function()
  if not deathTaxPanel or not deathTaxPanel.initialized then
    return
  end

  if deathTaxPanel.muteCheckbox then
    deathTaxPanel.muteCheckbox:SetChecked(FreshSoD_AreDeathTaxSoundsMuted())
  end

  if deathTaxPanel.notificationsCheckbox then
    deathTaxPanel.notificationsCheckbox:SetChecked(FreshSoD_AreDeathTaxNotificationsDisabled())
  end

  local entries = FreshSoD_GetDeathTaxLeaderboardSorted()

  for index = 1, MAX_ROWS do
    local row = ensureRow(deathTaxPanel, index)
    local entry = entries[index]

    if entry then
      row.rankText:SetText(index .. '.')
      setTextColor(row.rankText, RANK_COLOR)
      row.nameText:SetText(entry.playerName or 'Unknown')
      row.amountText:SetText(FreshSoD_FormatDeathTaxAmount(entry.totalCopper or 0))
      row.rankText:Show()
      row.nameText:Show()
      row.amountText:Show()
    else
      row.rankText:Hide()
      row.nameText:Hide()
      row.amountText:Hide()
    end
  end

  if #entries == 0 then
    deathTaxPanel.emptyLabel:Show()
  else
    deathTaxPanel.emptyLabel:Hide()
  end
end

_G.FreshSoD_RefreshDeathTaxPanel = updateDeathTaxPanelDisplay
_G.FreshSoD_RefreshDeathTaxTab = updateDeathTaxPanelDisplay

local function buildDeathTaxPanel(settingsFrame)
  if deathTaxPanel then
    return deathTaxPanel
  end

  local frameWidth = settingsFrame:GetWidth()
  local frameHeight = settingsFrame:GetHeight()
  local contentWidth = frameWidth - (CONTENT_HORIZONTAL_MARGIN * 2)
  local contentHeight = frameHeight - math.abs(TAB_CONTENT_TOP_OFFSET) - CONTENT_BOTTOM_MARGIN

  deathTaxPanel = CreateFrame('Frame', 'FreshSoDDeathTaxPanel', settingsFrame)
  deathTaxPanel:SetSize(contentWidth, contentHeight)
  deathTaxPanel:SetPoint('TOP', settingsFrame, 'TOP', 0, CONTENT_TOP_OFFSET)
  deathTaxPanel:Hide()
  deathTaxPanel.rows = {}

  local muteCheckbox = CreateFrame('CheckButton', nil, deathTaxPanel, 'UICheckButtonTemplate')
  muteCheckbox:SetSize(24, 24)
  muteCheckbox:SetPoint('TOPLEFT', deathTaxPanel, 'TOPLEFT', 8, CHECKBOX_TOP_OFFSET)
  muteCheckbox:SetChecked(FreshSoD_AreDeathTaxSoundsMuted())
  muteCheckbox:SetScript('OnClick', function(self)
    FreshSoD_SetDeathTaxSoundsMuted(self:GetChecked())
  end)
  deathTaxPanel.muteCheckbox = muteCheckbox

  local muteLabel = deathTaxPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  muteLabel:SetPoint('LEFT', muteCheckbox, 'RIGHT', 2, 0)
  muteLabel:SetText('Mute death tax sounds')
  muteLabel:SetTextColor(NAME_COLOR[1], NAME_COLOR[2], NAME_COLOR[3])

  local notificationsCheckbox = CreateFrame('CheckButton', nil, deathTaxPanel, 'UICheckButtonTemplate')
  notificationsCheckbox:SetSize(24, 24)
  notificationsCheckbox:SetPoint('TOPLEFT', muteCheckbox, 'BOTTOMLEFT', 0, -2)
  notificationsCheckbox:SetChecked(FreshSoD_AreDeathTaxNotificationsDisabled())
  notificationsCheckbox:SetScript('OnClick', function(self)
    FreshSoD_SetDeathTaxNotificationsDisabled(self:GetChecked())
  end)
  deathTaxPanel.notificationsCheckbox = notificationsCheckbox

  local notificationsLabel = deathTaxPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  notificationsLabel:SetPoint('LEFT', notificationsCheckbox, 'RIGHT', 2, 0)
  notificationsLabel:SetText('Disable death tax notifications')
  notificationsLabel:SetTextColor(NAME_COLOR[1], NAME_COLOR[2], NAME_COLOR[3])

  local leaderboardTitle = deathTaxPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  leaderboardTitle:SetPoint('TOPLEFT', notificationsCheckbox, 'BOTTOMLEFT', 0, -LEADERBOARD_GAP)
  leaderboardTitle:SetText('Debt Leaderboard')
  setTextColor(leaderboardTitle, RANK_COLOR)

  deathTaxPanel.listFrame = CreateFrame('Frame', nil, deathTaxPanel)
  deathTaxPanel.listFrame:SetPoint('TOPLEFT', leaderboardTitle, 'BOTTOMLEFT', LIST_LEFT_OFFSET - 8, -TITLE_LIST_GAP)
  deathTaxPanel.listFrame:SetPoint('BOTTOMRIGHT', deathTaxPanel, 'BOTTOMRIGHT', -LIST_LEFT_OFFSET, 12)

  deathTaxPanel.emptyLabel = deathTaxPanel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  deathTaxPanel.emptyLabel:SetPoint('CENTER', deathTaxPanel.listFrame, 'CENTER', 0, 0)
  deathTaxPanel.emptyLabel:SetText('No debt recorded yet.')
  deathTaxPanel.emptyLabel:SetTextColor(0.7, 0.7, 0.7)

  deathTaxPanel.initialized = true
  updateDeathTaxPanelDisplay()

  return deathTaxPanel
end

function FreshSoD_InitializeDeathTaxPanel(settingsFrame)
  buildDeathTaxPanel(settingsFrame)
end

function FreshSoD_IsDeathTaxPanelShown()
  return deathTaxPanelVisible
end

function FreshSoD_HideDeathTaxPanel(skipRestore)
  if not deathTaxPanelVisible then
    return
  end

  deathTaxPanelVisible = false

  if deathTaxPanel then
    deathTaxPanel:Hide()
  end

  if not skipRestore and FreshSoD_GetActiveTab and FreshSoD_SwitchToTab then
    FreshSoD_SwitchToTab(FreshSoD_GetActiveTab() or 1, true)
  end
end

function FreshSoD_ShowDeathTaxPanel()
  local settingsFrame = _G.FreshSoDSettingsFrame
  if not settingsFrame or not FreshSoD_IsDeathTaxGuild() then
    return
  end

  FreshSoD_InitializeDeathTaxPanel(settingsFrame)

  if FreshSoD_HideAllTabs then
    FreshSoD_HideAllTabs()
  end

  deathTaxPanelVisible = true
  deathTaxPanel:Show()
  updateDeathTaxPanelDisplay()
end

function FreshSoD_ToggleDeathTaxPanel()
  if deathTaxPanelVisible then
    FreshSoD_HideDeathTaxPanel()
    return
  end

  local settingsFrame = _G.FreshSoDSettingsFrame
  if not settingsFrame then
    return
  end

  if not settingsFrame:IsShown() then
    if FreshSoD_InitializeTabs then
      FreshSoD_InitializeTabs(settingsFrame)
    end
    settingsFrame:Show()
  end

  FreshSoD_ShowDeathTaxPanel()
end
