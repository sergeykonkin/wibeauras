-- Copyright (C) 2026 ForeverAuras. Part of ForeverAuras, licensed under the GNU GPL v2 (see LICENSE).
-- The API other addons use to share auras, such as WagoUI's UI Packs:
-- https://github.com/methodgg/Wago-Creator-UI/blob/main/WagoUI_Libraries/LibAddonProfiles/ImplementationGuide.lua
if not WibeAuras.IsLibsOK() then return end
---@class Private
local Private = select(2, ...)

WibeAurasAPI = {}

--- Every aura by id, with its group's id, the ids of the auras directly inside it, and its icon.
---@return table<string, {parent: string?, children: string[]?, icon: number|string|nil}>
function WibeAurasAPI:GetAuras()
  local auras = {}
  for id, data in pairs(Private.displays) do
    auras[id] = {
      parent = data.parent,
      children = data.controlledChildren and CopyTable(data.controlledChildren),
      icon = data.groupIcon or data.displayIcon,
    }
  end
  return auras
end

--- The encoded export of an aura and everything inside it.
--- Auras in excludedIds are left out, along with everything inside them. The exported aura itself never is.
---@param id string
---@param excludedIds table<string, boolean>?
---@return string?
function WibeAurasAPI:ExportAura(id, excludedIds)
  if not WibeAuras.GetData(id) then return nil end
  return Private.DisplayToString(id, excludedIds)
end

--- The table held by a WibeAuras export string.
---@param exportString string
---@return table?
function WibeAurasAPI:DecodeAuraString(exportString)
  if type(exportString) ~= "string" then return nil end
  local decoded = Private.StringToTable(exportString)
  return type(decoded) == "table" and decoded or nil
end
