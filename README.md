# sider_aws
Run sider pipeline on AWS

## Configure Security Credentials

1. Go to: http://aws.amazon.com/
2. Sign Up
3. Go to your AWS account overview
4. Account menu in the upper-right (has your name on it)
5. sub-menu: Security Credentials
6. Then, create **Access Key**

Now, configure your `awk-cli`:

	$ aws configure

and set **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY** properly.
