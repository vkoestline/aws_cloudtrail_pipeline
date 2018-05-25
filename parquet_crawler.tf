/**
 * AWS Glue Crawler module
 */


# --------------------------------------
# IAM role for the stream
# --------------------------------------
resource "aws_iam_role" "parquet_glue_role" {
  name = "parquet-glue-role"

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
resource "aws_iam_policy" "parquet_glue_policy" {
  name        = "parquet-glue-policy"
  path        = "/"
  description = "Policy to allow Glue do its thing"

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
        "arn:aws:s3:::*/*aws-glue-*/*"
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
        "arn:aws:s3:::${var.parquet_crawler_path}*"
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
resource "aws_iam_policy_attachment" "parquet_glue_policy_attach" {
  name       = "parquet-glue-attachment"
  roles      = ["${aws_iam_role.parquet_glue_role.name}"]
  policy_arn = "${aws_iam_policy.parquet_glue_policy.arn}"
}

# --------------------------------------
# Creating Glue Catalog Database
# --------------------------------------
resource "aws_glue_catalog_database" "parquet_database" {
  name = "${var.parquet_database_name}"
}


# --------------------------------------
# Parameterize CloudFormation Template
# --------------------------------------
data "template_file" "parquet_cf_template" {
  template = "${file("${path.module}/second_crawler_cf_template.json")}"
}

# --------------------------------------
# Creating Glue Crawler
# --------------------------------------
resource "aws_cloudformation_stack" "parquet_glue_crawler" {
  name = "parquet-cloudtrail-glue-crawler"

  parameters {
    RoleArn      = "${aws_iam_role.parquet_glue_role.arn}"
    Description  = "${var.parquet_crawler_description}"
    DatabaseName = "${var.parquet_database_name}"
    S3TargetPath = "${var.bucket_name}/parquetfiles"
    CrawlerName  = "${var.parquet_crawler_name}"
    RunShedule   = "${var.parquet_crawler_schedule}"
    
    UpdateBehavior = "${var.update_behavior}"
    DeleteBehavior = "${var.delete_behavior}"
  }

  template_body = "${data.template_file.parquet_cf_template.rendered}"

  depends_on = ["aws_iam_policy_attachment.parquet_glue_policy_attach", "aws_iam_policy.parquet_glue_policy", "aws_iam_role.parquet_glue_role"]

  provisioner "local-exec" {
    command = <<EOF
aws glue update-crawler \
  --name ${var.parquet_crawler_name} \
  --configuration "{  \"Version\":  1.0,  \"CrawlerOutput\":  {  \"Partitions\":  { \"AddOrUpdateBehavior\": \"InheritFromTable\" } } }" \
  --region ${var.region}
EOF
  }
}
