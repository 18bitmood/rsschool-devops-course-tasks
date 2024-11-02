resource "aws_instance" "ubuntu_server_instance" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  key_name      = aws_key_pair.keys.key_name
  depends_on    = [aws_key_pair.keys, aws_instance.ubuntu_agent_instance]
  
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./${var.bastion_key_name}.pem")
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      # Add keys to public instance
      "mkdir -p /home/ubuntu/.ssh",
      "chmod 700 /home/ubuntu/.ssh",
      "echo '${file("./${var.bastion_key_name}.pub")}' >> /home/ubuntu/.ssh/authorized_keys",
      "echo '${file("./${var.bastion_key_name}.pem")}' >> /home/ubuntu/.ssh/${var.bastion_key_name}.pem",
      "chmod 600 /home/ubuntu/.ssh/authorized_keys",
      "chmod 600 /home/ubuntu/.ssh/${var.bastion_key_name}.pem",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/${var.bastion_key_name}.pem",

      # Install k3s
      "curl -sfL https://get.k3s.io -o k3s-install.sh && sudo sh k3s-install.sh",
      # Save token to a file
      "sudo cat /var/lib/rancher/k3s/server/node-token > /home/ubuntu/k3s_token.txt",
      # Transfer token to agent instance
      "scp -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/k3s_token.txt ubuntu@${aws_instance.ubuntu_agent_instance.private_ip}:/home/ubuntu/k3s_token.txt",
      # Download the k3s installer script on agent instance
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'curl -sfL https://get.k3s.io -o k3s-install.sh'",
      # Install k3s in agent mode on agent instance
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'timeout 300 bash -c \"K3S_URL=https://${aws_instance.ubuntu_server_instance.private_ip}:6443 K3S_TOKEN=$(cat /home/ubuntu/k3s_token.txt) sh k3s-install.sh agent\"'",
      # Install Helm
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "sudo ./get_helm.sh",
      # Set local-path as default storage class
      "sudo kubectl patch storageclass local-path -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'",
      # Stop k3s on the server instance - to being able to connect to it
      "sudo systemctl stop k3s"
    ]
  }

  tags = {
    Name = "K3S server"
  }
}
