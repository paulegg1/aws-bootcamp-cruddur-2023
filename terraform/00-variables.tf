variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.6.6.0/24", "10.6.12.0/24", "10.6.18.0/24", "10.6.24.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.6.32.0/24", "10.6.40.0/24", "10.6.48.0/24", "10.6.56.0/24"]
}

variable "cidr16" {
  type    = string
  default = "10.6.0.0"
}

variable "cidr16array" {
  type    = list(any)
  default = [10, 6, 0, 0]

}

variable "public_subnet_count" {
  type    = number
  default = 4
}

variable "private_subnet_count" {
  type    = number
  default = 4
}
