# Use existing VPC
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "cidr"
    values = ["172.31.0.0/16"] # Existing VPC CIDR
  }
}

# Use existing Subnet
data "aws_subnet" "existing_subnet" {
  filter {
    name   = "cidr-block"
    values = ["172.31.32.0/20"] # Subnet CIDR you want
  }
  vpc_id = data.aws_vpc.existing_vpc.id
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "trend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "trendm-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Security Group (use your existing SG)
data "aws_security_group" "existing_sg" {
  id = "sg-0f17f39f935d2e732"
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = "ami-0c65adc9a5c1b5d7c"
  instance_type               = "t2.micro"
  key_name                    = "ubuntu-ssh"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = data.aws_subnet.existing_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.aws_security_group.existing_sg.id]

  
  user_data = <<-EOF
            #!/bin/bash
            set -eux

            apt-get update -y

            # Install required packages
            apt-get install -y openjdk-17-jdk curl gnupg ca-certificates

            # Create keyrings directory
            mkdir -p /usr/share/keyrings

            # Add Jenkins GPG key properly
            curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
              | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

            # Add Jenkins repo with signed-by
            echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
              > /etc/apt/sources.list.d/jenkins.list

            # Update and install Jenkins
            apt-get update -y
            apt-get install -y jenkins

            # Start Jenkins
            systemctl enable jenkins
            systemctl start jenkins
            EOF

  tags = {
    Name = "trend-ec2-jenkins"
  }
}










