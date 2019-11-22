###############################################################################
# 11 : Upload Public key for access to EC2 instances
###############################################################################
resource "aws_key_pair" "default" {
  key_name = "${var.pub_key_name}"
  public_key = "${file("${var.pub_key_path}")}"
}

###############################################################################
# 12 : Create EC2 Instance
#
# Execute install.sh for Ubuntu to configure
#   NGINX, CERTBOT
#   Pull git repos with websites
#
###############################################################################
resource "aws_instance" "wb" {
    ami  = "${var.ami}"
    instance_type = "${var.instance_type}"
    key_name = "${var.pub_key_name}"
    subnet_id = "${aws_subnet.subnet-1.id}"
    vpc_security_group_ids = ["${aws_security_group.sgpub.id}",
                              "${aws_security_group.sgpubssh.id}"]
    associate_public_ip_address = true
    availability_zone = "${var.az_a}"
    tags = {
      Name = "${var.project_name}"
      Author = "${var.author_name}"
    }
#    provisioner "file" {
#        source      = "install.sh"
#        destination = "/tmp/install.sh"
#    }
#    provisioner "remote-exec" {
#        inline = [
#          "chmod +x /tmp/install.sh",
#          "/tmp/install.sh",
#        ]
#    }
}

###############################################################################
# 13 : Assign Existing EIP
#
# NOTE: I have an EIP already and assign it in the variables. If it sits
#  without being assigned to an instance or nat gateway, it will occur hourly
#  charges!!!!!
###############################################################################
resource "aws_eip_association" "static_ip" {
  instance_id   = "${aws_instance.wb.id}"
  public_ip = "${var.instance_assigned_elastic_ip}"
}

###############################################################################
# WAIT : Create CloudWatch Alarm to restart the instance if unreachable
###############################################################################
# resource "aws_cloudwatch_metric_alarm" "autorecover" {
#   alarm_name          = "ec2-autorecover-High-Status-Check-Failed"
#   namespace           = "AWS/EC2"
#   evaluation_periods  = "2"
#   period              = "60"
#   alarm_description   = "This metric auto recovers EC2 instances"
#   alarm_actions       = ["arn:aws:automate:${var.aws_region}:ec2:reboot"]
#   statistic           = "Maximum"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   threshold           = "1"
#   metric_name         = "StatusCheckFailed"
#   dimensions = {
#     #InstanceId = "${aws_instance.wb.id}"
#     HealthCheckId           = "${aws_route53_health_check.port443_health_check.id}"
#   }
#   tags = {
#     #Name = "CloudWatch Alarm EC2 Instance Unreachable"
#     Name = "CW Alarm - EC2 Port 443 Unreachable"
#     Author = "${var.author_name}"
#   }
# }
###############################################################################
# WAIT : Don't want to apply these until webserver is up and running! 
#        port 443 won't be avail on the domain until the server is configured!
###############################################################################
# resource "aws_route53_health_check" "port443_health_check" {
#   fqdn              = "${var.domain_name}"
#   port              = 443
#   type              = "HTTPS"
#   resource_path     = "/"
#   failure_threshold = "5"
#   request_interval  = "30"

#   tags = {
#     Name = "tf-test-health-check"
#     Author = "${var.author_name}"
#   }
# }