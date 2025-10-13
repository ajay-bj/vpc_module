resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-igw"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}