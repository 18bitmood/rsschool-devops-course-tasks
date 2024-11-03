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
      # Wait for k3s to be ready
      "sudo kubectl wait --for=condition=Ready node --all --timeout=60s",
      # Install Helm
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "sudo ./get_helm.sh",
      # Set local-path as default storage class
      "sudo kubectl patch storageclass local-path -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'",
      # Create namespace for Jenkins
      "sudo kubectl create namespace jenkins",
      # Add the Jenkins Helm repository
      "sudo helm repo add jenkins https://charts.jenkins.io",
      "sudo helm repo update",
      # Transfer Jenkins configuration to server
      "echo '${file("./jenkins-values.yaml")}' > /home/ubuntu/jenkins-values.yaml",
      # Restart as the process might be fallen
      "sudo systemctl restart k3s",
      # Export KUBECONFIG for helm
      "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml",
      "sudo chmod 644 /etc/rancher/k3s/k3s.yaml",
      # Configure DNS for k3s
      "sudo kubectl -n kube-system rollout restart deployment coredns",
      "sudo kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=kube-dns --timeout=60s",
      # Verify DNS resolution
      "sudo kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 --command -- sleep 3600",
      "sudo kubectl wait --for=condition=Ready pod/dnsutils --timeout=60s",
      # Create plugins directory
      "mkdir -p /home/ubuntu/jenkins-plugins",
      # Download essential plugins
      "curl -L https://updates.jenkins.io/download/plugins/workflow-aggregator/latest/workflow-aggregator.hpi -o /home/ubuntu/jenkins-plugins/workflow-aggregator.hpi",
      "curl -L https://updates.jenkins.io/download/plugins/git/latest/git.hpi -o /home/ubuntu/jenkins-plugins/git.hpi",
      # Update Helm values to use local plugins
      "echo 'controller.installPlugins: false' >> /home/ubuntu/jenkins-values.yaml",
      "echo 'controller.additionalPlugins: []' >> /home/ubuntu/jenkins-values.yaml",
      # Install Jenkins using Helm
      "sudo helm install jenkins jenkins/jenkins --namespace jenkins --create-namespace --set controller.serviceType=NodePort --set controller.installPlugins=false --set controller.additionalPlugins=[] -f /home/ubuntu/jenkins-values.yaml --kubeconfig /etc/rancher/k3s/k3s.yaml",

      # "sudo helm install jenkins jenkins/jenkins --namespace jenkins --create-namespace --set controller.serviceType=NodePort -f /home/ubuntu/jenkins-values.yaml --kubeconfig /etc/rancher/k3s/k3s.yaml",
      # Wait for Jenkins to be ready
      # "sudo kubectl wait --for=condition=Ready pod --all --namespace jenkins --timeout=60s",
      # Change ownership of Jenkins volume
      # "sudo chown -R 1000:1000 /var/jenkins_volume",
      # Stop k3s to being able to do ssh 
      "sudo systemctl stop k3s"
    ]
  }

  tags = {
    Name = "K3S server"
  }
}
