resource "aws_key_pair" "keys" {
  key_name   = var.bastion_key_name
  public_key = file("./${var.bastion_key_name}.pub")
}

resource "aws_instance" "bastion" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  key_name      = aws_key_pair.keys.key_name
  depends_on    = [aws_key_pair.keys]

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "Bastion Host"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/.ssh",
      "chmod 700 /home/ubuntu/.ssh",
      "echo '${file("./${var.bastion_key_name}.pub")}' >> /home/ubuntu/.ssh/authorized_keys",
      "echo '${file("./${var.bastion_key_name}.pem")}' >> /home/ubuntu/.ssh/${var.bastion_key_name}.pem",
      "chmod 600 /home/ubuntu/.ssh/authorized_keys",
      "chmod 600 /home/ubuntu/.ssh/${var.bastion_key_name}.pem",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/${var.bastion_key_name}.pem"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./${var.bastion_key_name}.pem")
      host        = self.public_ip
    }
  }
}
