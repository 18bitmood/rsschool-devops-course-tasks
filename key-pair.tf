resource "aws_key_pair" "keys" {
  key_name   = var.bastion_key_name
  public_key = file("./${var.bastion_key_name}.pub")
}
