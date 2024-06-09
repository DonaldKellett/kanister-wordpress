# kanister-wordpress

Back up and restore WordPress on Kubernetes with Kanister

## Overview

[Kubernetes CSI](https://kubernetes-csi.github.io/docs/) enables us to take volume snapshots on supported storage backends as a first step towards protecting our data on Kubernetes but snapshots operate at the infrastructure level so they do not understand how applications operate and manage their data. This implies that snapshots, by nature, are crash-consistent but not application-consistent. For busy stateful workloads such as databases processing many transactions per second, crash-consistency is insufficient for data protection since in-progress transactions are not recorded so restoring from a snapshot may still lead to data loss and leave the application in a broken state.

[Kanister](https://kanister.io/) provides a robust and flexible solution for defining your own actions for performing application-aware backups on Kubernetes. It does this by defining blueprints, which serve as templates for application-specific backup and restore actions. The backup administrator or application owner may then instantiate actions defined in these blueprints by creating ActionSets which perform the actual application-specific backup and recovery tasks.

This demo demonstrates how to back up and restore WordPress on Kubernetes with Kanister in a reliable manner, by creating a logical database backup \(database dump\) and exporting it to S3 which can be imported during the restore phase to return WordPress to a known good state. The backup procedure consists of the following 3 steps:

1. Scale the WordPress deployment to zero to stop accepting user traffic and complete pending database transactions
1. Take a logical dump of the database and upload it to S3
1. Scale the WordPress deployment back to the original count to start accepting user traffic again

The restore procedure is also similar:

1. Scale the WordPress deployment to zero to stop accepting user traffic and ensure no additional database transactions are made during the restore operation
1. Download the logical database dump from S3 and import it to our running database
1. Scale the WordPress deployment back to the original count to start accepting user traffic again

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

As with backing our our WordPress database to S3, we should quiesce our WordPress application as well prior to restoring from our database dump:

```bash
kanctl -n kanister create actionset \
    --action quiesce \
    --blueprint wordpress-bp \
    --deployment wordpress/wordpress
```

Sample output:

```text
actionset quiesce-2jtgj created
```

Now run the `restore` action to restore our WordPress database from the SQL dump uploaded to S3:

```bash
BACKUP_ACTIONSET="backup-pzxzz" # Replace me!
kanctl -n kanister create actionset \
    --action restore \
    --from "${BACKUP_ACTIONSET}"
```

Once the restore operation is complete, unquiesce our WordPress application so it can start accepting user traffic again:

```bash
QUIESCE_ACTIONSET="quiesce-2jtgj" # Replace me!
kanctl -n kanister create actionset \
    --action unquiesce \
    --from "${QUIESCE_ACTIONSET}"
```

## License

[MIT](./LICENSE)
