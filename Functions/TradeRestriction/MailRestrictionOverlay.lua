local overlay
local OVERLAY_PADDING = 12
local BUTTON_WIDTH = 110
local BUTTON_HEIGHT = 24
local BUTTON_BOTTOM_MARGIN = 20
local BUTTON_GAP = 12
local MESSAGE_TEXT = 'Mail from invalid players must be returned before you can continue'

local function getRemainingMailCount()
  if type(FreshSoD_GetNonGuildMailIndices) ~= 'function' then
    return 0
  end

  return #FreshSoD_GetNonGuildMailIndices()
end

local function getOverlayMessage()
  local remaining = getRemainingMailCount()
  local noun = remaining == 1 and 'mail' or 'mails'
  return MESSAGE_TEXT .. '\n\nRemaining to return: ' .. remaining .. ' ' .. noun
end

local function closeMailbox()
  if CloseMail then
    CloseMail()
  elseif MailFrame then
    MailFrame:Hide()
  end
end

function FreshSoD_ShowMailRestrictionOverlay()
  if not MailFrame then
    return
  end

  if not overlay then
    overlay = CreateFrame('Frame', 'FreshSoDMailRestrictionOverlay', MailFrame, 'BackdropTemplate')
    overlay:SetFrameStrata('HIGH')
    overlay:SetFrameLevel(MailFrame:GetFrameLevel() + 20)
    overlay:EnableMouse(true)
    overlay:SetBackdrop({
      bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
      edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 11, top = 11, bottom = 11 },
    })
    overlay:SetBackdropColor(0, 0, 0, 0.95)

    overlay.messageText = overlay:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    overlay.messageText:SetPoint('CENTER', 0, 16)
    overlay.messageText:SetWidth(MailFrame:GetWidth() - 48)
    overlay.messageText:SetWordWrap(true)
    overlay.messageText:SetJustifyH('CENTER')
    overlay.messageText:SetJustifyV('MIDDLE')
    overlay.messageText:SetText(getOverlayMessage())

    overlay.cancelButton = CreateFrame('Button', nil, overlay, 'UIPanelButtonTemplate')
    overlay.cancelButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    overlay.cancelButton:SetText('Cancel')
    overlay.cancelButton:SetScript('OnClick', function()
      FreshSoD_HideMailRestrictionOverlay()
      closeMailbox()
    end)

    overlay.returnButton = CreateFrame('Button', nil, overlay, 'UIPanelButtonTemplate')
    overlay.returnButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    overlay.returnButton:SetText('Return mail')
    overlay.returnButton:SetScript('OnClick', function()
      FreshSoD_ReturnNonGuildMail()
    end)
  end

  overlay.messageText:SetWidth(MailFrame:GetWidth() - 48)
  overlay.messageText:SetText(getOverlayMessage())

  overlay.cancelButton:ClearAllPoints()
  overlay.cancelButton:SetPoint('BOTTOMLEFT', overlay, 'BOTTOMLEFT', BUTTON_BOTTOM_MARGIN, BUTTON_BOTTOM_MARGIN)

  overlay.returnButton:ClearAllPoints()
  overlay.returnButton:SetPoint('BOTTOMRIGHT', overlay, 'BOTTOMRIGHT', -BUTTON_BOTTOM_MARGIN, BUTTON_BOTTOM_MARGIN)

  overlay:SetSize(MailFrame:GetWidth() + (OVERLAY_PADDING * 2), MailFrame:GetHeight() + (OVERLAY_PADDING * 2))
  overlay:ClearAllPoints()
  overlay:SetPoint('CENTER', MailFrame, 'CENTER')
  overlay:Show()
end

function FreshSoD_HideMailRestrictionOverlay()
  if overlay then
    overlay:Hide()
  end
end

function FreshSoD_UpdateMailRestrictionOverlay()
  if MailFrame and MailFrame:IsShown() and FreshSoD_HasNonGuildMail() then
    FreshSoD_ShowMailRestrictionOverlay()
    return
  end

  FreshSoD_HideMailRestrictionOverlay()
end
