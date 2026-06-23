variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "domain" {
  description = "Root domain name"
  type        = string
  default     = "theclouddevopslearningblog.com"
}

variable "improvmx_forward_to" {
  description = "Email address that ImprovMX forwards incoming mail to"
  type        = string
  default     = "simon.mackinnon15@gmail.com"
}
