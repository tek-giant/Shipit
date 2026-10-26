variable "image_tag" {
  description = "Version of the orders-api image to run"
  type        = string
  default     = "0.1.2"
}

variable "desired_count" {
  description = "How many copies of the app to run"
  type        = number
  default     = 2
}
