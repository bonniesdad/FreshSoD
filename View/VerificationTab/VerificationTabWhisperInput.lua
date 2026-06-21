local LIST_LEFT_OFFSET = 10
local BOTTOM_MARGIN = 0
local INPUT_BOTTOM_GAP = 6
local INPUT_ROW_HEIGHT = 24
local SEND_BUTTON_WIDTH = 56
local SEND_BUTTON_GAP = 6

local HELPER_TEXT = 'Send your tampering history to another player'

local function updateWhisperInputLayout(content)
  local contentWidth = content:GetWidth()
  local inputWidth = contentWidth - (LIST_LEFT_OFFSET * 2) - SEND_BUTTON_WIDTH - SEND_BUTTON_GAP
  if inputWidth < 1 then
    inputWidth = 1
  end

  content.whisperSendButton:SetSize(SEND_BUTTON_WIDTH, INPUT_ROW_HEIGHT)
  content.whisperSendButton:ClearAllPoints()
  content.whisperSendButton:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -LIST_LEFT_OFFSET, BOTTOM_MARGIN)

  content.whisperPlayerInput:SetSize(inputWidth, INPUT_ROW_HEIGHT)
  content.whisperPlayerInput:ClearAllPoints()
  content.whisperPlayerInput:SetPoint('RIGHT', content.whisperSendButton, 'LEFT', -SEND_BUTTON_GAP, 0)
  content.whisperPlayerInput:SetPoint('BOTTOM', content.whisperSendButton, 'BOTTOM', 0, 0)

  content.whisperHelperLabel:ClearAllPoints()
  content.whisperHelperLabel:SetPoint('BOTTOMLEFT', content.whisperPlayerInput, 'TOPLEFT', 0, INPUT_BOTTOM_GAP)
  content.whisperHelperLabel:SetWidth(inputWidth + SEND_BUTTON_WIDTH + SEND_BUTTON_GAP)
  content.whisperHelperLabel:SetWordWrap(true)
  content.whisperHelperLabel:SetJustifyH('LEFT')
  content.whisperHelperLabel:SetJustifyV('BOTTOM')
end

local function ensureWhisperInputLayout(content)
  if content.whisperInputInitialized then
    return
  end

  content.whisperHelperLabel = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  content.whisperHelperLabel:SetText(HELPER_TEXT)
  content.whisperHelperLabel:SetTextColor(0.85, 0.85, 0.85)
  content.whisperHelperLabel:SetDrawLayer('OVERLAY', 2)

  content.whisperPlayerInput = CreateFrame('EditBox', nil, content, 'InputBoxTemplate')
  content.whisperPlayerInput:SetAutoFocus(false)
  content.whisperPlayerInput:SetMaxLetters(50)
  content.whisperPlayerInput:SetFrameLevel(content:GetFrameLevel() + 10)

  content.whisperSendButton = CreateFrame('Button', nil, content, 'UIPanelButtonTemplate')
  content.whisperSendButton:SetText('Send')
  content.whisperSendButton:SetFrameLevel(content:GetFrameLevel() + 10)
  content.whisperSendButton:SetScript('OnClick', function()
    local playerName = content.whisperPlayerInput:GetText()
    if playerName then
      playerName = playerName:match('^%s*(.-)%s*$')
    end
    FreshSoD_SendTamperingHistory(playerName)
    content.whisperPlayerInput:SetText('')
  end)

  content.whisperPlayerInput:SetScript('OnEnterPressed', function()
    content.whisperSendButton:Click()
  end)

  content.whisperInputInitialized = true
end

function FreshSoD_EnsureVerificationTabWhisperInput(content)
  ensureWhisperInputLayout(content)
  updateWhisperInputLayout(content)
end
