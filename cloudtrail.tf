/**
 * AWS Cloudtrail module
 */



# --------------------------------------
# Cloudtrail resource
# --------------------------------------
resource "aws_cloudtrail" "cloudtrail" {
  name                       = "internal_cloudtrail"
  s3_bucket_name             = "${var.bucket_name}"
  #s3_key_prefix              = "${var.folder_name}"
  s3_key_prefix              = "Logs"
  is_multi_region_trail      = true
  enable_log_file_validation = true

  # Get all s3 bucket data
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  # Get all lambda data
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}
