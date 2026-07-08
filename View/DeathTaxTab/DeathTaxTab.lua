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
local COLLECTED_SECTION_HEIGHT = 44
local COLLECTED_BUTTON_WIDTH = 52
local COLLECTED_BUTTON_HEIGHT = 18
local COLLECTED_BUTTON_GAP = 4
local COLLECTED_TITLE_GAP = 4
local COLLECTED_ROW_BOTTOM = 34

local TEXTURE_PATH = 'Interface\\AddOns\\FreshSoD\\Textures'
local MODAL_WIDTH = 320
local MODAL_HEIGHT = 180
local MODAL_CONTENT_INSET = 24
local MODAL_BUTTON_WIDTH = 100
local MODAL_BUTTON_HEIGHT = 24
local MODAL_INPUT_WIDTH = 56
local MODAL_INPUT_HEIGHT = 24
local MODAL_INPUT_GAP = 10
local HEADER_HEIGHT = 44
local BORDER_TEXTURE = 'Interface\\DialogFrame\\UI-DialogBox-Border'
local BORDER_EDGE_SIZE = 32
local BORDER_OUTSET = 10

local RANK_COL_WIDTH = 24
local NAME_COL_WIDTH = 90
local GOLD_COL_WIDTH = 64
local SILVER_COL_WIDTH = 38
local COPPER_COL_WIDTH = 38
local MONEY_COL_GAP = 2

local RANK_COLOR = { 0.78, 0.48, 0.12 }
local NAME_COLOR = { 0.92, 0.87, 0.76 }
local AMOUNT_COLOR = { 1, 0.82, 0 }
local SECTION_COLOR = { 0.922, 0.871, 0.761 }
local SUBTITLE_COLOR = { 0.78, 0.72, 0.62 }

local deathTaxPanel
local deathTaxPanelVisible = false
local collectedGoldModal

local updateDeathTaxPanelDisplay
local showCollectedGoldModal
local hideCollectedGoldModal
local hideClearCollectedConfirm

local function canManageTaxCollected()
  return FreshSoD_AmITopGuildRank and FreshSoD_AmITopGuildRank()
end

local CLEAR_COLLECTED_POPUP = 'FRESHSOD_CLEAR_TAX_COLLECTED'

StaticPopupDialogs[CLEAR_COLLECTED_POPUP] = {
  text = 'Clear all tax collected?\n\n%s',
  button1 = 'Clear',
  button2 = 'Cancel',
  OnAccept = function()
    if not canManageTaxCollected() then
      return
    end

    FreshSoD_ClearDeathTaxCollectedCopper()
    if updateDeathTaxPanelDisplay then
      updateDeathTaxPanelDisplay()
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

hideClearCollectedConfirm = function()
  StaticPopup_Hide(CLEAR_COLLECTED_POPUP)
end

local function showClearCollectedConfirm()
  if not canManageTaxCollected() then
    return
  end

  local amountText = FreshSoD_FormatDeathTaxAmount(FreshSoD_GetDeathTaxCollectedCopper())
  StaticPopup_Show(CLEAR_COLLECTED_POPUP, amountText)
end

local function setTextColor(fontString, color)
  fontString:SetTextColor(color[1], color[2], color[3])
end

local function parseMoneyField(editBox)
  local value = tonumber(editBox:GetText())
  if not value or value < 0 then
    return 0
  end
  return math.floor(value)
end

local function goldSilverCopperToCopper(gold, silver, copper)
  return (gold * 10000) + (silver * 100) + copper
end

local function copperToGoldSilverCopper(totalCopper)
  totalCopper = math.max(tonumber(totalCopper) or 0, 0)
  local gold = math.floor(totalCopper / 10000)
  local silver = math.floor((totalCopper % 10000) / 100)
  local copper = totalCopper % 100
  return gold, silver, copper
end

local function formatGoldColumn(gold)
  return string.format(GOLD_AMOUNT_TEXTURE, gold, 0, 0)
end

local function formatSilverColumn(silver)
  return string.format(SILVER_AMOUNT_TEXTURE, silver, 0, 0)
end

local function formatCopperColumn(copper)
  return string.format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
end

local function createMoneyColumn(parent, width, anchorPoint)
  local text = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  text:SetPoint(anchorPoint[1], anchorPoint[2], anchorPoint[3], anchorPoint[4], anchorPoint[5])
  text:SetWidth(width)
  text:SetJustifyH('RIGHT')
  setTextColor(text, AMOUNT_COLOR)
  return text
end

local function ensureRow(content, index)
  if content.rows[index] then
    return content.rows[index]
  end

  local row = {}
  local parent = content.listFrame
  local rowTop = -((index - 1) * ROW_HEIGHT)

  row.rankText = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.rankText:SetPoint('TOPLEFT', parent, 'TOPLEFT', 4, rowTop)
  row.rankText:SetWidth(RANK_COL_WIDTH)
  row.rankText:SetJustifyH('LEFT')

  row.nameText = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.nameText:SetPoint('TOPLEFT', row.rankText, 'TOPRIGHT', 4, 0)
  row.nameText:SetWidth(NAME_COL_WIDTH)
  row.nameText:SetJustifyH('LEFT')
  setTextColor(row.nameText, NAME_COLOR)

  row.copperText = createMoneyColumn(parent, COPPER_COL_WIDTH, {
    'TOPRIGHT', parent, 'TOPRIGHT', -4, rowTop,
  })
  row.silverText = createMoneyColumn(parent, SILVER_COL_WIDTH, {
    'TOPRIGHT', row.copperText, 'TOPLEFT', -MONEY_COL_GAP, 0,
  })
  row.goldText = createMoneyColumn(parent, GOLD_COL_WIDTH, {
    'TOPRIGHT', row.silverText, 'TOPLEFT', -MONEY_COL_GAP, 0,
  })

  content.rows[index] = row
  return row
end

local function updateCollectedRowVisibility()
  if not deathTaxPanel or not deathTaxPanel.collectedRow or not deathTaxPanel.listFrame or not deathTaxPanel.leaderboardTitle then
    return
  end

  local canManage = canManageTaxCollected()

  deathTaxPanel.listFrame:ClearAllPoints()
  deathTaxPanel.listFrame:SetPoint(
    'TOPLEFT',
    deathTaxPanel.leaderboardTitle,
    'BOTTOMLEFT',
    LIST_LEFT_OFFSET - 8,
    -TITLE_LIST_GAP
  )

  if canManage then
    deathTaxPanel.collectedRow:Show()
    deathTaxPanel.listFrame:SetPoint('BOTTOMRIGHT', deathTaxPanel.collectedRow, 'TOPRIGHT', 0, 8)
  else
    deathTaxPanel.collectedRow:Hide()
    deathTaxPanel.listFrame:SetPoint('BOTTOMRIGHT', deathTaxPanel, 'BOTTOMRIGHT', -LIST_LEFT_OFFSET, 12)
    hideCollectedGoldModal()
    hideClearCollectedConfirm()
  end
end

local function updateCollectedDisplay()
  if not deathTaxPanel or not deathTaxPanel.collectedAmountText then
    return
  end

  updateCollectedRowVisibility()

  if not canManageTaxCollected() then
    return
  end

  deathTaxPanel.collectedAmountText:SetText(FreshSoD_FormatDeathTaxAmount(FreshSoD_GetDeathTaxCollectedCopper()))
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
      local gold, silver, copper = copperToGoldSilverCopper(entry.totalCopper or 0)
      row.rankText:SetText(index .. '.')
      setTextColor(row.rankText, RANK_COLOR)
      row.nameText:SetText(entry.playerName or 'Unknown')
      row.goldText:SetText(formatGoldColumn(gold))
      row.silverText:SetText(formatSilverColumn(silver))
      row.copperText:SetText(formatCopperColumn(copper))
      row.rankText:Show()
      row.nameText:Show()
      row.goldText:Show()
      row.silverText:Show()
      row.copperText:Show()
    else
      row.rankText:Hide()
      row.nameText:Hide()
      row.goldText:Hide()
      row.silverText:Hide()
      row.copperText:Hide()
    end
  end

  if #entries == 0 then
    deathTaxPanel.emptyLabel:Show()
  else
    deathTaxPanel.emptyLabel:Hide()
  end

  updateCollectedDisplay()
end

_G.FreshSoD_RefreshDeathTaxPanel = updateDeathTaxPanelDisplay
_G.FreshSoD_RefreshDeathTaxTab = updateDeathTaxPanelDisplay

hideCollectedGoldModal = function()
  if collectedGoldModal then
    collectedGoldModal:Hide()
  end
end

local function clearModalInputs()
  if not collectedGoldModal then
    return
  end

  collectedGoldModal.goldInput:SetText('0')
  collectedGoldModal.silverInput:SetText('0')
  collectedGoldModal.copperInput:SetText('0')
end

local function submitCollectedGoldModal()
  if not collectedGoldModal or not canManageTaxCollected() then
    hideCollectedGoldModal()
    return
  end

  local gold = parseMoneyField(collectedGoldModal.goldInput)
  local silver = parseMoneyField(collectedGoldModal.silverInput)
  local copper = parseMoneyField(collectedGoldModal.copperInput)
  local totalCopper = goldSilverCopperToCopper(gold, silver, copper)

  if totalCopper > 0 then
    FreshSoD_AddDeathTaxCollectedCopper(totalCopper)
    updateCollectedDisplay()
  end

  hideCollectedGoldModal()
end

local function createMoneyInput(parent, labelText)
  local container = CreateFrame('Frame', nil, parent)
  container:SetSize(MODAL_INPUT_WIDTH + 18, MODAL_INPUT_HEIGHT + 16)

  local label = container:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  label:SetPoint('TOP', container, 'TOP', 0, 0)
  label:SetText(labelText)
  setTextColor(label, SUBTITLE_COLOR)

  local input = CreateFrame('EditBox', nil, container, 'InputBoxTemplate')
  input:SetSize(MODAL_INPUT_WIDTH, MODAL_INPUT_HEIGHT)
  input:SetPoint('TOP', label, 'BOTTOM', 0, -2)
  input:SetAutoFocus(false)
  input:SetNumeric(true)
  input:SetMaxLetters(6)
  input:SetText('0')
  input:SetJustifyH('CENTER')

  container.input = input
  return container
end

showCollectedGoldModal = function()
  if not canManageTaxCollected() then
    return
  end

  if not collectedGoldModal then
    collectedGoldModal = CreateFrame('Frame', 'FreshSoDDeathTaxCollectedModal', UIParent, 'BackdropTemplate')
    tinsert(UISpecialFrames, 'FreshSoDDeathTaxCollectedModal')
    collectedGoldModal:SetSize(MODAL_WIDTH, MODAL_HEIGHT)
    collectedGoldModal:SetPoint('CENTER', UIParent, 'CENTER', 0, 80)
    collectedGoldModal:SetFrameStrata('DIALOG')
    collectedGoldModal:SetFrameLevel(100)
    collectedGoldModal:EnableMouse(true)
    collectedGoldModal:SetClipsChildren(false)
    collectedGoldModal:SetBackdrop({
      bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
      tile = true,
      tileSize = 32,
    })
    collectedGoldModal:SetBackdropColor(0.05, 0.05, 0.05, 0.97)

    collectedGoldModal.border = CreateFrame('Frame', nil, collectedGoldModal, 'BackdropTemplate')
    collectedGoldModal.border:SetFrameLevel(collectedGoldModal:GetFrameLevel() + 10)
    collectedGoldModal.border:EnableMouse(false)
    collectedGoldModal.border:SetPoint('TOPLEFT', collectedGoldModal, 'TOPLEFT', -BORDER_OUTSET, BORDER_OUTSET)
    collectedGoldModal.border:SetPoint('BOTTOMRIGHT', collectedGoldModal, 'BOTTOMRIGHT', BORDER_OUTSET, -BORDER_OUTSET)
    collectedGoldModal.border:SetBackdrop({
      edgeFile = BORDER_TEXTURE,
      edgeSize = BORDER_EDGE_SIZE,
      tile = true,
      tileSize = 32,
      insets = { left = 11, right = 11, top = 11, bottom = 11 },
    })
    collectedGoldModal.border:SetBackdropBorderColor(1, 1, 1, 1)

    collectedGoldModal.headerBar = CreateFrame('Frame', nil, collectedGoldModal, 'BackdropTemplate')
    collectedGoldModal.headerBar:SetPoint('TOPLEFT', collectedGoldModal, 'TOPLEFT', 0, 0)
    collectedGoldModal.headerBar:SetPoint('TOPRIGHT', collectedGoldModal, 'TOPRIGHT', 0, 0)
    collectedGoldModal.headerBar:SetHeight(HEADER_HEIGHT)
    collectedGoldModal.headerBar:SetBackdropColor(0, 0, 0, 0.95)

    collectedGoldModal.headerBackground = collectedGoldModal.headerBar:CreateTexture(nil, 'BACKGROUND')
    collectedGoldModal.headerBackground:SetAllPoints()
    collectedGoldModal.headerBackground:SetTexture(TEXTURE_PATH .. '\\header.png')
    collectedGoldModal.headerBackground:SetTexCoord(0, 1, 0, 1)

    collectedGoldModal.headerTitle = collectedGoldModal.headerBar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightHuge')
    collectedGoldModal.headerTitle:SetPoint('CENTER', collectedGoldModal.headerBar, 'CENTER', 0, 0)
    collectedGoldModal.headerTitle:SetText('Add')
    setTextColor(collectedGoldModal.headerTitle, SECTION_COLOR)

    collectedGoldModal.dividerFrame = CreateFrame('Frame', nil, collectedGoldModal)
    collectedGoldModal.dividerFrame:SetSize(MODAL_WIDTH + 10, 16)
    collectedGoldModal.dividerFrame:SetPoint('BOTTOM', collectedGoldModal.headerBar, 'BOTTOM', 0, -8)
    collectedGoldModal.dividerFrame:SetFrameLevel(collectedGoldModal:GetFrameLevel() + 5)

    collectedGoldModal.divider = collectedGoldModal.dividerFrame:CreateTexture(nil, 'ARTWORK')
    collectedGoldModal.divider:SetAllPoints()
    collectedGoldModal.divider:SetTexture(TEXTURE_PATH .. '\\divider.png')
    collectedGoldModal.divider:SetTexCoord(0, 1, 0, 1)

    collectedGoldModal.promptText = collectedGoldModal:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    collectedGoldModal.promptText:SetPoint('TOP', collectedGoldModal.dividerFrame, 'BOTTOM', 0, -12)
    collectedGoldModal.promptText:SetPoint('LEFT', collectedGoldModal, 'LEFT', MODAL_CONTENT_INSET, 0)
    collectedGoldModal.promptText:SetPoint('RIGHT', collectedGoldModal, 'RIGHT', -MODAL_CONTENT_INSET, 0)
    collectedGoldModal.promptText:SetJustifyH('CENTER')
    collectedGoldModal.promptText:SetText('Enter gold, silver, and copper to add')
    setTextColor(collectedGoldModal.promptText, SUBTITLE_COLOR)

    local goldContainer = createMoneyInput(collectedGoldModal, 'g')
    local silverContainer = createMoneyInput(collectedGoldModal, 's')
    local copperContainer = createMoneyInput(collectedGoldModal, 'c')

    silverContainer:SetPoint('TOP', collectedGoldModal.promptText, 'BOTTOM', 0, -12)
    goldContainer:SetPoint('RIGHT', silverContainer, 'LEFT', -MODAL_INPUT_GAP, 0)
    copperContainer:SetPoint('LEFT', silverContainer, 'RIGHT', MODAL_INPUT_GAP, 0)

    collectedGoldModal.goldInput = goldContainer.input
    collectedGoldModal.silverInput = silverContainer.input
    collectedGoldModal.copperInput = copperContainer.input

    local function focusNext(current, nextInput)
      current:SetScript('OnTabPressed', function()
        nextInput:SetFocus()
      end)
      current:SetScript('OnEnterPressed', function()
        submitCollectedGoldModal()
      end)
    end

    focusNext(collectedGoldModal.goldInput, collectedGoldModal.silverInput)
    focusNext(collectedGoldModal.silverInput, collectedGoldModal.copperInput)
    focusNext(collectedGoldModal.copperInput, collectedGoldModal.goldInput)

    collectedGoldModal.cancelButton = CreateFrame('Button', nil, collectedGoldModal, 'UIPanelButtonTemplate')
    collectedGoldModal.cancelButton:SetSize(MODAL_BUTTON_WIDTH, MODAL_BUTTON_HEIGHT)
    collectedGoldModal.cancelButton:SetPoint('BOTTOMLEFT', collectedGoldModal, 'BOTTOMLEFT', MODAL_CONTENT_INSET, 18)
    collectedGoldModal.cancelButton:SetText('Cancel')
    collectedGoldModal.cancelButton:SetScript('OnClick', hideCollectedGoldModal)

    collectedGoldModal.addButton = CreateFrame('Button', nil, collectedGoldModal, 'UIPanelButtonTemplate')
    collectedGoldModal.addButton:SetSize(MODAL_BUTTON_WIDTH, MODAL_BUTTON_HEIGHT)
    collectedGoldModal.addButton:SetPoint('BOTTOMRIGHT', collectedGoldModal, 'BOTTOMRIGHT', -MODAL_CONTENT_INSET, 18)
    collectedGoldModal.addButton:SetText('Add')
    collectedGoldModal.addButton:SetScript('OnClick', submitCollectedGoldModal)

    collectedGoldModal:SetScript('OnHide', clearModalInputs)
    collectedGoldModal:Hide()
  end

  clearModalInputs()
  collectedGoldModal:Show()
  collectedGoldModal.goldInput:SetFocus()
  collectedGoldModal.goldInput:HighlightText()
end

local function buildCollectedRow(panel)
  local collectedSection = CreateFrame('Frame', nil, panel)
  collectedSection:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', LIST_LEFT_OFFSET, COLLECTED_ROW_BOTTOM)
  collectedSection:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -LIST_LEFT_OFFSET, COLLECTED_ROW_BOTTOM)
  collectedSection:SetHeight(COLLECTED_SECTION_HEIGHT)
  panel.collectedRow = collectedSection

  local label = collectedSection:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  label:SetPoint('TOPLEFT', collectedSection, 'TOPLEFT', 0, 0)
  label:SetText('Tax collected')
  setTextColor(label, RANK_COLOR)
  panel.collectedLabel = label

  local buttonRow = CreateFrame('Frame', nil, collectedSection)
  buttonRow:SetPoint('TOPLEFT', label, 'BOTTOMLEFT', 0, -COLLECTED_TITLE_GAP)
  buttonRow:SetPoint('TOPRIGHT', collectedSection, 'TOPRIGHT', 0, -COLLECTED_TITLE_GAP)
  buttonRow:SetHeight(COLLECTED_BUTTON_HEIGHT)
  panel.collectedButtonRow = buttonRow

  local addButton = CreateFrame('Button', nil, buttonRow, 'UIPanelButtonTemplate')
  addButton:SetSize(COLLECTED_BUTTON_WIDTH, COLLECTED_BUTTON_HEIGHT)
  addButton:SetPoint('RIGHT', buttonRow, 'RIGHT', 0, 0)
  addButton:SetText('Add')
  addButton:SetScript('OnClick', showCollectedGoldModal)
  panel.addCollectedButton = addButton

  local sentButton = CreateFrame('Button', nil, buttonRow, 'UIPanelButtonTemplate')
  sentButton:SetSize(COLLECTED_BUTTON_WIDTH, COLLECTED_BUTTON_HEIGHT)
  sentButton:SetPoint('RIGHT', addButton, 'LEFT', -COLLECTED_BUTTON_GAP, 0)
  sentButton:SetText('Clear')
  sentButton:SetScript('OnClick', showClearCollectedConfirm)
  panel.sentToTaxManButton = sentButton

  local amountText = buttonRow:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  amountText:SetPoint('LEFT', buttonRow, 'LEFT', 0, 0)
  amountText:SetPoint('RIGHT', sentButton, 'LEFT', -8, 0)
  amountText:SetJustifyH('LEFT')
  setTextColor(amountText, AMOUNT_COLOR)
  panel.collectedAmountText = amountText
end

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
  leaderboardTitle:SetText('Highest tax accumulators')
  setTextColor(leaderboardTitle, RANK_COLOR)
  deathTaxPanel.leaderboardTitle = leaderboardTitle

  buildCollectedRow(deathTaxPanel)

  deathTaxPanel.listFrame = CreateFrame('Frame', nil, deathTaxPanel)
  deathTaxPanel.listFrame:SetPoint('TOPLEFT', leaderboardTitle, 'BOTTOMLEFT', LIST_LEFT_OFFSET - 8, -TITLE_LIST_GAP)
  deathTaxPanel.listFrame:SetPoint('BOTTOMRIGHT', deathTaxPanel.collectedRow, 'TOPRIGHT', 0, 8)

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

  hideCollectedGoldModal()
  hideClearCollectedConfirm()

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
