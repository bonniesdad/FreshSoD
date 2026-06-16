FreshSoD_Comms = FreshSoD_Comms or {}
local Comms = FreshSoD_Comms

Comms.CHANNEL_NAME = 'FreshSoDDataBus'

local channelFiltersInstalled = false
local delayedJoinScheduled = false

-- Classic caps players at 10 chat channels; probe a bit higher to be safe.
local MAX_CHANNEL_SLOTS = 20

local function getSlotChannelInfo(slotIndex)
  local first, second = GetChannelName(slotIndex)

  if type(first) == 'number' then
    if first > 0 and second and second ~= '' then
      return first, second
    end
    return 0, nil
  end

  if type(first) == 'string' and first ~= '' then
    return slotIndex, first
  end

  return 0, nil
end

function Comms.GetChannelId()
  if not GetChannelName then
    return 0
  end

  local id, name = GetChannelName(Comms.CHANNEL_NAME)
  if type(id) == 'number' and id > 0 then
    return id
  end

  for slotIndex = 1, MAX_CHANNEL_SLOTS do
    local slotId, slotName = getSlotChannelInfo(slotIndex)
    if slotName == Comms.CHANNEL_NAME then
      return slotId
    end
  end

  return 0
end

local function hideChannelFromChatWindows()
  if not ChatFrame_RemoveChannel or not NUM_CHAT_WINDOWS then
    return
  end

  for index = 1, NUM_CHAT_WINDOWS do
    local frame = _G['ChatFrame' .. index]
    if frame then
      ChatFrame_RemoveChannel(frame, Comms.CHANNEL_NAME)
    end
  end
end

local function getOtherChannelsHighestIndex(ourId)
  if not GetChannelName then
    return 0
  end

  local highest = 0
  for index = 1, MAX_CHANNEL_SLOTS do
    if index ~= ourId then
      local _, name = getSlotChannelInfo(index)
      if name then
        highest = index
      end
    end
  end

  return highest
end

local function channelSlotOccupied(slotIndex)
  local _, name = getSlotChannelInfo(slotIndex)
  return name ~= nil
end

-- Bubble our channel slot up until nothing sits above it.
local function tryMoveOurChannelToBack()
  local swap = C_ChatInfo and C_ChatInfo.SwapChatChannelsByChannelIndex
  if not swap or not GetChannelName then
    return
  end

  for _ = 1, MAX_CHANNEL_SLOTS do
    local id = Comms.GetChannelId()
    if id <= 0 then
      return
    end

    if not channelSlotOccupied(id + 1) then
      return
    end

    swap(id, id + 1)
  end
end

local function finalizeJoinedChannel()
  tryMoveOurChannelToBack()
  hideChannelFromChatWindows()
  return Comms.GetChannelId()
end

function Comms.InstallChannelNoticeFilters()
  if channelFiltersInstalled or not ChatFrame_AddMessageEventFilter then
    return
  end

  channelFiltersInstalled = true

  local function filterChannelName(_, _, ...)
    for index = 1, select('#', ...) do
      if tostring(select(index, ...) or '') == Comms.CHANNEL_NAME then
        return true
      end
    end
    return false
  end

  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL_NOTICE', filterChannelName)
  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL_NOTICE_USER', filterChannelName)

  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL', function(_, _, ...)
    local channelIndex = select(8, ...)
    local channelBaseName = select(9, ...)
    if channelBaseName == Comms.CHANNEL_NAME then
      return true
    end

    local id = tonumber(channelIndex) or 0
    return id > 0 and id == Comms.GetChannelId()
  end)
end

function Comms.EnsureChannelJoined(forceJoin)
  local id = Comms.GetChannelId()
  if id > 0 then
    local othersHighest = getOtherChannelsHighestIndex(id)
    if othersHighest > id then
      tryMoveOurChannelToBack()
    end

    hideChannelFromChatWindows()
    return Comms.GetChannelId()
  end

  local othersHighest = getOtherChannelsHighestIndex(0)
  if othersHighest == 0 and not forceJoin then
    return 0
  end

  if JoinChannelByName then
    JoinChannelByName(Comms.CHANNEL_NAME)
    id = Comms.GetChannelId()
    if id > 0 then
      return finalizeJoinedChannel()
    end
  end

  if JoinTemporaryChannel then
    JoinTemporaryChannel(Comms.CHANNEL_NAME)
    id = Comms.GetChannelId()
    if id > 0 then
      return finalizeJoinedChannel()
    end
  end

  return 0
end

function Comms.ScheduleDelayedChannelJoin()
  if delayedJoinScheduled then
    return
  end

  delayedJoinScheduled = true

  if not C_Timer or not C_Timer.After then
    Comms.EnsureChannelJoined(true)
    delayedJoinScheduled = false
    return
  end

  local delays = { 0.5, 1.5, 3.0, 5.0, 8.0 }
  local delayIndex = 1

  local function attemptJoin()
    if Comms.EnsureChannelJoined(false) > 0 then
      delayedJoinScheduled = false
      return
    end

    if delayIndex >= #delays then
      Comms.EnsureChannelJoined(true)
      delayedJoinScheduled = false
      return
    end

    delayIndex = delayIndex + 1
    C_Timer.After(delays[delayIndex], attemptJoin)
  end

  C_Timer.After(delays[delayIndex], attemptJoin)
end

function Comms.IsOurChannelMessage(...)
  local channelIndex = select(8, ...)
  local channelBaseName = select(9, ...)
  if channelBaseName == Comms.CHANNEL_NAME then
    return true
  end

  local id = tonumber(channelIndex) or 0
  return id > 0 and id == Comms.GetChannelId()
end

function Comms.SendChannelMessage(message)
  if not SendChatMessage or not message or message == '' then
    return false
  end

  local channelId = Comms.GetChannelId()
  if channelId <= 0 then
    channelId = Comms.EnsureChannelJoined(true)
  end

  if channelId <= 0 then
    return false
  end

  local ok = pcall(SendChatMessage, message, 'CHANNEL', nil, channelId)
  return ok
end
