variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow the bucket to be deleted if non-empty."
}

variable "name" {
  type        = string
  description = "Name to uniquely identify the S3 bucket. Used to generate the underlying AWS bucket name."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional tags to associate w/ AWS resource."
}

variable "versioning_enabled" {
  type        = bool
  default     = true
  description = "Whether or not to enable versions of objects in the bucket."
}