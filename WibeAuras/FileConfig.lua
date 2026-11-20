-- Part of WibeAuras, licensed under the GNU GPL v2 (see LICENSE).
local _, Private = ...

local function ReadDisplays(source)
  if type(source) ~= "table" then
    return nil, "expected a table keyed by aura ID"
  end

  local uids = {}
  for id, data in pairs(source) do
    if type(id) ~= "string" or id == "" or type(data) ~= "table" then
      return nil, "expected nonempty string IDs and aura tables"
    end
    if data.id ~= nil and data.id ~= id then
      return nil, ("%q has an id that differs from its key"):format(id)
    end
    if type(data.uid) ~= "string" or data.uid == "" or uids[data.uid] then
      return nil, ("%q needs a nonempty, unique uid"):format(id)
    end
    uids[data.uid] = true
    if not Private.regionTypes[data.regionType] then
      return nil, ("%q has an unknown regionType"):format(id)
    end
    local version = data.internalVersion
    if version ~= nil and version ~= WibeAuras.InternalVersion() then
      return nil, ("%q has an unsupported internalVersion"):format(id)
    end
    if data.controlledChildren ~= nil then
      if type(data.controlledChildren) ~= "table"
          or (data.regionType ~= "group" and data.regionType ~= "dynamicgroup") then
        return nil, ("%q needs a group region and an ordered list of child IDs"):format(id)
      end
      local children = {}
      for index, child in pairs(data.controlledChildren) do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #data.controlledChildren
            or type(child) ~= "string" or type(source[child]) ~= "table"
            or source[child].parent ~= id or children[child] then
          return nil, ("%q has an invalid controlledChildren list"):format(id)
        end
        children[child] = true
      end
      for _, child in ipairs(data.controlledChildren) do children[child] = nil end
      if next(children) then
        return nil, ("%q has a gap in controlledChildren"):format(id)
      end
    end
    if data.information ~= nil and type(data.information) ~= "table" then
      return nil, ("%q needs an information table"):format(id)
    end
  end

  local checked = {}
  for id in pairs(source) do
    local path = {}
    local child = id
    while child and not checked[child] do
      if path[child] then
        return nil, ("%q has a circular parent relationship"):format(id)
      end
      path[child] = true
      local parent = source[child].parent
      if parent ~= nil then
        local group = type(parent) == "string" and source[parent]
        if not group or (group.regionType ~= "group" and group.regionType ~= "dynamicgroup") then
          return nil, ("%q needs a parent ID that refers to a group"):format(child)
        end
        local childType = source[child].regionType
        if group.regionType == "dynamicgroup" and (childType == "group" or childType == "dynamicgroup") then
          return nil, ("%q cannot be a group inside a dynamic group"):format(child)
        end
      end
      child = parent
    end
    for visited in pairs(path) do checked[visited] = true end
  end

  local copied, displays = pcall(CopyTable, source)
  if not copied then
    return nil, "could not copy the aura definitions"
  end
  for id, data in pairs(displays) do
    data.id = id
    data.internalVersion = data.internalVersion or WibeAuras.InternalVersion()
    if data.regionType == "group" or data.regionType == "dynamicgroup" then
      data.controlledChildren = data.controlledChildren or {}
    end
  end
  return displays
end

function Private.LoadFileConfig(db)
  local config = WibeAurasConfig
  WibeAurasConfig = nil
  Private.displays = {}

  if config == nil then
    WibeAuras.prettyPrint("WibeAurasConfig: Configuration is missing. Check that WibeAuras Config is installed and enabled.")
    return
  end
  if type(config) ~= "table" or (config.cdmHideBlizzard ~= nil and type(config.cdmHideBlizzard) ~= "boolean") then
    WibeAuras.prettyPrint("WibeAurasConfig: Expected a configuration table and a boolean cdmHideBlizzard if set.")
    return
  end
  local displays, reason = ReadDisplays(config.displays)
  if not displays then
    WibeAuras.prettyPrint(("WibeAurasConfig: %s."):format(reason))
    return
  end

  Private.displays = displays
  if config.cdmHideBlizzard ~= nil then
    db.cdmHideBlizzard = config.cdmHideBlizzard
  end
end
