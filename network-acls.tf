resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main.id
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 255
  }

  ingress {
    protocol   = "-1"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "icmp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 255
  }

  egress {
    protocol   = "-1"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Public ACL"
  }
}


resource "aws_network_acl_association" "public_acl_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  network_acl_id = aws_network_acl.public_acl.id
}

resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    cidr_block = "10.0.0.0/16"
    action     = "allow"
    rule_no    = 100
  }

  ingress {
    protocol   = "icmp"
    from_port  = 0
    to_port    = 255
    icmp_type  = -1
    icmp_code  = -1
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    rule_no    = 101
  }

  ingress {
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    rule_no    = 102
  }

  egress {
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    rule_no    = 100
  }

  tags = {
    Name = "Private ACL"
  }
}

resource "aws_network_acl_association" "private_acl_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  network_acl_id = aws_network_acl.private_acl.id
}
