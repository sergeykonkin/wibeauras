WibeAurasConfig.displays["Demo: Player health"] = {
  uid = "WibeDemoHP1",
  regionType = "aurabar",
  parent = "Demo: Status group",
  width = 180,
  height = 12,
  barColor = { 0.25, 0.75, 0.35, 1 },
  triggers = {
    {
      trigger = { type = "unit", event = "Health", unit = "player" },
      untrigger = {},
    },
  },
}
