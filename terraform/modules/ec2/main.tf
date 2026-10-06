resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.web_sg_id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx python3 python3-pip
    systemctl enable nginx
    systemctl start nginx
    pip3 install flask pymysql
  EOF

  tags = {
    Name = "${var.project_name}-web"
  }
}