# kanister-wordpress

Back up and restore WordPress on Kubernetes with Kanister

## Overview

TODO

## Developing

Fork and clone this repository, then navigate to the project root and follow the instructions below.

### Install pre-commit hook \(optional\)

The pre-commit hook runs formatting and sanity checks such as `tofu fmt` to reduce the chance of accidentally submitting badly formatted code that would fail CI.

```bash
ln -s ../../hooks/pre-commit ./.git/hooks/pre-commit
```

### Prerequisites

1. An [AWS](https://aws.amazon.com/) account
1. Valid AWS credentials for an IAM administrator account - see [Configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) for details
1. [OpenTofu](https://opentofu.org/) v1.7.2 or later
1. A Kubernetes cluster - spin one up with [kind](https://kind.sigs.k8s.io/) if in doubt
1. Cluster-admin access to the Kubernetes cluster with `kubectl`
1. [Helm](https://helm.sh/)
1. WordPress installed in the `wordpress` namespace with release name `wordpress` within your cluster via the Bitnami [Helm chart](https://artifacthub.io/packages/helm/bitnami/wordpress)
1. The [Kanister operator](https://docs.kanister.io/install.html) installed on our Kubernetes cluster
1. [Go](https://go.dev/) 1.22.4 or above
1. The [Kanister tools](https://docs.kanister.io/tooling.html) installed

### Create the S3 bucket for storing our Kanister backups

Create the S3 bucket for storing our Kanister backups using OpenTofu:

```bash
tofu init
tofu plan
tofu apply
```

Supported variables:

| Name | Type | Required | Default value | Description |
| --- | --- | --- | --- | --- |
| `profile` | `string` | - | `"default"` | The profile to assume from the [AWS credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) |
| `region` | `string` | - | `"ap-east-1"` | The AWS region to assume |

### Back up our WordPress database to S3

This demo is adapted from the [MariaDB Kanister example](https://github.com/kanisterio/kanister/tree/master/examples/maria).

First create the blueprint:

```bash
kubectl create -f manifests/blueprint.yaml
```

Now run the `quiesce-and-backup` action with `kanctl` which performs the following operations:

1. Quiesce the WordPress database by scaling it to zero
1. Upload a logical dump of the database to S3

```bash
kanctl -n kanister create actionset \
    --action quiesce-and-backup \
    --blueprint wordpress-bp \
    --statefulset wordpress/wordpress-mariadb
```

Sample output:

```text
actionset quiesce-and-backup-rbcj6 created
```

The original replica count is saved as an output artifact which can be used by the `unquiesce` action once the previous action is complete:

```bash
PARENT_ACTION="quiesce-and-backup-rbcj6" # Replace me!
kanctl -n kanister create actionset \
    --action unquiesce \
    --from "${PARENT_ACTION}"
```

### Restore our WordPress database from S3

TODO

## License

[MIT](./LICENSE)
