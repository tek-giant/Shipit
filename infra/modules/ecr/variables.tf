variable "name" {
  description = "Repository name"
  type        = string
}

variable "keep_last" {
  description = "How many images to keep"
  type        = number
  default     = 10
}
