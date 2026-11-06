variable "devices" {
  description = "Network devices and their management addresses"

  type = map(object({
    ip    = string
    group = string
  }))

  validation {
    condition = alltrue([
      for device in values(var.devices) :
      contains(["switches", "routers"], device.group)
    ])

    error_message = "Device group must be switches or routers."
  }
}