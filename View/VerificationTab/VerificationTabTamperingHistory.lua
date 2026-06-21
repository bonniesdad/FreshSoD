local LIST_LEFT_OFFSET = 10
local ANCHOR_TOP_GAP = 12
local WHISPER_TOP_GAP = -10
local PANEL_PADDING = 8
local SCROLLBAR_NUDGE_RIGHT = -20
local TITLE_DIVIDER_GAP = 6
local DIVIDER_GAP = 6
local ROW_GAP = 4
local EMPTY_TITLE = 'No tampering recorded'
local EMPTY_SUBTEXT = 'Violations and resets will appear here.'

local ENTRY_COLOR = { r = 0.85, g = 0.85, b = 0.85 }
local EMPTY_TITLE_COLOR = { r = 0.75, g = 0.72, b = 0.66 }
local EMPTY_SUBTEXT_COLOR = { r = 0.58, g = 0.56, b = 0.52 }

local function formatHistoryEntry(index, entry)
  local timestamp = entry.timestamp and date('%Y-%m-%d %H:%M', entry.timestamp) or 'Unknown time'
  return string.format('%d. [%s] %s', index, timestamp, entry.reason or 'Unknown')
end

local function nudgeScrollBarRight(scrollFrame, px)
  if not px or px == 0 or scrollFrame.tamperingHistoryScrollBarNudged then
    return
  end

  local function nudgeFrame(frame)
    if not frame or not frame.GetNumPoints then
      return
    end

    local numPoints = frame:GetNumPoints()
    if numPoints < 1 then
      return
    end

    local points = {}
    for index = 1, numPoints do
      points[index] = { frame:GetPoint(index) }
    end

    frame:ClearAllPoints()
    for _, point in ipairs(points) do
      local anchorPoint, relativeTo, relativePoint, x, y = point[1], point[2], point[3], point[4], point[5]
      x = x or 0
      y = y or 0
      if relativeTo == scrollFrame then
        x = x + px
      end
      frame:SetPoint(anchorPoint, relativeTo, relativePoint, x, y)
    end
  end

  nudgeFrame(scrollFrame.ScrollBar)
  nudgeFrame(scrollFrame.ScrollUpButton)
  nudgeFrame(scrollFrame.ScrollDownButton)

  scrollFrame.tamperingHistoryScrollBarNudged = true
end

local function updateScrollChildWidth(content)
  local scrollFrame = content.tamperingHistoryScroll
  local scrollChild = content.tamperingHistoryScrollChild
  if not scrollFrame or not scrollChild then
    return
  end

  local width = scrollFrame:GetWidth() - (PANEL_PADDING * 2)
  if width < 1 then
    width = 1
  end
  scrollChild:SetWidth(width)

  for _, row in ipairs(content.tamperingHistoryRows) do
    row:SetWidth(width)
  end
end

local function ensureTamperingHistoryLayout(content)
  if content.tamperingHistoryInitialized then
    return
  end

  content.tamperingHistoryPanel = CreateFrame('Frame', nil, content, 'BackdropTemplate')
  content.tamperingHistoryPanel:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 64,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  content.tamperingHistoryPanel:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
  content.tamperingHistoryPanel:SetBackdropBorderColor(0.35, 0.34, 0.32, 0.75)

  content.tamperingHistorySubHeader = content.tamperingHistoryPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  content.tamperingHistorySubHeader:SetText('Tampering History')
  content.tamperingHistorySubHeader:SetTextColor(0.922, 0.871, 0.761)
  content.tamperingHistorySubHeader:SetJustifyH('LEFT')

  content.tamperingHistoryDivider = content.tamperingHistoryPanel:CreateTexture(nil, 'ARTWORK')
  content.tamperingHistoryDivider:SetColorTexture(0.41, 0.39, 0.36, 0.45)
  content.tamperingHistoryDivider:SetHeight(1)

  content.tamperingHistoryEmptyTitle = content.tamperingHistoryPanel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  content.tamperingHistoryEmptyTitle:SetText(EMPTY_TITLE)
  content.tamperingHistoryEmptyTitle:SetTextColor(EMPTY_TITLE_COLOR.r, EMPTY_TITLE_COLOR.g, EMPTY_TITLE_COLOR.b)

  content.tamperingHistoryEmptySubtext = content.tamperingHistoryPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  content.tamperingHistoryEmptySubtext:SetText(EMPTY_SUBTEXT)
  content.tamperingHistoryEmptySubtext:SetTextColor(EMPTY_SUBTEXT_COLOR.r, EMPTY_SUBTEXT_COLOR.g, EMPTY_SUBTEXT_COLOR.b)
  content.tamperingHistoryEmptySubtext:SetWordWrap(true)
  content.tamperingHistoryEmptySubtext:SetJustifyH('CENTER')
  content.tamperingHistoryEmptySubtext:SetJustifyV('TOP')

  content.tamperingHistoryScroll = CreateFrame('ScrollFrame', nil, content.tamperingHistoryPanel, 'UIPanelScrollFrameTemplate')
  content.tamperingHistoryScrollChild = CreateFrame('Frame', nil, content.tamperingHistoryScroll)
  content.tamperingHistoryScrollChild:SetHeight(1)
  content.tamperingHistoryScroll:SetScrollChild(content.tamperingHistoryScrollChild)
  content.tamperingHistoryRows = {}
  nudgeScrollBarRight(content.tamperingHistoryScroll, SCROLLBAR_NUDGE_RIGHT)

  content.tamperingHistoryScroll:SetScript('OnSizeChanged', function()
    updateScrollChildWidth(content)
  end)

  content.tamperingHistoryInitialized = true
end

local function updateTamperingHistoryRows(content, entries)
  local scrollChild = content.tamperingHistoryScrollChild
  local rowWidth = scrollChild:GetWidth()
  if rowWidth < 1 then
    rowWidth = 1
  end
  local yOffset = 0

  for index, entry in ipairs(entries) do
    local row = content.tamperingHistoryRows[index]
    if not row then
      row = scrollChild:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
      content.tamperingHistoryRows[index] = row
    end

    row:ClearAllPoints()
    row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, -yOffset)
    row:SetWidth(rowWidth)
    row:SetJustifyH('LEFT')
    row:SetJustifyV('TOP')
    row:SetWordWrap(true)
    row:SetText(formatHistoryEntry(index, entry))
    row:SetTextColor(ENTRY_COLOR.r, ENTRY_COLOR.g, ENTRY_COLOR.b)
    row:Show()

    yOffset = yOffset + row:GetStringHeight() + ROW_GAP
  end

  if #entries > 0 then
    yOffset = yOffset - ROW_GAP
  end

  for index = #entries + 1, #content.tamperingHistoryRows do
    content.tamperingHistoryRows[index]:Hide()
  end

  scrollChild:SetHeight(math.max(yOffset, 1))
  content.tamperingHistoryScroll:SetVerticalScroll(0)

  local hasEntries = #entries > 0
  content.tamperingHistoryScroll:SetShown(hasEntries)
  content.tamperingHistoryEmptyTitle:SetShown(not hasEntries)
  content.tamperingHistoryEmptySubtext:SetShown(not hasEntries)
end

local function updateTamperingHistoryLayout(content, anchorFrame)
  content.tamperingHistoryPanel:ClearAllPoints()
  content.tamperingHistoryPanel:SetPoint('TOP', anchorFrame, 'BOTTOM', 0, -ANCHOR_TOP_GAP)
  content.tamperingHistoryPanel:SetPoint('LEFT', content, 'LEFT', LIST_LEFT_OFFSET, 0)
  content.tamperingHistoryPanel:SetPoint('RIGHT', content, 'RIGHT', -LIST_LEFT_OFFSET, 0)

  if content.whisperHelperLabel then
    content.tamperingHistoryPanel:SetPoint('BOTTOM', content.whisperHelperLabel, 'TOP', 0, -WHISPER_TOP_GAP)
  end

  content.tamperingHistorySubHeader:ClearAllPoints()
  content.tamperingHistorySubHeader:SetPoint('TOPLEFT', content.tamperingHistoryPanel, 'TOPLEFT', PANEL_PADDING, -PANEL_PADDING)
  content.tamperingHistorySubHeader:SetPoint('RIGHT', content.tamperingHistoryPanel, 'RIGHT', -PANEL_PADDING, 0)

  content.tamperingHistoryDivider:ClearAllPoints()
  content.tamperingHistoryDivider:SetPoint('TOPLEFT', content.tamperingHistorySubHeader, 'BOTTOMLEFT', 0, -TITLE_DIVIDER_GAP)
  content.tamperingHistoryDivider:SetPoint('TOPRIGHT', content.tamperingHistoryPanel, 'TOPRIGHT', -PANEL_PADDING, 0)

  content.tamperingHistoryScroll:ClearAllPoints()
  content.tamperingHistoryScroll:SetPoint('TOPLEFT', content.tamperingHistoryDivider, 'BOTTOMLEFT', 0, -DIVIDER_GAP)
  content.tamperingHistoryScroll:SetPoint('BOTTOMRIGHT', content.tamperingHistoryPanel, 'BOTTOMRIGHT', -PANEL_PADDING, PANEL_PADDING)

  content.tamperingHistoryEmptyTitle:ClearAllPoints()
  content.tamperingHistoryEmptyTitle:SetPoint('CENTER', content.tamperingHistoryPanel, 'CENTER', 0, -6)
  content.tamperingHistoryEmptyTitle:SetJustifyH('CENTER')

  content.tamperingHistoryEmptySubtext:ClearAllPoints()
  content.tamperingHistoryEmptySubtext:SetPoint('TOP', content.tamperingHistoryEmptyTitle, 'BOTTOM', 0, -4)
  content.tamperingHistoryEmptySubtext:SetPoint('LEFT', content.tamperingHistoryPanel, 'LEFT', PANEL_PADDING + 12, 0)
  content.tamperingHistoryEmptySubtext:SetPoint('RIGHT', content.tamperingHistoryPanel, 'RIGHT', -(PANEL_PADDING + 12), 0)

  updateScrollChildWidth(content)
end

function FreshSoD_EnsureVerificationTabTamperingHistory(content)
  ensureTamperingHistoryLayout(content)
end

function FreshSoD_UpdateVerificationTabTamperingHistory(content, anchorFrame)
  if not anchorFrame then
    return
  end

  ensureTamperingHistoryLayout(content)
  updateTamperingHistoryLayout(content, anchorFrame)
  updateTamperingHistoryRows(content, FreshSoD_GetTamperingHistory())
end
