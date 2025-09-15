variable "namespaces" {
  description = "Map of namespaces to create with their properties"
  type = map(object({
    labels      = optional(map(string))
    annotations = optional(map(string))
  }))
  default = {}
}