local TITLE_TOP_OFFSET = -74
local LIST_LEFT_OFFSET = 10
local TITLE_BOTTOM_GAP = 16
local ROW_GAP = 12
local HELPER_INDENT = 12
local HELPER_TOP_GAP = 4

local STATUS_TITLE = {
  valid = { text = 'Valid', r = 0.35, g = 0.8, b = 0.35 },
  pending = { text = 'Not Started', r = 0.95, g = 0.82, b = 0.25 },
  invalid = { text = 'Invalid', r = 0.82, g = 0.33, b = 0.33 },
}

local CHECK_PASS_COLOR = { r = 0.35, g = 0.8, b = 0.35 }
local CHECK_PENDING_COLOR = { r = 0.95, g = 0.82, b = 0.25 }
local CHECK_FAIL_COLOR = { r = 0.82, g = 0.33, b = 0.33 }

local function getDetectedOnHelperText(failedAt)
  if failedAt then
    return 'Detected on ' .. date('%d %b %Y', failedAt)
  end
end

local function getVerificationChecks()
  local playerTamperingValidationFailed = BonniesUtilities_GetNaughtyBoolean() == true

  return {
    {
      passed = playerTamperingValidationFailed == false,
      passMessage = 'No tampering detected',
      failMessage = 'Tampering detected',
      helperTexts = nil,
    }
  }
end

local function getOverallStatus(checks)
  local hasPending = false
  for _, check in ipairs(checks) do
    if check.pending then
      hasPending = true
    end
    if not check.passed then
      if not check.pending then
        return STATUS_TITLE.invalid
      end
    end
  end

  if hasPending then
    return STATUS_TITLE.pending
  end

  return STATUS_TITLE.valid
end

local function getWrapWidth(content, extraIndent)
  extraIndent = extraIndent or 0
  local width = content:GetWidth() - (LIST_LEFT_OFFSET * 2) - extraIndent
  if width < 1 then
    return 1
  end
  return width
end

local function applyWrappedText(fontString, content, extraIndent)
  fontString:SetWidth(getWrapWidth(content, extraIndent))
  fontString:SetWordWrap(true)
  fontString:SetJustifyH('LEFT')
  fontString:SetJustifyV('TOP')
end

local function ensureVerificationTabLayout(content)
  if content.verificationInitialized then
    return
  end

  content.titleLabel = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightHuge')
  content.checkRows = {}
  content.checkHelperRows = {}
  content.verificationInitialized = true
end

local function updateVerificationTabDisplay(content)
  local checks = getVerificationChecks()
  local status = getOverallStatus(checks)

  applyWrappedText(content.titleLabel, content)
  content.titleLabel:ClearAllPoints()
  content.titleLabel:SetPoint('TOPLEFT', content, 'TOPLEFT', LIST_LEFT_OFFSET, TITLE_TOP_OFFSET)
  content.titleLabel:SetText(status.text)
  content.titleLabel:SetTextColor(status.r, status.g, status.b)

  local blockEnd = content.titleLabel
  local firstRowGap = -TITLE_BOTTOM_GAP

  for index, check in ipairs(checks) do
    local row = content.checkRows[index]
    if not row then
      row = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
      content.checkRows[index] = row
    end

    applyWrappedText(row, content)
    row:ClearAllPoints()
    row:SetPoint('TOP', blockEnd, 'BOTTOM', 0, firstRowGap)
    row:SetPoint('LEFT', content, 'LEFT', LIST_LEFT_OFFSET, 0)
    firstRowGap = -ROW_GAP

    local passed = check.passed
    local pending = check.pending == true
    local color = pending and CHECK_PENDING_COLOR or (passed and CHECK_PASS_COLOR or CHECK_FAIL_COLOR)
    local rowMessage = pending and check.pendingMessage or (passed and check.passMessage or check.failMessage)
    row:SetText('• ' .. rowMessage)
    row:SetTextColor(color.r, color.g, color.b)
    row:Show()

    blockEnd = row

    local helperRows = content.checkHelperRows[index]
    if not helperRows then
      helperRows = {}
      content.checkHelperRows[index] = helperRows
    end

    local helperTexts = check.helperTexts
    if helperTexts and #helperTexts > 0 and (not passed or pending) then
      for helperIndex, helperText in ipairs(helperTexts) do
        local helper = helperRows[helperIndex]
        if not helper then
          helper = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
          helperRows[helperIndex] = helper
        end

        applyWrappedText(helper, content, HELPER_INDENT)
        helper:ClearAllPoints()
        helper:SetPoint('TOP', blockEnd, 'BOTTOM', 0, -HELPER_TOP_GAP)
        helper:SetPoint('LEFT', content, 'LEFT', LIST_LEFT_OFFSET + HELPER_INDENT, 0)
        helper:SetText(helperText)
        helper:SetTextColor(0.85, 0.85, 0.85)
        helper:Show()

        blockEnd = helper
      end
    end

    for helperIndex = (helperTexts and #helperTexts or 0) + 1, #helperRows do
      helperRows[helperIndex]:Hide()
    end
  end

  for index = #checks + 1, #content.checkRows do
    content.checkRows[index]:Hide()
  end

  if content.checkHelperRows then
    for index = #checks + 1, #content.checkHelperRows do
      local helperRows = content.checkHelperRows[index]
      if helperRows then
        for _, helper in ipairs(helperRows) do
          helper:Hide()
        end
      end
    end
  end

  FreshSoD_UpdateVerificationTabTamperingHistory(content, blockEnd)
  FreshSoD_EnsureVerificationTabWhisperInput(content)
end

function FreshSoD_InitializeVerificationTab(tabContents)
  local content = tabContents[1]
  if not content then
    return
  end

  ensureVerificationTabLayout(content)
  FreshSoD_EnsureVerificationTabWhisperInput(content)
  FreshSoD_EnsureVerificationTabTamperingHistory(content)
  updateVerificationTabDisplay(content)
end
