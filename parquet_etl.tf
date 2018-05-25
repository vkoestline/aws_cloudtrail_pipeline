/**
 * AWS Glue ETL module
 */



# --------------------------------------
# IAM role for the ETL Job
# --------------------------------------
resource "aws_iam_role" "glue_etl_role" {
  name = "${var.etl_job_name}-glue-etl-role"

  assume_role_policy = <<EOF
{
  "Statement": {
    "Effect": "Allow",
    "Principal": { 
      "Service": "glue.amazonaws.com" 
    },
    "Action": "sts:AssumeRole"
  }
}
EOF
}

# --------------------------------------
# IAM policy for the stream
# --------------------------------------
resource "aws_iam_policy" "glue_etl_policy" {
  name        = "${var.etl_job_name}-glue-etl-policy"
  path        = "/"
  description = "Policy to allow Glue ETL do its thing"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:*",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListAllMyBuckets",
        "s3:GetBucketAcl",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeRouteTables",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcAttribute",
        "iam:ListRolePolicies",
        "iam:GetRole",
        "iam:GetRolePolicy"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket"
      ],
      "Resource": [
        "arn:aws:s3:::aws-glue-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::aws-glue-*/*",
        "arn:aws:s3:::*/*aws-glue-*/*",
        "arn:aws:s3:::${element(split("/", var.etl_destination_bucket), 0)}*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::crawler-public*",
        "arn:aws:s3:::aws-glue-*",
        "arn:aws:s3:::${var.etl_script_bucket}*",
        "arn:aws:s3:::${var.etl_source_bucket}*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:/aws-glue/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Condition": {
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "aws-glue-service-resource"
          ]
        }
      },
      "Resource": [
        "arn:aws:ec2:*:*:network-interface/*",
        "arn:aws:ec2:*:*:security-group/*",
        "arn:aws:ec2:*:*:instance/*"
      ]
    }
  ]
}
EOF
}

# --------------------------------------
# Attaching role to the policy
# --------------------------------------
resource "aws_iam_policy_attachment" "glue_etl_policy_attach" {
  name       = "${var.etl_job_name}-glue-etl-attachment"
  roles      = ["${aws_iam_role.glue_etl_role.name}"]
  policy_arn = "${aws_iam_policy.glue_etl_policy.arn}"
}

# --------------------------------------
# Parameterize CloudFormation Template
# --------------------------------------
data "template_file" "etl_cf_template" {
  template = "${file("${path.module}/etl_cf_template.json")}"
}

# --------------------------------------
# Upload script to S3
# --------------------------------------
resource "aws_s3_bucket_object" "etl_job_script" {
  bucket = "${var.etl_script_bucket}"
  key    = "parquetizer.py"
  source = "${path.module}/parquetizer.py"
  etag   = "${md5(file("${path.module}/parquetizer.py"))}"

}

# --------------------------------------
# Creating Glue ETL Job
# --------------------------------------
resource "aws_cloudformation_stack" "glue_etl" {
  name = "${var.etl_job_name}-parquetizer"

  parameters {
    RoleArn           = "${aws_iam_role.glue_etl_role.arn}"
    Description       = "Parquetizer ETL job transform the data to have a flat structure in clolumnar format"
    ScriptLocation    = "s3://${var.etl_script_bucket}/parquetizer.py"
    TempDir           = "s3://${var.etl_source_bucket}/temporary-files/${var.etl_readfrom_db}/${var.etl_readfrom_table}"
    ETLName           = "${var.etl_job_name}"
    DatabaseName      = "${var.etl_readfrom_db}"
    TableName         = "${var.etl_readfrom_table}"
    DestinationBucket = "${var.etl_destination_bucket}"
    JobCronSchedule   = "${var.etl_job_cron_schedule}"
    TriggerName       = "${var.etl_job_name}-trigger"
  }

  template_body = "${data.template_file.etl_cf_template.rendered}"

  # Activate Job Trigger
  provisioner "local-exec" {
    command = "aws glue start-trigger --name=${var.etl_job_name}-trigger --region ${var.region}"
  }
}
