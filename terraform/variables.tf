variable "aws_region" {
  description = "AWS region where the mini k3s GitOps environment will be created."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project tag value."
  type        = string
  default     = "mini-k3s-gitops"
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet. The instance has no inbound rules but uses this subnet for cheap outbound internet access."
  type        = string
  default     = "10.42.1.0/24"
}

variable "availability_zone" {
  description = "Optional availability zone. When null, Terraform uses the first available AZ in the selected region."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the single-node k3s server."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "k3s_cluster_cidr" {
  description = "k3s pod CIDR. Must not overlap with the VPC CIDR."
  type        = string
  default     = "10.244.0.0/16"
}

variable "k3s_service_cidr" {
  description = "k3s service CIDR. Must not overlap with the VPC CIDR or pod CIDR."
  type        = string
  default     = "10.245.0.0/16"
}

variable "ubuntu_ami_id" {
  description = "Optional Ubuntu 22.04 AMI override. When null, Terraform discovers the latest Canonical Ubuntu 22.04 amd64 server AMI."
  type        = string
  default     = null
}

variable "extra_tags" {
  description = "Additional tags to merge with the standard tags."
  type        = map(string)
  default     = {}
}
