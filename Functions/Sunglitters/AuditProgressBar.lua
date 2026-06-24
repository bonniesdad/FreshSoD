local AUDIT_DURATION = 6
local BAR_WIDTH = 220
local BAR_HEIGHT = 48
local STATUS_HEIGHT = 14
local FRAME_TOP_PADDING = 10
local BAR_LABEL_GAP = 10
local BAR_HORIZONTAL_INSET = 14
local FRAME_BOTTOM_PADDING = 12

local activeBars = {}

local function stopBar(barState, cancelled)
  if barState.stopped then
    return
  end

  barState.stopped = true
  barState.frame:SetScript('OnUpdate', nil)
  barState.frame:Hide()
  activeBars[barState] = nil

  if cancelled and barState.onCancelled then
    barState.onCancelled()
  elseif not cancelled and barState.onComplete then
    barState.onComplete()
  end
end

function FreshSoD_HideAuditProgressBar(barState)
  if barState then
    stopBar(barState, true)
  end
end

function FreshSoD_ShowAuditProgressBar(options)
  local parent = options.parent or UIParent
  local labelText = options.label or 'Auditing'
  local duration = options.duration or AUDIT_DURATION

  local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  frame:SetSize(BAR_WIDTH, BAR_HEIGHT)
  frame:SetPoint('CENTER', parent, 'CENTER', 0, 0)
  frame:SetFrameStrata('HIGH')
  frame:SetFrameLevel(200)
  frame:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
    edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.08, 0.03, 0.03, 0.92)
  frame:SetBackdropBorderColor(0.78, 0.48, 0.12, 0.9)

  local label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  label:SetPoint('TOP', frame, 'TOP', 0, -FRAME_TOP_PADDING)
  label:SetText(labelText)
  label:SetTextColor(0.92, 0.87, 0.76)

  local statusBar = CreateFrame('StatusBar', nil, frame)
  statusBar:SetPoint('TOP', label, 'BOTTOM', 0, -BAR_LABEL_GAP)
  statusBar:SetPoint('LEFT', frame, 'LEFT', BAR_HORIZONTAL_INSET, 0)
  statusBar:SetPoint('RIGHT', frame, 'RIGHT', -BAR_HORIZONTAL_INSET, 0)
  statusBar:SetHeight(STATUS_HEIGHT)
  statusBar:SetStatusBarTexture('Interface\\TARGETINGFRAME\\UI-StatusBar')
  statusBar:SetStatusBarColor(0.78, 0.48, 0.12)
  statusBar:SetMinMaxValues(0, 1)
  statusBar:SetValue(0)

  local statusBackground = statusBar:CreateTexture(nil, 'BACKGROUND')
  statusBackground:SetAllPoints()
  statusBackground:SetColorTexture(0.1, 0.1, 0.1, 0.8)

  frame:SetHeight(
    FRAME_TOP_PADDING + label:GetStringHeight() + BAR_LABEL_GAP + STATUS_HEIGHT + FRAME_BOTTOM_PADDING
  )

  local barState = {
    frame = frame,
    elapsed = 0,
    duration = duration,
    onComplete = options.onComplete,
    onCancelled = options.onCancelled,
    shouldCancel = options.shouldCancel,
    stopped = false,
  }

  frame:Show()
  activeBars[barState] = true

  frame:SetScript('OnUpdate', function(_, elapsed)
    if barState.stopped then
      return
    end

    if barState.shouldCancel and barState.shouldCancel() then
      stopBar(barState, true)
      return
    end

    barState.elapsed = barState.elapsed + elapsed
    statusBar:SetValue(math.min(barState.elapsed / barState.duration, 1))

    if barState.elapsed >= barState.duration then
      stopBar(barState, false)
    end
  end)

  return barState
end
