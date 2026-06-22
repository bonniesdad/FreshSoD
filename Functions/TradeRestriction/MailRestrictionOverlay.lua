local NUM_MAIL_ROWS = INBOXITEMS_TO_DISPLAY or 7
local ROW_MESSAGE = 'Invalid sender'
local OPEN_ALL_BLOCKER_TEXT = 'Blocked'
local OPEN_ALL_BLOCKER_PADDING_X = 4
local BUTTON_WIDTH = 64
local BUTTON_HEIGHT = 18
local BUTTON_GAP = 4
local MESSAGE_INSET = 8
local TEXT_BLOCK_CENTER_OFFSET = -7
local SENDER_MESSAGE_GAP = 2

local rowOverlays = {}
local openAllBlocker
local restrictedIndexSet = {}

local function buildRestrictedIndexSet()
  wipe(restrictedIndexSet)

  if type(FreshSoD_GetNonGuildMailIndices) ~= 'function' then
    return restrictedIndexSet
  end

  for _, inboxIndex in ipairs(FreshSoD_GetNonGuildMailIndices()) do
    restrictedIndexSet[inboxIndex] = true
  end

  return restrictedIndexSet
end

local function hasRestrictedMail()
  return next(restrictedIndexSet) ~= nil
end

function FreshSoD_ShouldBlockOpenAllMail()
  if type(FreshSoD_IsMailInboxScanPending) == 'function' and FreshSoD_IsMailInboxScanPending() then
    return true
  end

  buildRestrictedIndexSet()
  return hasRestrictedMail()
end

local function getMailRowFrame(slotIndex)
  return _G['MailItem' .. slotIndex]
end

local function getMailRowButton(slotIndex)
  return _G['MailItem' .. slotIndex .. 'Button']
end

local function createRowOverlay(slotIndex)
  local mailRow = getMailRowFrame(slotIndex)
  if not mailRow then
    return nil
  end

  local overlay = CreateFrame('Frame', 'FreshSoDMailRestrictionRowOverlay' .. slotIndex, mailRow, 'BackdropTemplate')
  overlay:SetAllPoints(mailRow)
  overlay:SetFrameStrata('HIGH')
  overlay:SetFrameLevel(mailRow:GetFrameLevel() + 20)
  overlay:EnableMouse(true)
  overlay:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
    tile = true,
    tileSize = 8,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  overlay:SetBackdropColor(0, 0, 0, 0.9)
  overlay:SetBackdropBorderColor(0.6, 0.1, 0.1, 1)

  overlay.returnButton = CreateFrame('Button', nil, overlay, 'UIPanelButtonTemplate')
  overlay.returnButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  overlay.returnButton:SetText('Return')
  overlay.returnButton:SetScript('OnClick', function()
    if overlay.inboxIndex then
      FreshSoD_ReturnNonGuildMailAtIndex(overlay.inboxIndex)
    end
  end)

  overlay.deleteButton = CreateFrame('Button', nil, overlay, 'UIPanelButtonTemplate')
  overlay.deleteButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  overlay.deleteButton:SetText('Delete')
  overlay.deleteButton:SetScript('OnClick', function()
    if overlay.inboxIndex then
      FreshSoD_DeleteNonGuildMailAtIndex(overlay.inboxIndex)
    end
  end)

  overlay.deleteButton:SetPoint('RIGHT', overlay, 'RIGHT', -MESSAGE_INSET, 0)
  overlay.returnButton:SetPoint('RIGHT', overlay.deleteButton, 'LEFT', -BUTTON_GAP, 0)

  overlay.messageText = overlay:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  overlay.messageText:SetPoint('LEFT', overlay, 'LEFT', MESSAGE_INSET, TEXT_BLOCK_CENTER_OFFSET)
  overlay.messageText:SetPoint('RIGHT', overlay.returnButton, 'LEFT', -BUTTON_GAP, TEXT_BLOCK_CENTER_OFFSET)
  overlay.messageText:SetJustifyH('LEFT')
  overlay.messageText:SetText(ROW_MESSAGE)

  overlay.senderText = overlay:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  overlay.senderText:SetPoint('BOTTOMLEFT', overlay.messageText, 'TOPLEFT', 0, SENDER_MESSAGE_GAP)
  overlay.senderText:SetPoint('RIGHT', overlay.returnButton, 'LEFT', -BUTTON_GAP, 0)
  overlay.senderText:SetJustifyH('LEFT')
  overlay.senderText:SetTextColor(1, 1, 1)

  overlay:Hide()
  return overlay
end

local function getOrCreateRowOverlay(slotIndex)
  if not rowOverlays[slotIndex] then
    rowOverlays[slotIndex] = createRowOverlay(slotIndex)
  end

  return rowOverlays[slotIndex]
end

local function getRestrictedMailCount()
  local count = 0
  for _ in pairs(restrictedIndexSet) do
    count = count + 1
  end
  return count
end

local function createOpenAllBlocker()
  local blocker = CreateFrame('Frame', 'FreshSoDMailOpenAllBlocker', OpenAllMail, 'BackdropTemplate')
  blocker:SetPoint('TOPLEFT', OpenAllMail, 'TOPLEFT', -OPEN_ALL_BLOCKER_PADDING_X, 0)
  blocker:SetPoint('BOTTOMRIGHT', OpenAllMail, 'BOTTOMRIGHT', OPEN_ALL_BLOCKER_PADDING_X, 0)
  blocker:SetFrameStrata('HIGH')
  blocker:SetFrameLevel(OpenAllMail:GetFrameLevel() + 10)
  blocker:EnableMouse(true)
  blocker:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  blocker:SetBackdropColor(0.08, 0.02, 0.02, 0.94)
  blocker:SetBackdropBorderColor(0.7, 0.15, 0.1, 1)

  blocker.label = blocker:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  blocker.label:SetPoint('CENTER', blocker, 'CENTER', 0, 0)
  blocker.label:SetJustifyH('CENTER')
  blocker.label:SetTextColor(1, 0.82, 0)
  blocker.label:SetText(OPEN_ALL_BLOCKER_TEXT)

    blocker:SetScript('OnEnter', function()
      local scanPending = type(FreshSoD_IsMailInboxScanPending) == 'function' and FreshSoD_IsMailInboxScanPending()
      local remaining = getRestrictedMailCount()
      local noun = remaining == 1 and 'mail' or 'mails'

      GameTooltip:SetOwner(blocker, 'ANCHOR_RIGHT')
      GameTooltip:SetText('Open All disabled', 1, 0.82, 0)
      if scanPending then
        GameTooltip:AddLine('Checking inbox for restricted mail.', 1, 1, 1, true)
      else
        GameTooltip:AddLine('Return or delete restricted ' .. noun .. ' above first.', 1, 1, 1, true)
      end
      if remaining > 0 then
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Remaining: ' .. remaining, 0.75, 0.75, 0.75)
      end
      GameTooltip:Show()
    end)
  blocker:SetScript('OnLeave', function()
    GameTooltip:Hide()
  end)

  return blocker
end

function FreshSoD_EnsureMailOpenAllBlocker()
  if OpenAllMail and not openAllBlocker then
    openAllBlocker = createOpenAllBlocker()
    openAllBlocker:Hide()
  end
end

function FreshSoD_PreemptivelyBlockOpenAllMail()
  FreshSoD_EnsureMailOpenAllBlocker()

  if OpenAllMail then
    OpenAllMail:Disable()
  end

  if openAllBlocker then
    openAllBlocker:Show()
  end
end

local function updateOpenAllBlocker()
  if not OpenAllMail then
    return
  end

  FreshSoD_EnsureMailOpenAllBlocker()

  if FreshSoD_ShouldBlockOpenAllMail() then
    OpenAllMail:Disable()
    openAllBlocker:Show()
    return
  end

  openAllBlocker:Hide()
  OpenAllMail:Enable()
end

local function hideRowOverlays()
  for slotIndex = 1, NUM_MAIL_ROWS do
    local overlay = rowOverlays[slotIndex]
    if overlay then
      overlay.inboxIndex = nil
      overlay:Hide()
    end
  end
end

local function updateRowOverlays()
  for slotIndex = 1, NUM_MAIL_ROWS do
    local overlay = getOrCreateRowOverlay(slotIndex)
    local mailButton = getMailRowButton(slotIndex)

    if overlay and mailButton and mailButton:IsShown() and mailButton.index and restrictedIndexSet[mailButton.index] then
      local _, _, sender = GetInboxHeaderInfo(mailButton.index)
      overlay.inboxIndex = mailButton.index
      overlay.senderText:SetText(Ambiguate(sender or UNKNOWN, 'short'))
      overlay:Show()
    elseif overlay then
      overlay.inboxIndex = nil
      overlay:Hide()
    end
  end
end

function FreshSoD_HideMailRestrictionOverlay()
  hideRowOverlays()
  wipe(restrictedIndexSet)

  if openAllBlocker then
    openAllBlocker:Hide()
  end

  if OpenAllMail then
    OpenAllMail:Enable()
  end
end

function FreshSoD_UpdateMailRestrictionOverlay()
  if not MailFrame or not MailFrame:IsShown() then
    if type(FreshSoD_IsMailInboxScanPending) == 'function' and FreshSoD_IsMailInboxScanPending() then
      FreshSoD_PreemptivelyBlockOpenAllMail()
      return
    end

    FreshSoD_HideMailRestrictionOverlay()
    return
  end

  buildRestrictedIndexSet()
  updateOpenAllBlocker()

  if not InboxFrame or not InboxFrame:IsShown() then
    hideRowOverlays()
    return
  end

  if not hasRestrictedMail() then
    hideRowOverlays()
    return
  end

  updateRowOverlays()
end
