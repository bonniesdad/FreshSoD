local addonName = ...

local announcementFrame
local announcementQueue = {}
local isShowingAnnouncement = false
local announcementBatchCounter = 0

local DISPLAY_DURATION = 10
local FADE_DURATION = 1
local MULTIPLIER_JIGGLE_AMPLITUDE_MAX = 2.5
local MULTIPLIER_JIGGLE_SPEED = 10
local MULTIPLIER_TITLE_GAP = 6
local FRAME_WIDTH = 360
local TOP_OFFSET = -50
local HEADER_HEIGHT = 34
local CONTENT_HORIZONTAL_INSET = 14
local CONTENT_TOP_GAP = 6
local CONTENT_BOTTOM_PADDING = 8
local BORDER_TEXTURE = 'Interface\\DialogFrame\\UI-DialogBox-Border'
local BORDER_EDGE_SIZE = 32
local BORDER_OUTSET = 10
local PANEL_BACKGROUND_ALPHA = 0.5
local HEADER_BACKGROUND_ALPHA = 0.55
local BORDER_ALPHA = 0.7
local DIVIDER_ALPHA = 0.55

local TITLE_COLOR = { 0.92, 0.22, 0.18 }
local BORDER_COLOR = { 0.78, 0.48, 0.12 }
local BODY_COLOR = { 0.9, 0.88, 0.84 }
local TAX_COLOR = { 1, 0.82, 0 }

local DEATH_TAX_SOUNDS = {
  'Interface\\AddOns\\' .. addonName .. '\\Audio\\Sunglitters\\Omg.mp3',
  'Interface\\AddOns\\' .. addonName .. '\\Audio\\Sunglitters\\Oh Slay.mp3',
  'Interface\\AddOns\\' .. addonName .. '\\Audio\\Sunglitters\\Oh GODDH.mp3',
  'Interface\\AddOns\\' .. addonName .. '\\Audio\\Sunglitters\\Ohh my god.mp3',
}

local function colorCode(color)
  return string.format('|cff%02x%02x%02x', color[1] * 255, color[2] * 255, color[3] * 255)
end

local function formatTaxAmount(taxCopper)
  local gold = math.floor(taxCopper / 10000)
  local silver = math.floor((taxCopper % 10000) / 100)
  local copper = taxCopper % 100
  local parts = {}

  if gold > 0 then
    table.insert(parts, string.format('%dg', gold))
  end
  if silver > 0 then
    table.insert(parts, string.format('%ds', silver))
  end
  if copper > 0 then
    table.insert(parts, string.format('%dc', copper))
  end

  if #parts == 0 then
    return '0c'
  end

  return table.concat(parts, ' ')
end

local function buildAnnouncementMessage(playerName, taxCopper)
  return string.format(
    '%s%s|r%s has died, they owe %s%s|r%s in death tax.|r',
    colorCode(BODY_COLOR),
    playerName,
    colorCode(BODY_COLOR),
    colorCode(TAX_COLOR),
    formatTaxAmount(taxCopper),
    colorCode(BODY_COLOR)
  )
end

local function playDeathTaxSound()
  PlaySoundFile(DEATH_TAX_SOUNDS[math.random(#DEATH_TAX_SOUNDS)], 'Dialog')
end

local function ensureAnnouncementFrame()
  if announcementFrame then
    return
  end

  announcementFrame = CreateFrame('Frame', 'FreshSoDDeathTaxAnnouncement', UIParent, 'BackdropTemplate')
  announcementFrame:SetSize(FRAME_WIDTH, 1)
  announcementFrame:SetPoint('TOP', UIParent, 'TOP', 0, TOP_OFFSET)
  announcementFrame:SetFrameStrata('HIGH')
  announcementFrame:SetFrameLevel(100)
  announcementFrame:SetClipsChildren(false)
  announcementFrame:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
    tile = true,
    tileSize = 32,
  })
  announcementFrame:SetBackdropColor(0.08, 0.03, 0.03, PANEL_BACKGROUND_ALPHA)

  announcementFrame.border = CreateFrame('Frame', nil, announcementFrame, 'BackdropTemplate')
  announcementFrame.border:SetFrameLevel(announcementFrame:GetFrameLevel() + 10)
  announcementFrame.border:EnableMouse(false)
  announcementFrame.border:SetPoint('TOPLEFT', announcementFrame, 'TOPLEFT', -BORDER_OUTSET, BORDER_OUTSET)
  announcementFrame.border:SetPoint('BOTTOMRIGHT', announcementFrame, 'BOTTOMRIGHT', BORDER_OUTSET, -BORDER_OUTSET)
  announcementFrame.border:SetBackdrop({
    edgeFile = BORDER_TEXTURE,
    tile = true,
    tileSize = BORDER_EDGE_SIZE,
    edgeSize = BORDER_EDGE_SIZE,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  announcementFrame.border:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_ALPHA)

  announcementFrame.headerBar = CreateFrame('Frame', nil, announcementFrame, 'BackdropTemplate')
  announcementFrame.headerBar:SetPoint('TOPLEFT', announcementFrame, 'TOPLEFT', 0, 0)
  announcementFrame.headerBar:SetPoint('TOPRIGHT', announcementFrame, 'TOPRIGHT', 0, 0)
  announcementFrame.headerBar:SetHeight(HEADER_HEIGHT)
  announcementFrame.headerBar:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    tile = true,
    tileSize = 8,
  })
  announcementFrame.headerBar:SetBackdropColor(0.18, 0.05, 0.05, HEADER_BACKGROUND_ALPHA)

  announcementFrame.headerTitle = announcementFrame.headerBar:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  announcementFrame.headerTitle:SetPoint('CENTER', announcementFrame.headerBar, 'CENTER', 0, 1)
  announcementFrame.headerTitle:SetText('DEATH TAX')
  announcementFrame.headerTitle:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])

  announcementFrame.divider = announcementFrame:CreateTexture(nil, 'ARTWORK')
  announcementFrame.divider:SetPoint('TOPLEFT', announcementFrame.headerBar, 'BOTTOMLEFT', 0, 0)
  announcementFrame.divider:SetPoint('TOPRIGHT', announcementFrame.headerBar, 'BOTTOMRIGHT', 0, 0)
  announcementFrame.divider:SetHeight(1)
  announcementFrame.divider:SetColorTexture(0.45, 0.18, 0.12, DIVIDER_ALPHA)

  announcementFrame.text = announcementFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  announcementFrame.text:SetPoint('TOPLEFT', announcementFrame.divider, 'BOTTOMLEFT', CONTENT_HORIZONTAL_INSET, -CONTENT_TOP_GAP)
  announcementFrame.text:SetPoint('TOPRIGHT', announcementFrame.divider, 'BOTTOMRIGHT', -CONTENT_HORIZONTAL_INSET, -CONTENT_TOP_GAP)
  announcementFrame.text:SetWidth(FRAME_WIDTH - (CONTENT_HORIZONTAL_INSET * 2))
  announcementFrame.text:SetWordWrap(true)
  announcementFrame.text:SetJustifyH('CENTER')
  announcementFrame.text:SetSpacing(2)

  announcementFrame.multiplier = announcementFrame.headerBar:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  announcementFrame.multiplier:SetPoint('LEFT', announcementFrame.headerTitle, 'RIGHT', MULTIPLIER_TITLE_GAP, 0)
  announcementFrame.multiplier:SetTextColor(TAX_COLOR[1], TAX_COLOR[2], TAX_COLOR[3])
  announcementFrame.multiplier:Hide()
end

local function getNextQueuePosition()
  if not isShowingAnnouncement and #announcementQueue == 0 then
    announcementBatchCounter = 1
    return 1
  end

  announcementBatchCounter = announcementBatchCounter + 1
  return announcementBatchCounter
end

local function getMultiplierJiggleAmplitude(queuePosition)
  if queuePosition <= 2 then
    return 0
  elseif queuePosition == 3 then
    return 0.8
  elseif queuePosition == 4 then
    return 1.6
  end

  return MULTIPLIER_JIGGLE_AMPLITUDE_MAX
end

local function updateQueueMultiplier(queuePosition)
  if queuePosition > 1 then
    announcementFrame.multiplier:SetText('x' .. queuePosition)
    announcementFrame.multiplier:Show()
    announcementFrame.multiplierJiggleTime = 0
    announcementFrame.multiplierJiggleAmplitude = getMultiplierJiggleAmplitude(queuePosition)
    announcementFrame.multiplier:SetPoint('LEFT', announcementFrame.headerTitle, 'RIGHT', MULTIPLIER_TITLE_GAP, 0)
  else
    announcementFrame.multiplier:Hide()
    announcementFrame.multiplierJiggleAmplitude = 0
  end
end

local function processAnnouncementQueue()
  if isShowingAnnouncement or #announcementQueue == 0 then
    return
  end

  local nextAnnouncement = table.remove(announcementQueue, 1)
  local playerName = nextAnnouncement.playerName
  local taxCopper = nextAnnouncement.taxCopper
  local queuePosition = nextAnnouncement.queuePosition

  ensureAnnouncementFrame()

  isShowingAnnouncement = true
  playDeathTaxSound()
  updateQueueMultiplier(queuePosition)
  announcementFrame.text:SetText(buildAnnouncementMessage(playerName, taxCopper))
  local textHeight = announcementFrame.text:GetStringHeight()
  announcementFrame:SetHeight(
    HEADER_HEIGHT + 1 + CONTENT_TOP_GAP + textHeight + CONTENT_BOTTOM_PADDING
  )
  announcementFrame:SetAlpha(1)
  announcementFrame:Show()
  announcementFrame.fadeTimer = DISPLAY_DURATION

  announcementFrame:SetScript('OnUpdate', function(self, elapsed)
    self.fadeTimer = self.fadeTimer - elapsed
    if self.fadeTimer <= FADE_DURATION then
      self:SetAlpha(math.max(self.fadeTimer / FADE_DURATION, 0))
    end
    if self.multiplier:IsShown() and (self.multiplierJiggleAmplitude or 0) > 0 then
      self.multiplierJiggleTime = (self.multiplierJiggleTime or 0) + elapsed
      local amplitude = self.multiplierJiggleAmplitude
      local wiggleX = math.sin(self.multiplierJiggleTime * MULTIPLIER_JIGGLE_SPEED) * amplitude
      local wiggleY = math.cos(self.multiplierJiggleTime * MULTIPLIER_JIGGLE_SPEED * 1.3) * amplitude * 0.6
      self.multiplier:SetPoint(
        'LEFT',
        self.headerTitle,
        'RIGHT',
        MULTIPLIER_TITLE_GAP + wiggleX,
        wiggleY
      )
    end
    if self.fadeTimer <= 0 then
      self:SetScript('OnUpdate', nil)
      self:Hide()
      self.multiplier:Hide()
      isShowingAnnouncement = false
      if #announcementQueue == 0 then
        announcementBatchCounter = 0
      end
      processAnnouncementQueue()
    end
  end)
end

function FreshSoD_ShowDeathTaxAnnouncement(playerName, taxCopper)
  table.insert(announcementQueue, {
    playerName = playerName,
    taxCopper = taxCopper,
    queuePosition = getNextQueuePosition(),
  })
  processAnnouncementQueue()
end

local sunglittersFrame = CreateFrame('Frame')

sunglittersFrame:RegisterEvent('PLAYER_DEAD')

sunglittersFrame:SetScript('OnEvent', function(self, event, ...)
  if event == 'PLAYER_DEAD' then
    if not FreshSoD_IsDeathTaxGuild() then
      return
    end

    local copperCoins = GetMoney()
    local tax = math.floor(copperCoins * 0.10)
    local playerName = UnitName('player') or 'You'

    FreshSoD_AddDeathTaxOwedCopper(tax)
    FreshSoD_SendDeathTaxAddonMessage(playerName, tax)
    FreshSoD_ShowDeathTaxAnnouncement(playerName, tax)
  end
end)
