output "data_processing_role_arn" {
  description = "ARN del rol de procesamiento de datos"
  value       = aws_iam_role.data_processing.arn
}

output "audit_role_arn" {
  description = "ARN del rol de auditoría"
  value       = aws_iam_role.audit_control_plane.arn
}