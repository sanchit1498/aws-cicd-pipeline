output "vpc_id" {
    description = "ID of the vpc"
    value = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_app_subnet_id" {
    description = "ID of the private app subnet"
    value = aws_subnet.private_app.id
}

output "private_db_subnet_id" {
  description = "ID of the first private db subnet"
  value       = aws_subnet.private_db.id
}

output "private_db_subnet_2_id" {
  description = "ID of the second private db subnet"
  value       = aws_subnet.private_db_2.id
}