local overlay
local TEXT_INSET = 20
local TEXT_TOP_OFFSET = TEXT_INSET + 40
local WIDTH_OFFSET = 50
local HEIGHT_OFFSET = 110
local POSITION_OFFSET_X = -25
local POSITION_OFFSET_Y = 35
local SENTENCE_GAP = '\n\n\n'
local BUTTON_WIDTH = 110
local BUTTON_HEIGHT = 24
local BUTTON_BOTTOM_MARGIN = 16
local TITLE_TEXT = 'Sending mail in guild found'
local TITLE_COLOR = { 1, 1, 0 }
local TITLE_BODY_GAP = 22
local MESSAGE_LINES = {
  'You can only send mail to your own guild members.',
  'You cannot send mail to players in a sister guilds.  You must trade with them in person.',
  'Sending just gold to a sister guild member will result in the gold being returned to the sender.',
  'Sending items to a sister guild member will result in the items being returned.',
  'Be careful!',
}

local function getBulletText()
  return table.concat(MESSAGE_LINES, SENTENCE_GAP)
end

function FreshSoD_ShowSendMailRestrictionOverlay()
  if not SendMailFrame then
    return
  end

  if not overlay then
    overlay = CreateFrame('Frame', 'FreshSoDSendMailRestrictionOverlay', SendMailFrame, 'BackdropTemplate')
    overlay:SetFrameStrata('HIGH')
    overlay:SetFrameLevel(SendMailFrame:GetFrameLevel() + 20)
    overlay:EnableMouse(true)
    overlay:SetBackdrop({
      bgFile = 'Interface\\Buttons\\WHITE8x8',
      edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
      tile = true,
      tileSize = 8,
      edgeSize = 32,
      insets = { left = 11, right = 11, top = 11, bottom = 11 },
    })
    overlay:SetBackdropColor(0, 0, 0, 1)
    overlay:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

    overlay.titleText = overlay:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    overlay.titleText:SetPoint('TOPLEFT', overlay, 'TOPLEFT', TEXT_INSET, -TEXT_TOP_OFFSET)
    overlay.titleText:SetPoint('TOPRIGHT', overlay, 'TOPRIGHT', -TEXT_INSET, -TEXT_TOP_OFFSET)
    overlay.titleText:SetJustifyH('CENTER')
    overlay.titleText:SetText(TITLE_TEXT)
    overlay.titleText:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])

    overlay.messageText = overlay:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    overlay.messageText:SetPoint('TOPLEFT', overlay.titleText, 'BOTTOMLEFT', 0, -TITLE_BODY_GAP)
    overlay.messageText:SetPoint('TOPRIGHT', overlay.titleText, 'BOTTOMRIGHT', 0, -TITLE_BODY_GAP)
    overlay.messageText:SetWordWrap(true)
    overlay.messageText:SetJustifyH('LEFT')
    overlay.messageText:SetJustifyV('TOP')
    overlay.messageText:SetText(getBulletText())

    overlay.confirmButton = CreateFrame('Button', nil, overlay, 'UIPanelButtonTemplate')
    overlay.confirmButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    overlay.confirmButton:SetText('OK')
    overlay.confirmButton:SetScript('OnClick', function()
      FreshSoD_HideSendMailRestrictionOverlay()
    end)
  end

  overlay:SetSize(SendMailFrame:GetWidth() - WIDTH_OFFSET, SendMailFrame:GetHeight() - HEIGHT_OFFSET)
  overlay:ClearAllPoints()
  overlay:SetPoint('CENTER', SendMailFrame, 'CENTER', POSITION_OFFSET_X, POSITION_OFFSET_Y)
  overlay.confirmButton:ClearAllPoints()
  overlay.confirmButton:SetPoint('BOTTOM', overlay, 'BOTTOM', 0, BUTTON_BOTTOM_MARGIN)
  overlay:Show()
end

function FreshSoD_HideSendMailRestrictionOverlay()
  if overlay then
    overlay:Hide()
  end
end
