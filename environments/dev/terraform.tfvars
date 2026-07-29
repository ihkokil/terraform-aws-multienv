region                      = "us-east-1"
project_name                = "myapp"
vpc_cidr                    = "10.1.0.0/16"
public_subnet_cidrs         = ["10.1.1.0/24"]
private_subnet_cidrs        = ["10.1.10.0/24"]
app_runner_cpu              = "256"
app_runner_memory           = "512"
secret_recovery_window_days = 0
ec2_instance_type           = "t3.micro"
tags = {
  Owner = "dev-team"
}
