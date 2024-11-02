resource "aws_instance" "ubuntu_agent_instance" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  key_name      = aws_key_pair.keys.key_name
  depends_on    = [aws_key_pair.keys]

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "K3S agent"
  }
}
