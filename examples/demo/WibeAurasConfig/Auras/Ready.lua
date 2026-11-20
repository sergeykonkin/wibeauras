WibeAurasConfig.displays["Demo: Ready"] = {
  uid = "WibeDemoRdy",
  regionType = "text",
  parent = "Demo: Status group",
  displayText = "WibeAuras is running",
  fontSize = 16,
  triggers = {
    {
      trigger = { type = "unit", event = "Conditions", use_alwaystrue = true },
      untrigger = {},
    },
  },
}
