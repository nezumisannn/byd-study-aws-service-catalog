locals {
  public_key_file  = "./.key/${var.project}-key.id_rsa.pub"
  private_key_file = "./.key/${var.project}-key.id_rsa"
}

resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh
  provisioner "local-exec" {
    command = "chmod 600 ${local.public_key_file}"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.project}-key"
  public_key = tls_private_key.keygen.public_key_openssh
}

resource "aws_security_group" "allow_ssh" {
  name        = "${var.project}-allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "instance" {
  ami                    = "ami-03f584e50b2d32776"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "${var.project}-instance"
  }
}