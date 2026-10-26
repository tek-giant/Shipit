variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "cidr" {
  description = "IP range for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "enable_nat" {
  description = "Create a NAT gateway (costs money, off by default)"
  type        = bool
  default     = false
}
