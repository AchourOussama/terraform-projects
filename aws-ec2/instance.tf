resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

output "public_key" {
  value = aws_key_pair.mykey
}

output "aws_public_dns" {
  value = aws_instance.example.public_dns
}

resource "aws_instance" "example" {
  ami           = var.AMIS[var. AWS_REGION]
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mykey.key_name
  #try :  output the keyname
  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo sed -i -e 's/\r$//' /tmp/script.sh",  # Remove the spurious CR characters.
      "sudo /tmp/script.sh",
    ]
  }
  # common practice : place the connection block near the end of the resource block for readablilty
  # the connection block executes during the creation of the resource: during 'terraform run'
  connection {
    #since the connection block is nested inside the aws_instance resource block , we extract the instance's attributes using 'self'
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout = "2m"
  }
}
