local CONTENT_TOP_OFFSET = -50
local LIST_LEFT_OFFSET = 10
local SEARCH_HEIGHT = 24
local SEARCH_BOTTOM_GAP = 4
local TABLE_TOP_GAP = 9
local FILTER_SEARCH_GAP = 6
local FILTER_DROPDOWN_WIDTH = 70
local FILTER_COLUMN_WIDTH = FILTER_DROPDOWN_WIDTH + 26
local HEADER_BOTTOM_GAP = 4
local STATUS_COLUMN_WIDTH = 52
local ROW_HEIGHT = 13
local ROWS_PER_PAGE = 15
local SEARCH_MIN_CHARS = 3
local STATUS_COLUMN_OFFSET = 180
local FILTER_COLUMN_OFFSET = STATUS_COLUMN_OFFSET - 20
local ACTION_COLUMN_OFFSET = 238
local REFRESH_BUTTON_SIZE = 16
local PAGINATION_HEIGHT = 24
local PAGINATION_BOTTOM_MARGIN = -2
local PAGINATION_BUTTON_WIDTH = 64
local PAGINATION_BUTTON_GAP = 6

local SEARCH_HELPER_TEXT = 'Search members (3+ characters)'
local REFRESH_ICON = 'Interface\\Buttons\\UI-RefreshButton'
local REFRESH_TOOLTIP_TEXT = 'This will re-validate the player'
local REQUEST_STATUS_TOOLTIP_TEXT = 'Click to request a status update'

local FILTER_OPTIONS = {
  { key = 'all', label = 'All' },
  { key = 'valid', label = 'Valid' },
  { key = 'invalid', label = 'Invalid' },
  { key = 'unknown', label = 'Unknown' },
}

local STATUS_DISPLAY = {
  valid = { text = 'Valid', r = 0.35, g = 0.8, b = 0.35 },
  invalid = { text = 'Invalid', r = 0.82, g = 0.33, b = 0.33 },
  unknown = { text = 'Unknown', r = 0.95, g = 0.82, b = 0.25 },
}

local FILTER_ALL_COLOR = { r = 0.85, g = 0.85, b = 0.85 }

local function getFilterColor(filterKey)
  if filterKey == 'all' then
    return FILTER_ALL_COLOR.r, FILTER_ALL_COLOR.g, FILTER_ALL_COLOR.b
  end

  local display = STATUS_DISPLAY[filterKey]
  if display then
    return display.r, display.g, display.b
  end

  return 1, 1, 1
end

local function getFilterColorCode(filterKey)
  local r, g, b = getFilterColor(filterKey)
  return string.format('|cff%02x%02x%02x', r * 255, g * 255, b * 255)
end

local function getFilterLabel(filterKey)
  for _, option in ipairs(FILTER_OPTIONS) do
    if option.key == filterKey then
      return option.label
    end
  end

  return 'All'
end

local function getFilterColoredText(filterKey)
  return getFilterColorCode(filterKey) .. getFilterLabel(filterKey) .. '|r'
end

local SEARCH_DEBOUNCE_SECONDS = 0.2

local updateGuildBoardTabDisplay
local refreshGuildBoardTable
local scheduleGuildBoardRefresh

local function wipeArray(array)
  for index = #array, 1, -1 do
    array[index] = nil
  end
end

local function buildGuildStatusLookup(guildName)
  local lookup = {}
  FreshSoD_EnsureGuildVerificationDB()

  local guildData = FRESH_SOD_DB.guildVerificationStatus[guildName]
  if not guildData then
    return lookup
  end

  for storedName, status in pairs(guildData) do
    lookup[string.lower(Ambiguate(storedName, 'short'))] = status
  end

  return lookup
end

local function getStatusKeyFromStoredStatus(storedStatus)
  if storedStatus == true then
    return 'valid'
  end
  if storedStatus == false then
    return 'invalid'
  end
  return 'unknown'
end

local function getSearchText(content)
  local searchText = content.searchInput:GetText()
  if searchText then
    searchText = searchText:match('^%s*(.-)%s*$')
  end
  return searchText or ''
end

local function rebuildGuildBoardMemberCache(content, skipRosterRefresh)
  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    content.guildBoardMemberData = nil
    content.guildBoardMembersByStatus = nil
    content.guildBoardGuildName = nil
    content.guildBoardShowOfficerActions = false
    return
  end

  if FreshSoD_UpdateBuffVerification then
    FreshSoD_UpdateBuffVerification()
  end

  local members = FreshSoD_GetGuildMemberNames(true, skipRosterRefresh)
  local memberData = {}
  local membersByStatus = {
    all = memberData,
    valid = {},
    invalid = {},
    unknown = {},
  }
  local statusLookup = buildGuildStatusLookup(guildName)
  local playerShortName = string.lower(Ambiguate(UnitName('player'), 'short'))
  local playerVerified = FreshSoD_AmIVerified()

  for _, memberName in ipairs(members) do
    local lowerName = string.lower(memberName)
    local statusKey
    local isSelf = lowerName == playerShortName

    if isSelf then
      statusKey = getStatusKeyFromStoredStatus(playerVerified)
    else
      statusKey = getStatusKeyFromStoredStatus(statusLookup[lowerName])
    end

    local entry = {
      name = memberName,
      lowerName = lowerName,
      statusKey = statusKey,
      isSelf = isSelf,
    }

    memberData[#memberData + 1] = entry
    membersByStatus[statusKey][#membersByStatus[statusKey] + 1] = entry
  end

  content.guildBoardMemberData = memberData
  content.guildBoardMembersByStatus = membersByStatus
  content.guildBoardGuildName = guildName
  content.guildBoardShowOfficerActions = FreshSoD_AmITopGuildRank()
end

local function moveEntryBetweenStatusBuckets(membersByStatus, entry, oldKey, newKey)
  if oldKey == newKey then
    return
  end

  local oldBucket = membersByStatus[oldKey]
  for index = #oldBucket, 1, -1 do
    if oldBucket[index] == entry then
      table.remove(oldBucket, index)
      break
    end
  end

  local newBucket = membersByStatus[newKey]
  newBucket[#newBucket + 1] = entry
  entry.statusKey = newKey
end

local function updateCachedMemberVerificationStatus(content, lowerName, isVerified)
  local memberData = content.guildBoardMemberData
  local membersByStatus = content.guildBoardMembersByStatus
  if not memberData or not membersByStatus then
    return false
  end

  local newKey = getStatusKeyFromStoredStatus(isVerified)
  for _, entry in ipairs(memberData) do
    if entry.lowerName == lowerName then
      moveEntryBetweenStatusBuckets(membersByStatus, entry, entry.statusKey, newKey)
      return true
    end
  end

  return false
end

function FreshSoD_TrackGuildBoardStatusRequest(content, memberName)
  if not content or not memberName then
    return
  end

  content.guildBoardPendingStatusRequests = content.guildBoardPendingStatusRequests or {}
  content.guildBoardPendingStatusRequests[string.lower(Ambiguate(memberName, 'short'))] = true
end

function FreshSoD_OnGuildMemberVerificationUpdated(sender, isVerified)
  local content = FreshSoD_GetTabContent and FreshSoD_GetTabContent(2)
  if not content or not content.guildBoardInitialized or not content:IsShown() then
    return
  end

  local shortName = string.lower(Ambiguate(sender, 'short'))
  local pending = content.guildBoardPendingStatusRequests
  if not pending or not pending[shortName] then
    return
  end

  pending[shortName] = nil
  if updateCachedMemberVerificationStatus(content, shortName, isVerified) then
    scheduleGuildBoardRefresh(content, 0)
  end
end

local function ensureGuildBoardMemberCache(content, skipRosterRefresh)
  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    content.guildBoardMemberData = nil
    content.guildBoardGuildName = nil
    return
  end

  if not content.guildBoardMemberData or content.guildBoardGuildName ~= guildName then
    rebuildGuildBoardMemberCache(content, skipRosterRefresh)
  end
end

local function getFilteredMembers(content, searchText, statusFilter)
  local memberData = content.guildBoardMemberData or {}
  local membersByStatus = content.guildBoardMembersByStatus
  local query = #searchText >= SEARCH_MIN_CHARS and string.lower(searchText) or nil

  if not query then
    if statusFilter == 'all' then
      return memberData
    end

    return membersByStatus and membersByStatus[statusFilter] or {}
  end

  local source = statusFilter == 'all' and memberData or (membersByStatus and membersByStatus[statusFilter] or {})
  local filtered = content.guildBoardFilteredScratch
  if not filtered then
    filtered = {}
    content.guildBoardFilteredScratch = filtered
  end

  wipeArray(filtered)
  for index = 1, #source do
    local entry = source[index]
    if string.find(entry.lowerName, query, 1, true) then
      filtered[#filtered + 1] = entry
    end
  end

  return filtered
end

scheduleGuildBoardRefresh = function(content, delay)
  if content.guildBoardRefreshTimer then
    content.guildBoardRefreshTimer:Cancel()
  end

  if C_Timer and C_Timer.NewTimer then
    content.guildBoardRefreshTimer = C_Timer.NewTimer(delay or 0, function()
      content.guildBoardRefreshTimer = nil
      if content:IsShown() then
        refreshGuildBoardTable(content)
      end
    end)
    return
  end

  refreshGuildBoardTable(content)
end

local function createClickableRow(parent, tooltipText)
  local button = CreateFrame('Button', nil, parent)
  button:SetHeight(ROW_HEIGHT)

  local label = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  label:SetPoint('LEFT', button, 'LEFT', 0, 0)
  label:SetJustifyH('LEFT')
  button.label = label

  if tooltipText then
    button:SetScript('OnEnter', function(self)
      GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
      GameTooltip:SetText(tooltipText)
      GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function()
      GameTooltip:Hide()
    end)
  end

  return button
end

local function setFilterDropdownHeight(dropdown, height)
  dropdown:SetHeight(height)

  local buttonName = dropdown:GetName() .. 'Button'
  local button = _G[buttonName]
  if not button then
    return
  end

  button:SetHeight(height)

  local left = _G[buttonName .. 'Left']
  local middle = _G[buttonName .. 'Middle']
  local right = _G[buttonName .. 'Right']
  if left then
    left:SetHeight(height)
  end
  if middle then
    middle:SetHeight(height)
  end
  if right then
    right:SetHeight(height)
  end
end

local function updateStatusFilterDropdown(content)
  local activeFilter = content.guildBoardStatusFilter or 'all'
  UIDropDownMenu_SetSelectedValue(content.statusFilterDropdown, activeFilter)
  UIDropDownMenu_SetText(content.statusFilterDropdown, getFilterColoredText(activeFilter))
end

local function initializeStatusFilterDropdown(content)
  UIDropDownMenu_SetWidth(content.statusFilterDropdown, FILTER_DROPDOWN_WIDTH)
  setFilterDropdownHeight(content.statusFilterDropdown, SEARCH_HEIGHT)
  UIDropDownMenu_Initialize(content.statusFilterDropdown, function(_, level)
    local info = UIDropDownMenu_CreateInfo()
    for _, option in ipairs(FILTER_OPTIONS) do
      info = UIDropDownMenu_CreateInfo()
      info.text = option.label
      info.colorCode = getFilterColorCode(option.key)
      info.arg1 = option.key
      info.func = function(_, filterKey)
        content.guildBoardStatusFilter = filterKey
        content.guildBoardCurrentPage = 1
        UIDropDownMenu_SetSelectedValue(content.statusFilterDropdown, filterKey)
        UIDropDownMenu_SetText(content.statusFilterDropdown, getFilterColoredText(filterKey))
        scheduleGuildBoardRefresh(content, 0)
      end
      info.checked = (content.guildBoardStatusFilter or 'all') == option.key
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  updateStatusFilterDropdown(content)
end

local function createRefreshButton(parent)
  local button = CreateFrame('Button', nil, parent)
  button:SetSize(REFRESH_BUTTON_SIZE, REFRESH_BUTTON_SIZE)

  local normal = button:CreateTexture(nil, 'ARTWORK')
  normal:SetAllPoints()
  normal:SetTexture(REFRESH_ICON)

  local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
  highlight:SetAllPoints()
  highlight:SetTexture(REFRESH_ICON)
  highlight:SetBlendMode('ADD')
  highlight:SetAlpha(0.4)

  button:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText(REFRESH_TOOLTIP_TEXT)
    GameTooltip:Show()
  end)
  button:SetScript('OnLeave', function()
    GameTooltip:Hide()
  end)

  return button
end

local function getPageSlice(filteredMembers, page)
  local totalPages = math.max(1, math.ceil(#filteredMembers / ROWS_PER_PAGE))
  page = math.max(1, math.min(page, totalPages))
  local startIndex = (page - 1) * ROWS_PER_PAGE + 1
  return startIndex, totalPages, page
end

local function setStatusFilterVisibility(content, visible)
  if visible then
    content.statusFilterDropdown:Show()
  else
    content.statusFilterDropdown:Hide()
    if CloseDropDownMenus then
      CloseDropDownMenus()
    end
  end
end

local function setMembersUiVisible(content, visible)
  if content.guildBoardMembersUiVisible == visible then
    return
  end

  content.guildBoardMembersUiVisible = visible

  if visible then
    content.searchHelperLabel:Show()
    content.searchInput:Show()
    setStatusFilterVisibility(content, true)
    content.headerName:Show()
    content.headerStatus:Show()
    content.tableContainer:Show()
    content.prevButton:Show()
    content.nextButton:Show()
    content.pageLabel:Show()
    content.emptyLabel:Hide()
    return
  end

  content.searchHelperLabel:Hide()
  content.searchInput:Hide()
  setStatusFilterVisibility(content, false)
  content.headerName:Hide()
  content.headerStatus:Hide()
  content.tableContainer:Hide()
  content.prevButton:Hide()
  content.nextButton:Hide()
  content.pageLabel:Hide()
end

local function updateMemberRow(nameRow, statusRow, resetButton, entry, showOfficerActions)
  if not entry then
    if nameRow:IsShown() then
      nameRow:Hide()
    end
    if statusRow:IsShown() then
      statusRow:Hide()
    end
    statusRow.memberName = nil
    if resetButton:IsShown() then
      resetButton:Hide()
    end
    resetButton.memberName = nil
    return
  end

  if nameRow.guildBoardEntry ~= entry then
    nameRow:SetText(entry.name)
    nameRow.guildBoardEntry = entry
  end
  if not nameRow:IsShown() then
    nameRow:Show()
  end

  local status = STATUS_DISPLAY[entry.statusKey] or STATUS_DISPLAY.unknown
  local statusMemberName = entry.isSelf and nil or entry.name
  if statusRow.memberName ~= statusMemberName then
    statusRow.memberName = statusMemberName
  end
  if statusRow.guildBoardStatusKey ~= entry.statusKey then
    statusRow.label:SetText(status.text)
    statusRow.label:SetTextColor(status.r, status.g, status.b)
    statusRow.guildBoardStatusKey = entry.statusKey
  end
  if not statusRow:IsShown() then
    statusRow:Show()
  end

  local showReset = showOfficerActions and entry.statusKey == 'invalid' and not entry.isSelf
  local resetMemberName = showReset and entry.name or nil
  if resetButton.memberName ~= resetMemberName then
    resetButton.memberName = resetMemberName
    if showReset then
      resetButton:Show()
    else
      resetButton:Hide()
    end
  elseif showReset and not resetButton:IsShown() then
    resetButton:Show()
  elseif not showReset and resetButton:IsShown() then
    resetButton:Hide()
  end
end

local function updateGuildBoardLayout(content)
  local contentWidth = content:GetWidth()
  if content.guildBoardLayoutWidth == contentWidth then
    return
  end

  content.guildBoardLayoutWidth = contentWidth
  local rowWidth = contentWidth - (LIST_LEFT_OFFSET * 2)
  local searchWidth = FILTER_COLUMN_OFFSET - FILTER_SEARCH_GAP
  if rowWidth < 1 then
    rowWidth = 1
  end
  if searchWidth < 1 then
    searchWidth = 1
  end

  content.searchHelperLabel:ClearAllPoints()
  content.searchHelperLabel:SetPoint('TOPLEFT', content, 'TOPLEFT', LIST_LEFT_OFFSET, CONTENT_TOP_OFFSET)
  content.searchHelperLabel:SetWidth(rowWidth)
  content.searchHelperLabel:SetWordWrap(true)
  content.searchHelperLabel:SetJustifyH('LEFT')
  content.searchHelperLabel:SetJustifyV('TOP')

  content.searchInput:SetSize(searchWidth, SEARCH_HEIGHT)
  content.searchInput:ClearAllPoints()
  content.searchInput:SetPoint('TOPLEFT', content.searchHelperLabel, 'BOTTOMLEFT', 0, -SEARCH_BOTTOM_GAP)

  content.statusFilterDropdown:ClearAllPoints()
  content.statusFilterDropdown:SetPoint('TOPLEFT', content.searchInput, 'TOPLEFT', FILTER_COLUMN_OFFSET, 0)
  setFilterDropdownHeight(content.statusFilterDropdown, SEARCH_HEIGHT)

  content.headerName:ClearAllPoints()
  content.headerName:SetPoint('TOPLEFT', content.searchInput, 'BOTTOMLEFT', 0, -TABLE_TOP_GAP)

  content.headerStatus:ClearAllPoints()
  content.headerStatus:SetPoint('LEFT', content.headerName, 'LEFT', STATUS_COLUMN_OFFSET, 0)

  content.prevButton:SetSize(PAGINATION_BUTTON_WIDTH, PAGINATION_HEIGHT)
  content.nextButton:SetSize(PAGINATION_BUTTON_WIDTH, PAGINATION_HEIGHT)
  content.prevButton:ClearAllPoints()
  content.nextButton:ClearAllPoints()
  content.prevButton:SetPoint('BOTTOMLEFT', content, 'BOTTOMLEFT', LIST_LEFT_OFFSET, PAGINATION_BOTTOM_MARGIN)
  content.nextButton:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -LIST_LEFT_OFFSET, PAGINATION_BOTTOM_MARGIN)

  content.pageLabel:ClearAllPoints()
  content.pageLabel:SetPoint('CENTER', content, 'BOTTOM', 0, PAGINATION_BOTTOM_MARGIN + (PAGINATION_HEIGHT / 2))

  content.tableContainer:ClearAllPoints()
  content.tableContainer:SetPoint('TOPLEFT', content.headerName, 'BOTTOMLEFT', 0, -HEADER_BOTTOM_GAP)
  content.tableContainer:SetPoint('BOTTOMLEFT', content.prevButton, 'TOPLEFT', 0, 6)
  content.tableContainer:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -LIST_LEFT_OFFSET, PAGINATION_HEIGHT + PAGINATION_BOTTOM_MARGIN + 6)
  content.tableContainer:SetClipsChildren(true)

  for index = 1, ROWS_PER_PAGE do
    local nameRow = content.memberNameRows[index]
    local statusRow = content.memberStatusRows[index]
    local resetButton = content.memberResetButtons and content.memberResetButtons[index]

    nameRow:ClearAllPoints()
    nameRow:SetPoint('TOPLEFT', content.tableContainer, 'TOPLEFT', 0, -((index - 1) * ROW_HEIGHT))
    nameRow:SetHeight(ROW_HEIGHT)

    statusRow:SetSize(STATUS_COLUMN_WIDTH, ROW_HEIGHT)
    statusRow:ClearAllPoints()
    statusRow:SetPoint('LEFT', nameRow, 'LEFT', STATUS_COLUMN_OFFSET, 0)

    if resetButton then
      resetButton:ClearAllPoints()
      resetButton:SetPoint('LEFT', nameRow, 'LEFT', ACTION_COLUMN_OFFSET, 0)
      resetButton:SetSize(REFRESH_BUTTON_SIZE, REFRESH_BUTTON_SIZE)
    end
  end
end

local function ensureGuildBoardTabLayout(content)
  if content.guildBoardInitialized then
    return
  end

  content.guildBoardCurrentPage = 1
  content.guildBoardStatusFilter = 'all'

  content.searchHelperLabel = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  content.searchHelperLabel:SetText(SEARCH_HELPER_TEXT)
  content.searchHelperLabel:SetTextColor(0.85, 0.85, 0.85)

  content.searchInput = CreateFrame('EditBox', nil, content, 'InputBoxTemplate')
  content.searchInput:SetAutoFocus(false)
  content.searchInput:SetMaxLetters(50)
  content.searchInput:SetScript('OnTextChanged', function()
    content.guildBoardCurrentPage = 1
    scheduleGuildBoardRefresh(content, SEARCH_DEBOUNCE_SECONDS)
  end)

  content.statusFilterDropdown = CreateFrame('Frame', 'FreshSoDGuildBoardStatusFilterDropdown', content, 'UIDropDownMenuTemplate')
  initializeStatusFilterDropdown(content)

  content.headerName = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  content.headerName:SetText('Member')
  content.headerName:SetTextColor(0.75, 0.75, 0.75)

  content.headerStatus = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  content.headerStatus:SetText('Status')
  content.headerStatus:SetTextColor(0.75, 0.75, 0.75)

  content.tableContainer = CreateFrame('Frame', nil, content)
  content.tableContainer:SetClipsChildren(true)

  content.memberNameRows = {}
  content.memberStatusRows = {}
  content.memberResetButtons = {}
  for index = 1, ROWS_PER_PAGE do
    content.memberNameRows[index] = content.tableContainer:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')

    local statusRow = createClickableRow(content.tableContainer, REQUEST_STATUS_TOOLTIP_TEXT)
    statusRow:SetScript('OnClick', function(self)
      local memberName = self.memberName
      if memberName and FreshSoD_SendGuildStatusRequest(memberName) then
        FreshSoD_TrackGuildBoardStatusRequest(content, memberName)
        FreshSoD_PrintRestrictionMessage('Status request sent to ' .. Ambiguate(memberName, 'short') .. '. They must be online to receive the request.')
      end
    end)
    content.memberStatusRows[index] = statusRow

    local resetButton = createRefreshButton(content.tableContainer)
    resetButton:Hide()
    resetButton:SetScript('OnClick', function(self)
      local targetName = self.memberName
      if targetName and FreshSoD_SendGuildResetRequest(targetName) then
        FreshSoD_PrintRestrictionMessage('Reset validation request sent to ' .. Ambiguate(targetName, 'short') .. '. They must be online to receive the request.')
      end
    end)
    content.memberResetButtons[index] = resetButton
  end

  content.emptyLabel = content.tableContainer:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')

  content.prevButton = CreateFrame('Button', nil, content, 'UIPanelButtonTemplate')
  content.prevButton:SetText('Prev')
  content.prevButton:SetScript('OnClick', function()
    content.guildBoardCurrentPage = math.max(1, (content.guildBoardCurrentPage or 1) - 1)
    scheduleGuildBoardRefresh(content, 0)
  end)

  content.nextButton = CreateFrame('Button', nil, content, 'UIPanelButtonTemplate')
  content.nextButton:SetText('Next')
  content.nextButton:SetScript('OnClick', function()
    content.guildBoardCurrentPage = (content.guildBoardCurrentPage or 1) + 1
    scheduleGuildBoardRefresh(content, 0)
  end)

  content.pageLabel = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')

  content.guildBoardInitialized = true
end

local function hideTableRows(content)
  for index = 1, ROWS_PER_PAGE do
    updateMemberRow(
      content.memberNameRows[index],
      content.memberStatusRows[index],
      content.memberResetButtons[index],
      nil,
      false
    )
    content.memberNameRows[index].guildBoardEntry = nil
    content.memberStatusRows[index].guildBoardStatusKey = nil
  end
end

refreshGuildBoardTable = function(content, skipRosterRefresh)
  if not content.guildBoardInitialized then
    return
  end

  ensureGuildBoardMemberCache(content, skipRosterRefresh)

  local memberData = content.guildBoardMemberData or {}
  if #memberData == 0 then
    updateGuildBoardTabDisplay(content)
    return
  end

  local searchText = getSearchText(content)
  local statusFilter = content.guildBoardStatusFilter or 'all'
  local filteredMembers = getFilteredMembers(content, searchText, statusFilter)
  local startIndex, totalPages, currentPage = getPageSlice(filteredMembers, content.guildBoardCurrentPage or 1)

  content.guildBoardCurrentPage = currentPage
  local showOfficerActions = content.guildBoardShowOfficerActions == true

  if #filteredMembers == 0 then
    hideTableRows(content)
    content.emptyLabel:ClearAllPoints()
    content.emptyLabel:SetPoint('TOPLEFT', content.tableContainer, 'TOPLEFT', 0, 0)
    content.emptyLabel:SetText('No members match your search or filter.')
    content.emptyLabel:SetTextColor(0.85, 0.85, 0.85)
    content.emptyLabel:Show()
  else
    content.emptyLabel:Hide()

    for index = 1, ROWS_PER_PAGE do
      updateMemberRow(
        content.memberNameRows[index],
        content.memberStatusRows[index],
        content.memberResetButtons[index],
        filteredMembers[startIndex + index - 1],
        showOfficerActions
      )
    end
  end

  local pageText = string.format('Page %d of %d', currentPage, totalPages)
  if content.guildBoardPageText ~= pageText then
    content.pageLabel:SetText(pageText)
    content.guildBoardPageText = pageText
  end

  local prevEnabled = currentPage > 1
  if content.guildBoardPrevEnabled ~= prevEnabled then
    content.prevButton:SetEnabled(prevEnabled)
    content.guildBoardPrevEnabled = prevEnabled
  end

  local nextEnabled = currentPage < totalPages
  if content.guildBoardNextEnabled ~= nextEnabled then
    content.nextButton:SetEnabled(nextEnabled)
    content.guildBoardNextEnabled = nextEnabled
  end
end

updateGuildBoardTabDisplay = function(content)
  ensureGuildBoardTabLayout(content)
  updateGuildBoardLayout(content)
  ensureGuildBoardMemberCache(content)

  local memberData = content.guildBoardMemberData or {}

  if #memberData == 0 then
    setMembersUiVisible(content, false)
    hideTableRows(content)

    content.emptyLabel:ClearAllPoints()
    content.emptyLabel:SetPoint('TOPLEFT', content, 'TOPLEFT', LIST_LEFT_OFFSET, CONTENT_TOP_OFFSET)
    content.emptyLabel:SetText(content.guildBoardGuildName and 'No guild members found.' or 'Join a guild to see member verification status.')
    content.emptyLabel:SetTextColor(0.85, 0.85, 0.85)
    content.emptyLabel:Show()
    return
  end

  setMembersUiVisible(content, true)
  refreshGuildBoardTable(content)
end

function FreshSoD_InitializeGuildBoardTab(tabContents)
  local content = tabContents[2]
  if not content then
    return
  end

  ensureGuildBoardTabLayout(content)
  updateGuildBoardTabDisplay(content)
end

local guildBoardRefreshFrame = CreateFrame('Frame')
guildBoardRefreshFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

guildBoardRefreshFrame:SetScript('OnEvent', function()
  FreshSoD_InvalidateGuildMemberNamesCache()

  local content = FreshSoD_GetTabContent and FreshSoD_GetTabContent(2)
  if content then
    content.guildBoardMemberData = nil
    content.guildBoardMembersByStatus = nil
    content.guildBoardMembersUiVisible = nil
  end
end)
