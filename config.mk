S3_BUCKET_REF    := sider-ref
GENOME_PATH      := /home/genomes/Homo_sapiens/hg38/hg38.25chr.fa.gz
ANNOTATION_PATH  := /home/projects2/databases/gencode/release36/gencode.v36.annotation.gtf.gz
ECR_IMAGE        := siderp
ECR_IMAGE_TAG    := latest
IAM_ROLE_BATCH   := siderAWSBatchRole
IAM_POLICY_BATCH := siderAWSBatchPolicy
EC2_KEY_PAIR     := sider-key-pair
