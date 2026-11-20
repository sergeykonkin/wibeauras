WibeAurasConfig.displays["Demo: Combat status"] = {
  uid = "WibeDemoCbt",
  regionType = "text",
  parent = "Demo: Status group",
  displayText = "In combat",
  color = { 1, 0.45, 0.25, 1 },
  load = { use_combat = true },
  triggers = {
    {
      trigger = { type = "unit", event = "Conditions", use_alwaystrue = true },
      untrigger = {},
    },
  },
}
