provider "aws" {
  region = "ap-south-1"  # Change this to your desired region
}

################# Defining Variable
variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "wp"  # Specify the desired database name here
}
variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "thiru"  # Specify the desired username here
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  default     = "thiru1234"  # Specify the desired password here
}


######################## Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
      tags = {
    Name = "Main_VPC"
  }
}

######################## Create public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"  # Change this to your desired availability zone
  map_public_ip_on_launch = true
      tags = {
    Name = "Public_Subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"  # Change this to your desired availability zone
  map_public_ip_on_launch = true
    tags = {
    Name = "Public_Subnet_2"
  }
}
######################## Create private subnet
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Private_Subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Private_Subnet_2"
  }
}

######################## Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
    tags = {
    Name = "IGW"
  }
}

resource "aws_eip" "nat_eip" {
  instance = null
    tags = {
    Name = "EIP"
  }
}

######################## Create NAT Gateway for private subnets
resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public_subnet_2.id
  allocation_id = aws_eip.nat_eip.id
    tags = {
    Name = "NAT"
  }
}
######################### Create Route Table for public subnet
resource "aws_route_table" "public_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
    tags = {
    Name = "Public_RT_1"
  }
}
resource "aws_route_table" "public_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
    tags = {
    Name = "Public_RT_2"
  }
}
######################## Public Subnet Association to Route Table
resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_1.id
}

resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_1.id
}
####################### Create Route Table for private subnets
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
    tags = {
    Name = "Private_RT_1"
  }
}
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
    tags = {
    Name = "Private_RT_2"
  }
}


######################## Private Subnet Association to Route Table
resource "aws_route_table_association" "private_subnet_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_2.id
}
######################## Create a security group for the Bastion host
resource "aws_security_group" "bastion_security_group" {
  name = "bastion_host"  # Set the name to "bastion_host"

  vpc_id = aws_vpc.main.id  # Replace with your VPC ID

  // Inbound rule allowing traffic on port 22 (SSH) from any source
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound rule allowing all traffic to any destination on any port
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Bastion_SG"
  }
}

######################## Outputs the security group ID
output "public_security_group_id" {
  value = aws_security_group.bastion_security_group.id
 
}
######################## Create a security group for alb
resource "aws_security_group" "alb_security_group" {
  name = "alb"  # Set the name to "alb"

  vpc_id = aws_vpc.main.id  # Replace with your VPC ID

  // Inbound rule allowing traffic on port 80 (http) from any source
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // Inbound rule allowing traffic on port 443 (https) from any source
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound rule allowing all traffic to any destination on any port
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
    Name = "ALB_SG"
  }
}

######################## Outputs the security group ID
output "alb_security_group_id" {
  value = aws_security_group.alb_security_group.id

}

######################### Create a security group for private
resource "aws_security_group" "private_security_group" {
  name = "private"  # Set the name to "private"

  vpc_id = aws_vpc.main.id  # Replace with your VPC ID

  // Inbound rule allowing traffic on port 22 (SSH) from bastion host
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
   security_groups = [aws_security_group.bastion_security_group.id]
  }
  // Inbound rule allowing traffic on port 80 (http) from alb
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
   security_groups = [aws_security_group.alb_security_group.id]
  }
  // Inbound rule allowing traffic on port 443 (https) from any source
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  // Outbound rule allowing all traffic to any destination on any port
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "Private_Instance_SG"
	}
}

########################## Outputs the security group ID
output "private_security_group_id" {
  value = aws_security_group.private_security_group.id  
}

resource "aws_security_group" "db_security_group" {
  name = "db"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.private_security_group.id]  // Allow only private instances to access DB
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB_SG"
  }
}
######################## Outputs the security group ID
output "db_security_group_id" {
  value = aws_security_group.db_security_group.id
 
}
######################### Create EC2 Instances
resource "aws_instance" "public_instance" {
  ami           = "ami-0b41f7055516b991a"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  count         = 1
  subnet_id     = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_security_group.id]
  key_name      = "webserver"  # Replace with your key pair name
      tags = {
	Name = "Bastion_Host"
  }
}

resource "aws_instance" "private_instances" {
  ami           = "ami-0b41f7055516b991a"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  count         = 2  # Changed to 4 private instances
  subnet_id     = count.index % 2 == 0 ? aws_subnet.private_subnet_1.id : aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  key_name      = "webserver"  # Replace with your key pair name
  
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y

    # Enable and install PHP 7.4 from Amazon Linux Extras
    sudo amazon-linux-extras install php7.4 -y
    sudo yum install php php-mysqlnd -y  # Ensure php-mysqlnd is installed

    # Install Apache
    sudo yum install httpd -y

    # Install wget
    sudo yum install wget -y

    # Download and install WordPress
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    sudo mkdir -p /var/www/html/
    sudo mv wordpress/* /var/www/html/

    # Set permissions
    sudo chown -R apache:apache /var/www/html/
    sudo chmod -R 755 /var/www/html/

    # Configure WordPress
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/${var.db_name}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${var.db_username}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${var.db_password}/" /var/www/html/wp-config.php
    sed -i "s/localhost/${aws_db_instance.db_instance.address}/" /var/www/html/wp-config.php

    # Restart Apache
    sudo systemctl restart httpd
    sudo systemctl enable httpd
  EOF
  tags = {
    Name = "Webserver-${count.index + 1}"
  }
}


##################### ALB
resource "aws_lb" "my_load_balancer" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  enable_deletion_protection = false

  enable_http2 = true

  enable_cross_zone_load_balancing = true

    subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

}

resource "aws_lb_target_group" "web_target_group" {
  name        = "web-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.main.id

  health_check {
    path        = "/"
    port        = 80
    protocol    = "HTTP"
    interval    = 30
    timeout     = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.my_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}

###################### Instances Attachement
resource "aws_lb_target_group_attachment" "private_to_target_group" {
  count           = 2
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id       = aws_instance.private_instances[count.index].id
  port            = 80
}


######################### Create DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}
######################### Create RDS Instance
resource "aws_db_instance" "db_instance" {
  identifier           = "db-instance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name		       = "wp"
  username             = "thiru"
  password             = "thiru1234"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible  = false
  multi_az             = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_security_group.id]

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name


  tags = {
    Name = "MyRDSInstance"
  }
}
