# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = try(module.vpc.private_subnets,"")
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "app_subnets" {
  description = "List of IDs of public subnets"
  # value       = slice(module.vpc.private_subnets, 0, 4)
  value = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "infra_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# Customer Gateway
output "cgw_ids" {
  description = "List of IDs of Customer Gateway"
  value       = module.vpc.cgw_ids
}

output "this_customer_gateway" {
  description = "Map of Customer Gateway attributes"
  value       = module.vpc.this_customer_gateway
}

output "private_subnet_zone_a" {
  description = "List of IDs of private subnets"
  value       = try(module.vpc.private_subnets[0],"")
}

output "private_subnet_zone_b" {
  description = "List of IDs of private subnets"
  value       = try(module.vpc.private_subnets[1],"")
}

output "public_subnet_zone_a" {
  description = "List of IDs of public subnets"
  value       = try(module.vpc.public_subnets[0],"")
}

output "public_subnet_zone_b" {
  description = "List of IDs of public subnets"
  value       = try(module.vpc.public_subnets[1],"")
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = try(module.vpc.private_route_table_ids,"")
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "infra_subnet_zone_a" {
  description = "List of IDs of infra subnets"
  value       = module.vpc.elasticache_subnets[0]
}

output "infra_subnet_zone_b" {
  description = "List of IDs of infra subnets"
  value       = module.vpc.elasticache_subnets[1]
}

output "db_subnet_zone_a" {
  description = "List of IDs of db subnets"
  value       = module.vpc.database_subnets[0]
}

output "db_subnet_zone_b" {
  description = "List of IDs of db subnets"
  value       = module.vpc.database_subnets[1]
}

# output "additional_sg" {
#  	 description = "List of IDs of infra subnets"
#   value       = aws_security_group.additional.id
# }

output "all_route_tables_id" {
  description = "List of IDs of public route table id"
  value       = concat(module.vpc.public_route_table_ids, module.vpc.private_route_table_ids)
}
	
