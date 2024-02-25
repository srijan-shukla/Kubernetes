output "terraform-dynamodb_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.terraform-dynamodb.dynamodb_table_arn
}

output "terraform-dynamodb_id" {
  description = "ID of the DynamoDB table"
  value       = module.terraform-dynamodb.dynamodb_table_id
}

output "terraform-dynamodb_stream_arn" {
  description = "The ARN of the Table Stream. Only available when var.stream_enabled is true"
  value       = module.terraform-dynamodb.dynamodb_table_stream_arn
}

output "terraform-dynamodb_stream_label" {
  description = "A timestamp, in ISO 8601 format of the Table Stream. Only available when var.stream_enabled is true"
  value       = module.terraform-dynamodb.dynamodb_table_stream_label
}