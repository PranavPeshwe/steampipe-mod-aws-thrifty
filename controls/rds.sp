variable "rds_db_instance_avg_connections" {
  type        = number
  description = "The minimum number of average connections per day required for DB instances to be considered in-use."
  default     = 2
}

variable "rds_db_instance_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
  default     = 50
}

variable "rds_db_instance_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
  default     = 25
}

variable "rds_running_db_instance_age_max_days" {
  type        = number
  description = "The maximum number of days DB instances are allowed to run."
  default     = 90
}

variable "rds_running_db_instance_age_warning_days" {
  type        = number
  description = "The number of days DB instances can be running before sending a warning."
  default     = 30
}

locals {
  rds_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/RDS"
  })
}

benchmark "rds" {
  title         = "RDS Checks"
  description   = "Thrifty developers eliminate unused and under-utilized RDS instances."
  documentation = file("./controls/docs/rds.md")
  children = [
    control.rds_db_instance_class_prev_gen,
    control.rds_db_instance_age_90,
    control.rds_db_instance_low_connections,
    control.rds_db_instance_low_usage
  ]

  tags = merge(local.rds_common_tags, {
    type = "Benchmark"
  })
}

control "rds_db_instance_age_90" {
  title         = "Long running RDS DBs should have reserved instances purchased for them"
  description   = "Long running database servers should be associated with a reserve instance."
  sql           = query.rds_db_instance_age_90.sql
  severity      = "low"

  param "rds_running_db_instance_age_max_days" {
    description = "The maximum number of days DB instances are allowed to run."
    default     = var.rds_running_db_instance_age_max_days
  }

  param "rds_running_db_instance_age_warning_days" {
    description = "The number of days DB instances can be running before sending a warning."
    default     = var.rds_running_db_instance_age_warning_days
  }

  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}


control "rds_db_instance_class_prev_gen" {
  title         = "Are there RDS instances using previous gen instance types?"
  description   = "M5 and T3 instance types are less costly than previous generations"
  sql           = query.rds_db_instance_class_prev_gen.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}

control "rds_db_instance_low_connections" {
  title         = "RDS DB instances with a low number connections per day should be reviewed"
  description   = "These databases have very little usage in last 30 days. Should this instance be shutdown when not in use?"
  sql           = query.rds_db_instance_low_connections.sql
  severity      = "high"

  param "rds_db_instance_avg_connections" {
    description = "The minimum number of average connections per day required for DB instances to be considered in-use."
    default     = var.rds_db_instance_avg_connections
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}

control "rds_db_instance_low_usage" {
  title         = "RDS DB instance having low CPU utilization should be reviewed"
  description   = "These databases may be oversized for their usage."
  sql           = query.rds_db_instance_low_usage.sql
  severity      = "low"

  param "rds_db_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
    default     = var.rds_db_instance_avg_cpu_utilization_low
  }

  param "rds_db_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
    default     = var.rds_db_instance_avg_cpu_utilization_high
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}
