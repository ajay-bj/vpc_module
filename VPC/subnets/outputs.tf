output "subnets" {
  value = { for a, b in aws_subnet.subnets : a => b.id }
}

output "subnets_cidr" {
  value = { for a, b in aws_subnet.subnets : a => b.cidr_block }
}