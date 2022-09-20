provider "aws" {
   region = "ap-south-1"
   default_tags {
    tags = {
      App = "monitoring"
      Managed_By = "terraform"
    }
   }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.29.0"
    }
  }
}

resource "aws_security_group" "monitoring" {
  name        = "monitoring"
  description = "Allow ssh inbound traffic"
  vpc_id      = var.vpc_id  

  ingress {
    description = "Allow all traffic inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all traffic outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "monitoring" {
  ami                     = var.ami_id   
  instance_type           = "t2.micro"   
  key_name                = var.key_name

  subnet_id = var.subnet_id
  security_groups = [aws_security_group.monitoring.id] 

  monitoring                    = true
  disable_api_termination       = false
  hibernation                   = null
  disable_api_stop              = null
  tenancy                       = null
  associate_public_ip_address   = true
  source_dest_check             = true
  instance_initiated_shutdown_behavior = null

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install epel -y
    sudo yum install ssmtp -y

    # For Setting SMTP Configuration
    sudo tee /etc/ssmtp/ssmtp.conf<<EOT
    root=${var.smtp_user}
    AuthUser=${var.smtp_user}
    AuthPass=${var.smtp_password}
    mailhub=smtp.gmail.com:587
    FromLineOverride=YES
    UseSTARTTLS=YES
    UseTLS=YES
    TLS_CA_File=/etc/pki/tls/certs/ca-bundle.crt
    EOT

    # Cron-job Setup
    # echo '* * * * * /home/ec2-user/script.sh' | crontab
  EOF

  root_block_device {
    delete_on_termination = true
    encrypted = false
    volume_type = "gp3"
    volume_size = var.root_volume_size    
    iops = "3000"
    throughput = "125"
  }

connection {
    type     = "ssh"
    host     =  "${self.public_ip}"
    user     = "ec2-user"
    private_key = "${file("task-ssh.pem")}"
  }
provisioner "file" {
    source      = "script.sh"
    destination = "/home/ec2-user/script.sh"
  }
provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/script.sh"
    ]
  }
}