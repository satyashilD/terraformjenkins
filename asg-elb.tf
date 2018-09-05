provider "aws" {
  region = "ap-south-1"
  }

resource "aws_launch_configuration" "test_lc" {
  name          = "web_config"
  image_id      = "ami-00b6a8a2bd28daf19"
  instance_type = "t2.micro"
  security_groups = ["sg-19707a72"]
  #subnet_id = "subnet-d59a3eaf"
  connection {
  user = "ec2-user"
  key_file ="https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:sort=keyName"
  }
  key_name = "Jenkins"
  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "8"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    },
  ]
  
}
#########ASG########################

resource "aws_autoscaling_group" "asg_test" {
  name                 = "terraform-asg-example"
  launch_configuration = "${aws_launch_configuration.test_lc.name}"
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier  = ["subnet-a613a9ce"]
  lifecycle {
    create_before_destroy = true
  }
  load_balancers       = ["${aws_elb.bar.id}"]
}


#############ELB#################
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-east-2a", "us-east-2b"]

#  access_logs {
#    bucket        = "foo"
#    bucket_prefix = "bar"
#    interval      = 60
#  }

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

# instances                   = ["${aws_autoscaling_group.asg_test.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "foobar-terraform-elb"
  }
}

#resource "aws_autoscaling_attachment" "asg_attachment_bar" {
#  autoscaling_group_name = "${aws_autoscaling_group.asg_test.id}"
#  elb                    = "${aws_elb.bar.id}"
#}
