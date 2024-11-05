# resource "aws_network_interface" "nat_eni" {
#   subnet_id         = aws_subnet.public_subnets[0].id
#   security_groups   = [aws_security_group.allow_all.id]
#   source_dest_check = false

#   tags = {
#     Name = "NAT ENI"
#   }
# }

# resource "aws_instance" "nat_instance" {
#   ami           = "ami-005fc0f236362e99f"
#   instance_type = "t2.micro"
#   key_name      = aws_key_pair.keys.key_name

#   network_interface {
#     network_interface_id = aws_network_interface.nat_eni.id
#     device_index         = 0
#   }

#   user_data = <<-EOF
#               #!/bin/bash
#               echo 1 > /proc/sys/net/ipv4/ip_forward
#               iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#               iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
#               iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
#               EOF

#   tags = {
#     Name = "NAT Instance"
#   }
# }

# resource "aws_eip" "nat_eip" {
#   network_interface         = aws_network_interface.nat_eni.id
#   associate_with_private_ip = aws_network_interface.nat_eni.private_ip
#   depends_on                = [aws_instance.nat_instance]
# }

# resource "aws_route_table" "private_route_table" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block           = "0.0.0.0/0"
#     network_interface_id = aws_network_interface.nat_eni.id
#   }

#   tags = {
#     Name = "Private Route Table"
#   }
# }

# resource "aws_route_table_association" "private_route_table_association" {
#   count          = length(var.private_subnet_cidrs)
#   subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
#   route_table_id = aws_route_table.private_route_table.id
# }
