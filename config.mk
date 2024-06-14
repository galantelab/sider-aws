AWS_REGION           := us-east-1
AWS_REGION_ZONES     := a b c d e f
S3_BUCKET_REF        := sider-ref
GENOME_PATH          := /home/genomes/Homo_sapiens/hg38/hg38.25chr.fa.gz
ANNOTATION_PATH      := /home/projects2/databases/gencode/release36/gencode.v36.annotation.gtf.gz
ECR_IMAGE            := siderp
ECR_IMAGE_TAG        := latest
IAM_SERVICE_ROLE     := siderAWSBatchServiceRole
IAM_INSTANCE_PROFILE := siderAWSBatchInstanceProfile
IAM_INSTANCE_ROLE    := siderAWSBatchInstanceRole
IAM_INSTANCE_POLICY  := siderAWSBatchInstancePolice
EC2_KEY_PAIR         := sider-key-pair
EC2_SECURITY_GROUP   := sider-sg
EC2_LAUNCH_TEMPLATE  := sider-launch-template
EC2_IMAGE_ID         := ami-066d355e52dd737a4
EC2_INSTANCE_TYPE    := r5.2xlarge
EC2_INSTANCE_CPUS    := 8
EC2_INSTANCE_MEM     := 65536
EBS_VOLUME_TYPE      := gp3
EBS_VOLUME_SIZE      := 5120
BATCH_MINVCPUS       := 0
BATCH_DESIREDVCPUS   := 8
BATCH_MAXVCPUS       := 8000
BATCH_COMP_ENV       := sider-env
BATCH_JOB_QUEUE      := sider-job-queue
BATCH_JOB_DEF        := sider-job-definition
