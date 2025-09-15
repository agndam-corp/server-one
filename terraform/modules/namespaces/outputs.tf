output "namespaces" {
  description = "Map of created namespaces"
  value = {
    for k, v in kubernetes_namespace.required : k => v.metadata[0].name
  }
}