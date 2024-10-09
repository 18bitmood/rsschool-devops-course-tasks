resource "aws_instance" "ubuntu_public_instances" {
  count         = length(var.public_subnet_cidrs)
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "Ubuntu Public Instance ${count.index + 1}"
  }
}

resource "aws_instance" "ubuntu_private_instances" {
  count         = length(var.private_subnet_cidrs)
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "Ubuntu Private Instance ${count.index + 1}"
  }
}
