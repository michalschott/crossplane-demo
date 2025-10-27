# Crossplane for Karpenter IAM Provisioning

This project demonstrates how to use Crossplane to provision and manage the required AWS IAM resources for a Karpenter installation, acting as a direct replacement for tools like Terraform.

Instead of managing multiple IAM resources manually, this demo creates a single, cluster-scoped Crossplane **Composite Resource Definition (XRD)** called `karpenter`.

When you create an instance of the `karpenter` custom resource, a Crossplane **Composition** (using `function-patch-and-transform`) will automatically provision the following four AWS resources:

1.  `Policy` (IAM Policy)
2.  `Role` (IAM Role)
3.  `RolePolicyAttachment`
4.  `PodIdentityAssociation` (for EKS)

**Note:** This demo is for provisioning new resources. While Crossplane does support importing and adopting existing resources, that functionality is not configured in this composition for simplicity.

---

## Prerequisites

Before running the demo, you will need the following tools installed on your local machine:

* `kubectl`
* `helm`
* `kind`

## Demo Instructions

### 1. Set AWS Credentials

You must export your AWS credentials as environment variables. The `run.sh` script will use these to create the necessary Kubernetes secret for Crossplane.

```bash
# Replace with your actual AWS credentials
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
```

### 2. Run the Demo

Execute the run.sh script, which will perform all setup steps automatically:

```bash
./run.sh
```

### 3. Verify the Results

The `run.sh` script will automatically print the status of the newly created AWS resources at the end. You can also run this command manually to check the status:

```bash
kubectl get -A Policy,Role.iam.aws.m.upbound.io,RolePolicyAttachment,PodIdentityAssociation
```

You can also check the status of your main karpenter resource:

```bash
kubectl get karpenter karpenter -o yaml
```

Look for the `status.conditions` to see if it's `Synced: True`.

## How It Works

The `run.sh` script automates the entire setup:

1. Creates a local cluster.
2. Installs Crossplane via Helm.
3. Installs `aws-iam` and `aws-eks` providers.
4. Installs composition `patch-and-transform` function, which is required by Composition.
5. Your exported AWS credentials are used to create the `aws-secret` in the `crossplane-system` namespace for providers to authenticate.
6. Applies `xrd.yaml` (custom API) and `composition.yaml` (the implementation).
7. Finally, `karpenter.yaml` is applied. This creates the `karpenter` custom resource, which signals Crossplane to execute the composition and create the four AWS resources.

## Cleanup

To delete all resources and the local cluster, simply run:

```bash
kubectl delete -f deploy/karpenter.yaml
kind delete cluster
```
