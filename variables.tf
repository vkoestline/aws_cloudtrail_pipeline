variable "region" {
  description = "AWS region"
  default = "us-west-2"
}

variable "aws_account_id" {
  default = "110337815507"
}

variable "bucket_name" {
  type = "string"
  description = "bucket to have cloudtrail data written to"
  default = "my-log-repository-logs"
}

variable "cloudtrail_name" {
  type = "string"
  description = "Name of the cloudtrail trail"
  default = "cloudtrail"
}

variable "initial_crawler_name" {
  default = "initial-crawler"
}

variable "initial_crawler_description" {
  default = "Description for the crawler"
}

variable "initial_crawler_path" {
  type = "string"
  description = "Path to the bucket on S3 where files are located"
  default = "CloudTrail"
}

variable "initial_crawler_schedule" {
  type = "string"
  description = "Cron string for run schedule"
  default = "cron(0 0 * * ? *)"
}

variable "initial_database_name" {
  type = "string"
  description = "Database created from initial crawler"
  default = "cloudtrail"
}

variable "parquet_crawler_name" {
  default = "parquet-crawler"
}

variable "parquet_crawler_description" {
  default = "Description for the crawler"
}

variable "parquet_crawler_path" {
  type = "string"
  description = "Path to the bucket on S3 where files are located"
  default = "my-log-repository-logs"
}

variable "parquet_crawler_schedule" {
  type = "string"
  description = "Cron string for run schedule"
  default = "cron(0 2 * * ? *)"
}

variable "parquet_database_name" {
  type = "string"
  description = "Database created from parquet crawler"
  default = "parquet"
}

variable "update_behavior" {
  type = "string"
  description = "What to do when schema change is detected. Possible values are 'LOG' and 'UPDATE_IN_DATABASE'"
  default = "UPDATE_IN_DATABASE"
}

variable "delete_behavior" {
  type = "string"
  description = "What to do when data deletion is detected. Possible values are 'LOG', 'DELETE_FROM_DATABASE', 'DEPRECATE_IN_DATABASE'e"
  default = "LOG"
}

variable "etl_job_name" {
  type = "string"
  description = "Name of the ETL job"
  default = "parquetizer"
}

variable "etl_readfrom_db" {
  type = "string"
  description = "Database to read from"
  default = "cloudtrail"
}

variable "etl_readfrom_table" {
  type = "string"
  description = "Table to read from"
  default = "cloudtrail"
}

variable "etl_source_bucket" {
  type = "string"
  description = "S3 bucket where data files are located"
  default = "my-log-repository-logs" 
}

variable "etl_destination_bucket" {
  type = "string"
  description = "Where to store parquet files"
  default = "my-log-repository-logs"
}

variable "etl_script_bucket" {
  type = "string"
  description = "S3 bucket where job script will be uploaded"
  default = "my-log-repository-logs"
}

variable "etl_job_cron_schedule" {
  type = "string"
  description = "Cron string for job scheduling"
  default = "cron(0 1 * * ? *)"
}

#
#variable "pipeline_name" {
#  type = "string"
#  description = "Pipeline_name to uniquify resource names"
#  default = "cloudtrail"
#}
