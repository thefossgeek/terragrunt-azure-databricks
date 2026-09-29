variable "groups" {
  description = "Entra ID groups to create, keyed by logical name. Empty members skips creating that group."
  type = map(object({
    display_name = string
    members      = list(string)
  }))
  default = {}
}
