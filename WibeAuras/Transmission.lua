-- Modified for ForeverAuras, 2026-09-18.
-- Modifications Copyright (C) 2026 ForeverAuras. Licensed under the GNU GPL v2 (see LICENSE).
if not WibeAuras.IsLibsOK() then return end
---@class Private
local Private = select(2, ...)

-- Lua APIs
local tinsert = table.insert
local tostring = tostring
local pairs, type = pairs, type
local error = error

---@class WibeAuras
local WibeAuras = WibeAuras;
local L = WibeAuras.L;

local versionString = WibeAuras.versionString;

-- Local functions
local GenerateUniqueID
local CompressDisplay, TableToString, StringToTable

local bytetoB64 = {
  [0]="a","b","c","d","e","f","g","h",
  "i","j","k","l","m","n","o","p",
  "q","r","s","t","u","v","w","x",
  "y","z","A","B","C","D","E","F",
  "G","H","I","J","K","L","M","N",
  "O","P","Q","R","S","T","U","V",
  "W","X","Y","Z","0","1","2","3",
  "4","5","6","7","8","9","(",")"
}

function GenerateUniqueID()
  -- generates a unique random 11 digit number in base64
  local s = {}
  for i=1,11 do
    tinsert(s, bytetoB64[math.random(0, 63)])
  end
  return table.concat(s)
end
WibeAuras.GenerateUniqueID = GenerateUniqueID

local function stripNonTransmissableFields(datum, fieldMap)
  for k, v in pairs(fieldMap) do
    if type(v) == "table" and type(datum[k]) == "table" then
      stripNonTransmissableFields(datum[k], v)
    elseif v == true then
      datum[k] = nil
    end
  end
end

function CompressDisplay(data, version)
  -- Clean up custom trigger fields that are unused
  -- Those can contain lots of unnecessary data.
  -- Also we warn about any custom code, so removing unnecessary
  -- custom code prevents unnecessary warnings
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger

    if (trigger and trigger.type ~= "custom") then
      trigger.custom = nil;
      trigger.customDuration = nil;
      trigger.customName = nil;
      trigger.customIcon = nil;
      trigger.customTexture = nil;
      trigger.customStacks = nil;
      if (untrigger) then
        untrigger.custom = nil;
      end
    end
  end

  local copiedData = CopyTable(data)
  -- External Display Changes (ExternalDisplay.lua) are session state: the export carries authored values.
  if Private.ExternalDisplayRestore then Private.ExternalDisplayRestore(copiedData) end
  local non_transmissable_fields = version >= 2000 and Private.non_transmissable_fields_v2000
                                                       or Private.non_transmissable_fields
  stripNonTransmissableFields(copiedData, non_transmissable_fields)
  copiedData.tocversion = WibeAuras.BuildInfo
  return copiedData;
end

local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize-WibeAuras")
-- the biggest bottleneck by far is in transmission and printing; so use maximal compression
local configForDeflate = {level = 9}
local configForLS = {
  errorOnUnserializableType =  false
}

local compressedTablesCache = {}

function TableToString(inTable)
  local serialized = LibSerialize:SerializeEx(configForLS, inTable)
  local compressed
  -- get from / add to cache
  if compressedTablesCache[serialized] then
    compressed = compressedTablesCache[serialized].compressed
    compressedTablesCache[serialized].lastAccess = time()
  else
    compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
    compressedTablesCache[serialized] = {
      compressed = compressed,
      lastAccess = time(),
    }
  end
  -- remove cache items after 5 minutes
  for k, v in pairs(compressedTablesCache) do
    if v.lastAccess < (time() - 300) then
      compressedTablesCache[k] = nil
    end
  end
  return "!WIBE:2!" .. LibDeflate:EncodeForPrint(compressed)
end

function StringToTable(input)
  local encoded = input:match("^%s*!WIBE:2!(%S+)%s*$")
  if not encoded then return nil end
  local decoded = LibDeflate:DecodeForPrint(encoded)
  if not decoded then return nil end
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then return nil end
  local success, data = LibSerialize:Deserialize(decompressed)
  if success then return data end
end

Private.StringToTable = StringToTable

-- excludedIds leaves those auras out, along with everything inside them.
function Private.DisplayToString(id, excludedIds)
  local data = WibeAuras.GetData(id);
  if(data) then
    excludedIds = excludedIds or {}
    local excluded = {}
    data.uid = data.uid or GenerateUniqueID()
    -- Check which transmission version we want to use
    local version = 1421
    for child in Private.TraverseSubGroups(data) do -- luacheck: ignore
      version = 2000
      break;
    end
    local transmitData = CompressDisplay(data, version);
    local transmit = {
      m = "d",
      d = transmitData,
      v = version,
      s = versionString
    };
    if(data.controlledChildren) then
      transmit.c = {};
      local uids = {}
      local index = 1
      for child in Private.TraverseAllChildren(data) do
        -- Children come after their group, so a group's exclusion reaches everything inside it.
        if excludedIds[child.id] or excluded[child.parent] then
          excluded[child.id] = true
        else
          if child.uid then
            if uids[child.uid] then
              child.uid = GenerateUniqueID()
            else
              uids[child.uid] = true
            end
          else
            child.uid = GenerateUniqueID()
          end
          transmit.c[index] = CompressDisplay(child, version);
          index = index + 1
        end
      end
    end
    if next(excluded) then
      local function dropExcluded(groupData)
        if not groupData.controlledChildren then return end
        local kept = {}
        for _, childId in ipairs(groupData.controlledChildren) do
          if not excluded[childId] then
            tinsert(kept, childId)
          end
        end
        groupData.controlledChildren = kept
      end
      dropExcluded(transmitData)
      for _, childData in ipairs(transmit.c or {}) do
        dropExcluded(childData)
      end
    end
    return TableToString(transmit);
  else
    return "";
  end
end

local orderedPairs
do
  local function __genOrderedIndex(t)
    local orderedIndex = {}
    for key in pairs(t) do
      if key ~= "__orderedIndex" then
        table.insert(orderedIndex, key)
      end
    end
    table.sort(orderedIndex, function(a, b)
      local typeA, typeB = type(a), type(b)
      if typeA ~= typeB then
        return typeA < typeB
      else
        return a < b
      end
    end)
    return orderedIndex
  end

  local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.
    local key = nil
    if state == nil then
      -- the first time, generate the index
      t.__orderedIndex = __genOrderedIndex(t)
      key = t.__orderedIndex[1]
    else
      -- fetch the next value
      for i = 1, table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
          key = t.__orderedIndex[i+1]
        end
      end
    end

    if key then
      return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
  end

  function orderedPairs(t)
    return orderedNext, t, nil
  end
end

local function recurseStringify(data, level, lines, sorted)
  local pairsFn = sorted and orderedPairs or pairs
  for k, v in pairsFn(data) do
    local lineFormat = strrep("    ", level) .. "[%s] = %s"
    local form1, form2, value
    local kType, vType = type(k), type(v)
    if kType == "string" then
      form1 = "%q"
    elseif kType == "number" then
      form1 = "%d"
    else
      form1 = "%s"
    end
    if vType == "string" then
      form2 = "%q"
      v = v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"")
    elseif vType == "boolean" then
      v = tostring(v)
      form2 = "%s"
    else
      form2 = "%s"
    end
    lineFormat = lineFormat:format(form1, form2)
    if vType == "table" then
      tinsert(lines, lineFormat:format(k, "{"))
      recurseStringify(v, level + 1, lines, sorted)
      tinsert(lines, strrep("    ", level) .. "},")
    else
      tinsert(lines, lineFormat:format(k, v) .. ",")
    end
  end
end

function Private.DataToString(id, sorted)
  local data = WibeAuras.GetData(id)
  if data then
    return Private.SerializeTable(data, sorted):gsub("|", "||")
  end
end

function Private.SerializeTable(data, sorted)
  local lines = {"{"}
  recurseStringify(data, 1, lines, sorted)
  tinsert(lines, "}")
  return table.concat(lines, "\n")
end
