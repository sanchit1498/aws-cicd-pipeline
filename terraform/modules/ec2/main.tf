resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.web_sg_id]
  key_name               = var.key_name

  # Startup scripts only run on first boot, so a changed script must replace the server
  user_data_replace_on_change = true

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y nginx python3 python3-pip git
    pip3 install flask pymysql
    git clone https://github.com/sanchit1498/aws-cicd-pipeline.git /opt/app

    cat > /etc/app.env << 'ENVF'
    DB_HOST="${var.db_host}"
    DB_USER="${var.db_user}"
    DB_PASSWORD="${var.db_password}"
    DB_NAME="${var.db_name}"
    ENVF

    cat > /etc/systemd/system/app.service << 'UNIT'
    [Unit]
    Description=Flask product catalog
    After=network-online.target

    [Service]
    EnvironmentFile=/etc/app.env
    WorkingDirectory=/opt/app/app
    ExecStart=/usr/bin/python3 /opt/app/app/app.py
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    UNIT

    cat > /etc/nginx/nginx.conf << 'NGINX'
    user nginx;
    worker_processes auto;
    pid /run/nginx.pid;
    events {}
    http {
      server {
        listen 80;
        location / {
          proxy_pass http://127.0.0.1:5000;
          proxy_set_header Host $host;
        }
      }
    }
    NGINX

    systemctl daemon-reload
    systemctl enable --now app
    systemctl enable --now nginx
  EOT

  tags = {
    Name = "${var.project_name}-web"
  }
}