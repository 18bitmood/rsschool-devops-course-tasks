resource "aws_instance" "app_server" {
  ami           = "ami-055744c75048d8296"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
