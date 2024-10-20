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
      # Add keys to private instances
      "mkdir -p /home/ubuntu/.ssh",
      "chmod 700 /home/ubuntu/.ssh",
      "echo '${file("./${var.bastion_key_name}.pub")}' >> /home/ubuntu/.ssh/authorized_keys",
      "echo '${file("./${var.bastion_key_name}.pem")}' >> /home/ubuntu/.ssh/${var.bastion_key_name}.pem",
      "chmod 600 /home/ubuntu/.ssh/authorized_keys",
      "chmod 600 /home/ubuntu/.ssh/${var.bastion_key_name}.pem",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/${var.bastion_key_name}.pem",

      # Install k3s on the first public instance
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_private_instances[0].private_ip} 'curl -sfL https://get.k3s.io -o k3s-install.sh && sudo sh k3s-install.sh'",
      "sleep 10",

      # Retrieve the node token and save it to a file
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_private_instances[0].private_ip} 'sudo cat /var/lib/rancher/k3s/server/node-token' > /home/ubuntu/k3s_token.txt",

      # Install k3s in agent mode on other public instances
      "${join("\n",
        flatten([
          for ip in slice(aws_instance.ubuntu_private_instances[*].private_ip, 1, length(aws_instance.ubuntu_private_instances)) : [
            # Transfer the node token to the agent instances
            "scp -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/k3s_token.txt ubuntu@${ip}:/home/ubuntu/k3s_token.txt",
            # Download the k3s installer script
            "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${ip} 'curl -sfL https://get.k3s.io -o k3s-install.sh'",
            # Install k3s in agent mode
            "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${ip} 'timeout 300 bash -c \"K3S_URL=https://${aws_instance.ubuntu_private_instances[0].private_ip}:6443 K3S_TOKEN=$(cat /home/ubuntu/k3s_token.txt) sh k3s-install.sh agent\"'"
          ]
        ])
      )}"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./${var.bastion_key_name}.pem")
      host        = self.public_ip
    }
  }
}
