output "web_sg_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "db_sg_id" {
  description = "ID of the db security group"
  value       = aws_security_group.db.id
}