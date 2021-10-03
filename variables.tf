
variable "suffix" {
  type        = string
  description = "task and my name to use for resource names."
  default     = "task16_cmba"
}



variable "path_names" {
  description = "Create api paths with these names"
  type        = list(string)
  default     = ["Create", "Put"]
}
