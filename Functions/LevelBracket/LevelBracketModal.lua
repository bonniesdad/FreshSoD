local TEXTURE_PATH = 'Interface\\AddOns\\FreshSoD\\Textures'

local modal
local MODAL_WIDTH = 440
local MODAL_HEIGHT = 300
local CONTENT_HORIZONTAL_INSET = 28
local CONTENT_TOP_PADDING = 18
local BUTTON_WIDTH = 130
local BUTTON_HEIGHT = 24
local BUTTON_BOTTOM_MARGIN = 18
local HEADER_HEIGHT = 44
local BORDER_TEXTURE = 'Interface\\DialogFrame\\UI-DialogBox-Border'
local BORDER_EDGE_SIZE = 32
local BORDER_OUTSET = 10

local TITLE_COLOR = { 0.95, 0.82, 0.25 }
local SUBTITLE_COLOR = { 0.78, 0.72, 0.62 }
local SECTION_COLOR = { 0.922, 0.871, 0.761 }
local SCHEDULE_BODY_COLOR = { 0.86, 0.82, 0.74 }
local SCHEDULE_LEVEL_COLOR = { 1, 0.82, 0 }
local SCHEDULE_DATE_COLOR = { 0.55, 0.78, 0.55 }
local BULLET_COLOR = { 0.65, 0.6, 0.5 }

local TITLE_TEXT = 'You must now turn off your XP until the next phase begins'
local SUBTITLE_TEXT = 'Speak to Grendag Brightbeard in Orgrimmar or the Undercity Entrance to disable XP gain'
local SUBSUBTITLE_TEXT = "Orgrimmar coordinates: 49x, 58y. Undercity coordinates: 66.1x, 9.6y"
local SECTION_TITLE_TEXT = 'Phase Schedule'

local SCHEDULE_ENTRIES = {
  { level = '25', date = 'Jun 29th', suffix = 'until' },
  { level = '40', date = 'July 8th', suffix = 'until' },
  { level = '50', date = 'July 15th', suffix = 'until' },
  { level = '60', date = 'July 15th', suffix = 'after' },
}

local pendingBracketLevel

local function setTextColor(fontString, color)
  fontString:SetTextColor(color[1], color[2], color[3])
end

local function formatScheduleLine(entry)
  local levelColor = string.format('|cff%02x%02x%02x', SCHEDULE_LEVEL_COLOR[1] * 255, SCHEDULE_LEVEL_COLOR[2] * 255, SCHEDULE_LEVEL_COLOR[3] * 255)
  local dateColor = string.format('|cff%02x%02x%02x', SCHEDULE_DATE_COLOR[1] * 255, SCHEDULE_DATE_COLOR[2] * 255, SCHEDULE_DATE_COLOR[3] * 255)

  if entry.suffix == 'after' then
    return string.format(
      'Max level %s%s|r after %s%s|r',
      levelColor,
      entry.level,
      dateColor,
      entry.date
    )
  end

  return string.format(
    'Max level %s%s|r until %s%s|r',
    levelColor,
    entry.level,
    dateColor,
    entry.date
  )
end

local function updateScheduleHighlights(bracketLevel)
  if not modal or not modal.scheduleRows then
    return
  end

  for index, entry in ipairs(SCHEDULE_ENTRIES) do
    local rowData = modal.scheduleRows[index]
    local isActive = tonumber(entry.level) == bracketLevel

    if isActive then
      rowData.row:SetFontObject('GameFontHighlight')
      setTextColor(rowData.bullet, TITLE_COLOR)
    else
      rowData.row:SetFontObject('GameFontHighlightSmall')
      setTextColor(rowData.bullet, BULLET_COLOR)
    end

    rowData.row:SetText(formatScheduleLine(entry))
    setTextColor(rowData.row, SCHEDULE_BODY_COLOR)
  end
end

local function hideModal()
  if modal then
    modal:Hide()
  end
  pendingBracketLevel = nil
end

function FreshSoD_ShowLevelBracketModal(bracketLevel)
  pendingBracketLevel = bracketLevel

  if not modal then
    modal = CreateFrame('Frame', 'FreshSoDLevelBracketModal', UIParent, 'BackdropTemplate')
    tinsert(UISpecialFrames, 'FreshSoDLevelBracketModal')
    modal:SetSize(MODAL_WIDTH, MODAL_HEIGHT)
    modal:SetPoint('CENTER', UIParent, 'CENTER', 0, 80)
    modal:SetFrameStrata('DIALOG')
    modal:SetFrameLevel(100)
    modal:EnableMouse(true)
    modal:SetClipsChildren(false)
    modal:SetBackdrop({
      bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
      tile = true,
      tileSize = 32,
    })
    modal:SetBackdropColor(0.05, 0.05, 0.05, 0.97)

    modal.border = CreateFrame('Frame', nil, modal, 'BackdropTemplate')
    modal.border:SetFrameLevel(modal:GetFrameLevel() + 10)
    modal.border:EnableMouse(false)
    modal.border:SetPoint('TOPLEFT', modal, 'TOPLEFT', -BORDER_OUTSET, BORDER_OUTSET)
    modal.border:SetPoint('BOTTOMRIGHT', modal, 'BOTTOMRIGHT', BORDER_OUTSET, -BORDER_OUTSET)
    modal.border:SetBackdrop({
      edgeFile = BORDER_TEXTURE,
      tile = true,
      tileSize = BORDER_EDGE_SIZE,
      edgeSize = BORDER_EDGE_SIZE,
      insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    modal.border:SetBackdropBorderColor(1, 1, 1, 1)

    modal.headerBar = CreateFrame('Frame', nil, modal, 'BackdropTemplate')
    modal.headerBar:SetPoint('TOPLEFT', modal, 'TOPLEFT', 0, 0)
    modal.headerBar:SetPoint('TOPRIGHT', modal, 'TOPRIGHT', 0, 0)
    modal.headerBar:SetHeight(HEADER_HEIGHT)
    modal.headerBar:SetBackdropColor(0, 0, 0, 0.95)

    modal.headerBackground = modal.headerBar:CreateTexture(nil, 'BACKGROUND')
    modal.headerBackground:SetAllPoints()
    modal.headerBackground:SetTexture(TEXTURE_PATH .. '\\header.png')
    modal.headerBackground:SetTexCoord(0, 1, 0, 1)

    modal.headerTitle = modal.headerBar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightHuge')
    modal.headerTitle:SetPoint('CENTER', modal.headerBar, 'CENTER', 0, 2)
    modal.headerTitle:SetText('Level Cap Reached')
    setTextColor(modal.headerTitle, SECTION_COLOR)

    modal.dividerFrame = CreateFrame('Frame', nil, modal)
    modal.dividerFrame:SetSize(MODAL_WIDTH + 10, 16)
    modal.dividerFrame:SetPoint('BOTTOM', modal.headerBar, 'BOTTOM', 0, -8)
    modal.dividerFrame:SetFrameLevel(modal:GetFrameLevel() + 5)

    modal.divider = modal.dividerFrame:CreateTexture(nil, 'ARTWORK')
    modal.divider:SetAllPoints()
    modal.divider:SetTexture(TEXTURE_PATH .. '\\divider.png')
    modal.divider:SetTexCoord(0, 1, 0, 1)

    modal.titleText = modal:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    modal.titleText:SetPoint('TOP', modal.dividerFrame, 'BOTTOM', 0, -CONTENT_TOP_PADDING)
    modal.titleText:SetPoint('LEFT', modal, 'LEFT', CONTENT_HORIZONTAL_INSET, 0)
    modal.titleText:SetPoint('RIGHT', modal, 'RIGHT', -CONTENT_HORIZONTAL_INSET, 0)
    modal.titleText:SetWordWrap(true)
    modal.titleText:SetJustifyH('CENTER')
    modal.titleText:SetSpacing(2)
    modal.titleText:SetText(TITLE_TEXT)
    setTextColor(modal.titleText, TITLE_COLOR)

    modal.subtitleText = modal:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    modal.subtitleText:SetPoint('TOP', modal.titleText, 'BOTTOM', 0, -10)
    modal.subtitleText:SetPoint('LEFT', modal, 'LEFT', CONTENT_HORIZONTAL_INSET, 0)
    modal.subtitleText:SetPoint('RIGHT', modal, 'RIGHT', -CONTENT_HORIZONTAL_INSET, 0)
    modal.subtitleText:SetWordWrap(true)
    modal.subtitleText:SetJustifyH('CENTER')
    modal.subtitleText:SetSpacing(2)
    modal.subtitleText:SetText(SUBTITLE_TEXT)
    setTextColor(modal.subtitleText, SUBTITLE_COLOR)

    modal.subsubtitleText = modal:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    modal.subsubtitleText:SetPoint('TOP', modal.subtitleText, 'BOTTOM', 0, -6)
    modal.subsubtitleText:SetPoint('LEFT', modal, 'LEFT', CONTENT_HORIZONTAL_INSET, 0)
    modal.subsubtitleText:SetPoint('RIGHT', modal, 'RIGHT', -CONTENT_HORIZONTAL_INSET, 0)
    modal.subsubtitleText:SetWordWrap(true)
    modal.subsubtitleText:SetJustifyH('CENTER')
    modal.subsubtitleText:SetSpacing(2)
    modal.subsubtitleText:SetText(SUBSUBTITLE_TEXT)
    setTextColor(modal.subsubtitleText, SUBTITLE_COLOR)

    modal.sectionTitle = modal:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    modal.sectionTitle:SetPoint('TOP', modal.subsubtitleText, 'BOTTOM', 0, -18)
    modal.sectionTitle:SetPoint('LEFT', modal, 'LEFT', CONTENT_HORIZONTAL_INSET, 0)
    modal.sectionTitle:SetText(SECTION_TITLE_TEXT)
    setTextColor(modal.sectionTitle, SECTION_COLOR)

    modal.scheduleRows = {}
    local previousAnchor = modal.sectionTitle
    local firstRowOffset = -10
    local rowGap = -6

    for index, entry in ipairs(SCHEDULE_ENTRIES) do
      local bullet = modal:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
      bullet:SetPoint('TOPLEFT', previousAnchor, 'BOTTOMLEFT', 0, index == 1 and firstRowOffset or rowGap)
      bullet:SetText('•')
      setTextColor(bullet, BULLET_COLOR)

      local row = modal:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
      row:SetPoint('TOP', bullet, 'TOP', 0, 0)
      row:SetPoint('LEFT', bullet, 'RIGHT', 6, 0)
      row:SetPoint('RIGHT', modal, 'RIGHT', -CONTENT_HORIZONTAL_INSET, 0)
      row:SetWordWrap(true)
      row:SetJustifyH('LEFT')
      row:SetText(formatScheduleLine(entry))
      setTextColor(row, SCHEDULE_BODY_COLOR)

      modal.scheduleRows[index] = { bullet = bullet, row = row }
      previousAnchor = row
    end

    modal.confirmButton = CreateFrame('Button', nil, modal, 'UIPanelButtonTemplate')
    modal.confirmButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    modal.confirmButton:SetPoint('BOTTOM', 0, BUTTON_BOTTOM_MARGIN)
    modal.confirmButton:SetText('I understand')
    modal.confirmButton:SetScript('OnClick', function()
      if pendingBracketLevel and FreshSoD_AcknowledgeLevelBracket then
        FreshSoD_AcknowledgeLevelBracket(pendingBracketLevel)
      end
      hideModal()
    end)
  end

  updateScheduleHighlights(bracketLevel)
  modal:Show()
end

function FreshSoD_HideLevelBracketModal()
  hideModal()
end
