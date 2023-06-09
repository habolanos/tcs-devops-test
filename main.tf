## ----------------------------------------------------
## TCS Devops Test by Harold Adrian
## ----------------------------------------------------

#Set cloud provider
provider "aws" {
  region = var.region
  profile = "aws-tcs"
}

# Set Data Source to get VPS's ID by default
data "aws_vpc" "default" {
  default = true
}

# Set EC2's instance with AMI Amazon Linux
resource "aws_instance" "ec2_instance" {
  ami                    = "ami-04a0ae173da5807d3"
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.sg_main.id]

  // Escribimos un "here document" que es
  // usado durante la inicialización
  user_data = <<-EOF
              #!/bin/bash
              echo "TSC Devops Test by Harold Adrian." > index.html
              nohup busybox httpd -f -p 80 &
              EOF

  tags = {
    Name = "ec2_instance"
    Scope = "TCS Devops Test"
  }
}

# Set security group to access by ports
resource "aws_security_group" "sg_main" {
  name   = "security-group-main"
  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = toset(var.sg_ports.ports_in)
    content {
      description = "Web Traffic from internet"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "egress" {
    for_each = toset(var.sg_ports.ports_out)
    content {
      description = "Web Traffic to internet"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = {
    Name  = "sg-main"
    Scope = "TCS Devops Test"
  }
}

#Set EBS's volume to use it
resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = var.region
  size              = var.ebs_size

  tags = {
    Name = "ebs_volume"
    Scope = "TCS Devops Test"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.ec2_instance.id
}