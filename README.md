# ecr-vacuum

A simple script to vacuum AWS Elastic Container Registry of old and unused
container images.

Makes a couple assumptions:

* Your source code is managed by git
* Images are tagged with the SHA (full) of the git commit they are associated with

## Configuration

Copy `repositories.example.yml` to `repositories.yml`. Configure:

```yaml
[name of repository in ECR]:
  git: [clone-able git URI, used to determine what images to keep]
  keep_branches: [array of branch names to search]
```

## Authentication

The most common use case for this script is being run in an EC2 instance that has
an IAM Role that grants that instance permissions.

You may use the "AmazonEC2ContainerRegistryFullAccess" managed policy, or you can
use the minimal policy below:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1459996380000",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchDeleteImage",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```
