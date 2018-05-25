import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3
import time

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DB_NAME', 'TABLE_NAME', 'DEST_BUCKET'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

datasource0 = glueContext.create_dynamic_frame.from_catalog(database = args["DB_NAME"], table_name = args["TABLE_NAME"], transformation_ctx = "datasource0")
resolvechoice1 = ResolveChoice.apply(frame = datasource0, choice = "make_struct", transformation_ctx = "resolvechoice1")
relationalized1 = resolvechoice1.relationalize("trail", args["TempDir"]).select("trail")
datasink = glueContext.write_dynamic_frame.from_options(frame = relationalized1, connection_type = "s3", connection_options = {"path": "s3://{}/parquettrails".format(args["DEST_BUCKET"])}, format = "parquet", transformation_ctx = "datasink4")
job.commit()
