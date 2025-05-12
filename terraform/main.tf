provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer"{
  key_name   = "deployer-key"
  public_key = file("/home/danan/.ssh/id_rsa.pub")
}

resource "aws_instance" "web" {
  ami                    = "ami-084568db4383264d4" # Ubuntu 20.04
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "TerraformWeb"
  }

  provisioner "local-exec" {
  command = "echo '[web]\n${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/danan/.ssh/id_rsa' > ../ansible/hosts.ini"
  }
}

output "instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}
