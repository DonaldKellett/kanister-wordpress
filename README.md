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

Create a location profile and corresponding secret as well to point to our S3 bucket where we'll store our database dumps to.

```bash
kubectl create -f manifests/secret.yaml
kubectl create -f manifests/profile.yaml
```

Now run the `quiesce` action with `kanctl` which scales down our WordPress deployment to zero. This ensures that we are not writing to the database when the backup occurs at a later stage.

```bash
kanctl -n kanister create actionset \
    --action quiesce \
    --blueprint wordpress-bp \
    --deployment wordpress/wordpress
```

Sample output:

```text
actionset quiesce-spx9q created
```

Now we can run the `backup` action to backup up our WordPress database:

```bash
kanctl -n kanister create actionset \
    --action backup \
    --blueprint wordpress-bp \
    --profile wordpress-s3-profile \
    --statefulset wordpress/wordpress-mariadb
```

Sample output:

```text
actionset backup-pzxzz created
```

Once the backup is complete, run the `unquiesce` action which scales our WordPress deployment back to the original number of replicas so it can start accepting user traffic again.

```bash
QUIESCE_ACTIONSET="quiesce-spx9q" # Replace me!
kanctl -n kanister create actionset \
    --action unquiesce \
    --from "${QUIESCE_ACTIONSET}"
```

### Restore our WordPress database from S3

TODO

## License

[MIT](./LICENSE)
