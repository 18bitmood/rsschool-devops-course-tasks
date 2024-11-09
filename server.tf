resource "aws_instance" "ubuntu_server_instance" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  key_name      = aws_key_pair.keys.key_name
  depends_on    = [aws_key_pair.keys, aws_instance.ubuntu_agent_instance, aws_instance.ubuntu_second_agent_instance]

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

      # Configure RAM swap on server
      "echo '${file("./ram-swap.sh")}' > /home/ubuntu/ram-swap.sh",
      "chmod +x /home/ubuntu/ram-swap.sh",
      "sudo /home/ubuntu/ram-swap.sh",

      # Configure RAM swap on agent
      "scp -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/ram-swap.sh ubuntu@${aws_instance.ubuntu_agent_instance.private_ip}:/home/ubuntu/ram-swap.sh",
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'chmod +x /home/ubuntu/ram-swap.sh && sudo /home/ubuntu/ram-swap.sh'",

      # Configure RAM swap on second agent
      "scp -C -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/ram-swap.sh ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip}:/home/ubuntu/ram-swap.sh",
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip} 'chmod +x /home/ubuntu/ram-swap.sh && sudo /home/ubuntu/ram-swap.sh'",

      # Install k3s on server
      "curl -sfL https://get.k3s.io -o k3s-install.sh && sudo sh k3s-install.sh",
      # Save token to a file
      "sudo cat /var/lib/rancher/k3s/server/node-token > /home/ubuntu/k3s_token.txt",

      # Transfer token to agent instance
      "scp -C -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/k3s_token.txt ubuntu@${aws_instance.ubuntu_agent_instance.private_ip}:/home/ubuntu/k3s_token.txt",
      # Download the k3s installer script on agent instance
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'curl -sfL https://get.k3s.io -o k3s-install.sh'",
      # Install k3s in agent mode on agent instance
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'timeout 300 bash -c \"K3S_URL=https://${aws_instance.ubuntu_server_instance.private_ip}:6443 K3S_TOKEN=$(cat /home/ubuntu/k3s_token.txt) sh k3s-install.sh agent\"'",

      # Transfer token to second agent instance
      "scp -C -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/k3s_token.txt ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip}:/home/ubuntu/k3s_token.txt",
      # Pass k3s installer from first agent instance to second agent instance
      "scp -C -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip}:/home/ubuntu/k3s-install.sh ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip}:/home/ubuntu/k3s-install.sh",
      # Install k3s in agent mode on second agent instance
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip} 'timeout 300 bash -c \"K3S_URL=https://${aws_instance.ubuntu_server_instance.private_ip}:6443 K3S_TOKEN=$(cat /home/ubuntu/k3s_token.txt) sh k3s-install.sh agent\"'",

      # Wait for k3s to be ready
      "sudo kubectl wait --for=condition=Ready node --all --timeout=300s",
      # Write kubeconfig to file
      "sudo cat /etc/rancher/k3s/k3s.yaml > /home/ubuntu/k3s.yaml",

      # Copy kubeconfig to agent
      "scp -C -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/k3s.yaml ubuntu@${aws_instance.ubuntu_agent_instance.private_ip}:/home/ubuntu/k3s.yaml",
      # Copy kubeconfig to second agent
      "scp -C -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/k3s.yaml ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip}:/home/ubuntu/k3s.yaml",

      # Install Helm on agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && sudo ./get_helm.sh'",
      # Configure Jenkins installation on agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo mkdir -p /etc/rancher/k3s && sudo mv /home/ubuntu/k3s.yaml /etc/rancher/k3s/k3s.yaml && sudo chmod 644 /etc/rancher/k3s/k3s.yaml'",

      # Configure DNS for k3s and Verify DNS resolution for server
      "sudo kubectl -n kube-system rollout restart deployment coredns",
      "sudo kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=kube-dns --timeout=60s",
      "sudo kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 --command -- sleep 3600",
      "sudo kubectl wait --for=condition=Ready pod/dnsutils --timeout=60s",

      # Update kubeconfig on agent to use server IP
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo sed -i \"s/127.0.0.1/${aws_instance.ubuntu_server_instance.private_ip}/g\" /etc/rancher/k3s/k3s.yaml'",
      # Set proper permissions for kubeconfig on agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo chmod 600 /etc/rancher/k3s/k3s.yaml'",

      # Update kubeconfig on second agent to use server IP
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip} 'sudo sed -i \"s/127.0.0.1/${aws_instance.ubuntu_server_instance.private_ip}/g\" /etc/rancher/k3s/k3s.yaml'",
      # Set proper permissions for kubeconfig on second agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip} 'sudo chmod 600 /etc/rancher/k3s/k3s.yaml'",

      # Prepare Jenkins Installation on agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo kubectl create namespace jenkins'",
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo helm repo add jenkins https://charts.jenkins.io && sudo helm repo update'",
      "echo '${file("./jenkins-values.yaml")}' > /home/ubuntu/jenkins-values.yaml",
      "scp -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no /home/ubuntu/jenkins-values.yaml ubuntu@${aws_instance.ubuntu_agent_instance.private_ip}:/home/ubuntu/jenkins-values.yaml",
      # Install Jenkins
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo helm install jenkins jenkins/jenkins --namespace jenkins --create-namespace --set controller.serviceType=NodePort --set controller.installPlugins=false --set controller.additionalPlugins=[] -f /home/ubuntu/jenkins-values.yaml --kubeconfig /etc/rancher/k3s/k3s.yaml'",
      # Restart k3s-agent on agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_agent_instance.private_ip} 'sudo systemctl restart k3s-agent'",
      # Restart k3s-agent on second agent
      "ssh -i /home/ubuntu/.ssh/${var.bastion_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.ubuntu_second_agent_instance.private_ip} 'sudo systemctl restart k3s-agent'",
      # Stop k3s - to access the server instance
      "sudo service k3s stop"
    ]
  }

  tags = {
    Name = "K3S server"
  }
}
