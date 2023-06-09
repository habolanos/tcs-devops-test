## ----------------------------------------------------
## TCS Devops Test by Harold Adrian
## ----------------------------------------------------

#Set cloud provider
provider "aws" {
  region = var.region
  profile = "aws-tcs"
  default_tags {
    tags = {
      Environment = "Lab"
      Scope = "TCS Devops Test"
    }
  }
}

# Set Data Source to get VPS's ID to Lab
data "aws_vpc" "lab_vpc" {
  default = true
}

resource "aws_vpc" "lab_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "lab-vpc"
  }
}

resource "aws_subnet" "lab_private_subnet" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "lab-private-subnet"
  }
}

resource "aws_network_interface" "lab_ni" {
  subnet_id   = aws_subnet.lab_private_subnet.id
  private_ips = ["10.0.10.100"]

  tags = {
    Name = "lab-network-interface"
  }
}

resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "lab-internet-gateway"
  }
}

resource "aws_eip" "lab_eip" {
  vpc = true
}

resource "aws_nat_gateway" "lab_nat_gw" {
  allocation_id = aws_eip.lab_eip.id
  subnet_id     = aws_subnet.lab_private_subnet.id

  tags = {
    Name = "lab-nat-gateway"
  }

  depends_on = [aws_internet_gateway.lab_igw]
}

# Set EC2's instance with AMI Amazon Linux
resource "aws_instance" "ec2_instance" {
  ami                    = "ami-04a0ae173da5807d3"
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.sg_main.id]

  network_interface {
    network_interface_id = aws_network_interface.lab_ni.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  // Make a file to publish it as a page html
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
  vpc_id = data.aws_vpc.lab_vpc.id

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

#Set S3 Bucket
resource "aws_s3_bucket" "lab_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
  }
}

resource "aws_s3_bucket_acl" "lab_bucket_acl" {
  bucket = aws_s3_bucket.lab_bucket.id
  acl    = "private"
}