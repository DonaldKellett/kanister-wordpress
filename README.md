# kanister-wordpress

Back up and restore WordPress on Kubernetes with Kanister

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
1. WordPress installed on your cluster via the Bitnami [Helm chart](https://artifacthub.io/packages/helm/bitnami/wordpress)
1. The [Kanister operator](https://docs.kanister.io/install.html) installed on our Kubernetes cluster

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

## License

[MIT](./LICENSE)
