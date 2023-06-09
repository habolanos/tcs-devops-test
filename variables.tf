variable "region" {
  description = "Region on AWS"
  type        = string
  default     = "us-east-1"
}

variable "ec2_type" {
  description = "Type instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "ebs_size" {
  description = "Size EBS"
  type        = number
  default     = 2
}

variable "sg_ports" {
  type = object({
    ports_in  = list(number)
    ports_out = list(number)
  })
  default = {
    ports_in = [
      443,
      80,
      22
    ]
    ports_out = [
      0
    ]
  }
}
