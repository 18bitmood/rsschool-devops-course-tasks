resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    rule_no    = 100
  }

  ingress {
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    cidr_block = "10.0.0.0/16"
    action     = "allow"
    rule_no    = 101
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
