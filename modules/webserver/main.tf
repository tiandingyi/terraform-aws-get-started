resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id  

    //允许本机IP地址ssh连接
    ingress  {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [ var.my_ip ]
    } 

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    //配置出口允许的流量不设限制
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
        prefix_list_ids = [ ]
    }

    tags = {
      Name : "${var.env_prefix}-sg"
    }
  
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = [ "amazon" ]
    //过滤器，用于筛选
    filter {
        name = "name"
        //可以使用正则表达式
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = [ "hvm" ]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    //公钥地址，用于ssh连接
    public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
    //之所以动态获取ID是因为ID不是固定的
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
    availability_zone = var.avail_zone

    //是否将公网 IP 地址与 VPC 中的实例关联。
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    //不实用绝对路径会报错，提示识别不到
    user_data = file("/Users/dingyi.tian/Desktop/terraform/modules/webserver/entry-script.sh")

    tags = {
      Name : "${var.env_prefix}-server"
    }


  
}