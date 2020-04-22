provider "alicloud" {
  region     = "cn-shenzhen"
}

module "ecs_sg" {
  source                        = "../../modules/security_group/ecs_sg"
  env                           = "stg"  
  ecs_sg_name                   = "member-union-account-system"
  vpc_id                        = "vpc-wz9fx48s44dbsx2sbp3sn"
  inbound_rules = {
    "0" = [ "tcp","443/443","0.0.0.0/0" ]
    "1" = [ "tcp","80/80","0.0.0.0/0" ] 
    "2" = [ "tcp","22/22","0.0.0.0/0" ]    
  }
  outbound_rules = {
    "0" = [ "all","-1/-1","0.0.0.0/0" ]
  }  
}

module "slb" {
  source                        = "../../modules/slb/slb_http""
  env                           = "stg"
  slb_name                      = "member-union-account-system"
  vswitch_id                    = "vsw-wz9pjabqeit12ai79nif7"
  master_zone_id                = "cn-shenzhen-a"
  slave_zone_id                 = ""
  internet                      = true
  health_check_uri              = "/health_check"
  health_check_http_code        = "http_2xx,http_3xx"
}

module "ess" {
  source                        = "../../modules/ess"
  env                           = "stg"
  scaling_group_name            = "member-union-account-system"
  instance_name                 = "member-union-account-system"
  instance_type                 = "ecs.t5-lc1m2.small"
  image_id                      = "m-wz91w1somomxo2u0rqng"
  system_disk_size              = "100"
  system_disk_category          = "cloud_ssd"
  security_group_id             = "${module.ecs_sg.ecs_sg_id}"
  min_size                      = "1"
  max_size                      = "1"
  adjustment_type               = "TotalCapacity"
  adjustment_value              = "2"
  key_name                      = "ali-mem"
  role_name                     = "ansible-oss-pull"
  vswitch_ids                   = ["vsw-wz9pjabqeit12ai79nif7","vsw-wz9dw5uywqhwdvshf27ke"]
  loadbalancer_ids              = ["${module.slb.slb_id}"]
  db_instance_ids               = ["${module.rds.rds_id}"]
  multi_az_policy               = "BALANCE"
  
  userdata_CODE_SERVER          = "172.21.15.239:82"
  userdata_ENV_HOME             = "/root"
  userdata_OSS_ANSIBLE          = "dd01mem-devops-ansible"
  userdata_VAR_PLAYBOOKS        = [
    "playbooks/common/load-sshkey-member-stg.yml",
    "playbooks/common/sysctl.yml",
    "playbooks/site-member-union-account-system.yml",
  ]
}

module "rds" {
  source                        = "../../modules/rds"
  env                           = "stg"
  engine                        = "MySQL"
  engine_version                = "5.7"
  instance_name                 = "member-union-account-system"
  instance_type                 = "rds.mysql.t1.small"
  instance_storage              = "30"
  zone_id                       = "cn-shenzhen-c"
  vswitch_id                    = "vsw-wz9s0km2hf3s715myu5qu"

  database_name                 = "union-account-system"
  character_set                 = "utf8"
  username                      = "dadi01"
  password                      = "jwWXYiZITza05BUj"
}

module "redis" {
  source                        = "../../modules/redis"
  env                           = "stg"
  instance_name                 = "member-union-account-system"
  engine                        = "Redis"
  engine_version                = "4.0"
  instance_class                = "redis.master.small.default"           
  password                      = "jwWXYiZITza05BUj"
  #availability_zone             = "cn-shenzhen-a"
  vswitch_id                    = "vsw-wz9pjabqeit12ai79nif7"
  security_ips                  = ["172.21.0.0/16"]
}