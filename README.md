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
