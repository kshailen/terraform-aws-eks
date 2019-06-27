# terraform-aws-eks

Deploy a full AWS EKS cluster with Terraform

## What resources are created

1. VPC
2. Internet Gateway (IGW)
3. Public and Private Subnets
4. Security Groups, Route Tables and Route Table Associations
5. IAM roles, instance profiles and policies
6. An EKS Cluster
7. Autoscaling group and Launch Configuration
8. Worker Nodes in a private Subnet
9. The ConfigMap required to register Nodes with EKS
10. KUBECONFIG file to authenticate kubectl using the heptio authenticator aws binary

## Configuration

You can configure you config with the following input variables:

| Name                 | Description                       | Default       |
|----------------------|-----------------------------------|---------------|
| `cluster-name`       | The name of your EKS Cluster      | `EKS_TEST`  |
| `aws-region`         | The AWS Region to deploy EKS      | `us-east-1`   |
| `k8s-version`        | The desired K8s version to launch | `1.11`        |
| `node-instance-type` | Worker Node EC2 instance type     | `m4.large`    |
| `desired-capacity`   | Autoscaling Desired node capacity | `2`           |
| `max-size`           | Autoscaling Maximum node capacity | `5`           |
| `min-size`           | Autoscaling Minimum node capacity | `1`           |
| `vpc-subnet-cidr`    | Subnet CIDR                       | `10.0.0.0/16` |

> You can create a file called terraform.tfvars in the project root, to place your variables if you would like to over-ride the defaults.

## How to use this example

```bash
git clone https://github.com/kshailen/terraform-aws-eks.git
cd terraform-aws-eks
```
### IAM

The AWS credentials must be associated with a user having at least the following AWS managed IAM policies

* IAMFullAccess
* AutoScalingFullAccess
* AmazonEKSClusterPolicy
* AmazonEKSWorkerNodePolicy
* AmazonVPCFullAccess
* AmazonEKSServicePolicy
* AmazonEKS_CNI_Policy
* AmazonEC2FullAccess

In addition, you will need to create the following managed policies

*EKS*

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Terraform

You need to run the following commands to create the resources with Terraform:

```bash
terraform init
terraform plan
terraform apply
```

> TIP: you should save the plan state `terraform plan -out eks-state` or even better yet, setup [remote storage](https://www.terraform.io/docs/state/remote.html) for Terraform state. You can store state in an [S3 backend](https://www.terraform.io/docs/backends/types/s3.html), with locking via DynamoDB

### Setup kubectl

Setup your `KUBECONFIG`

```bash
terraform output kubeconfig > ~/.kube/eks-cluster
export KUBECONFIG=~/.kube/eks-cluster
```

### Authorize worker nodes

Get the config from terraform output, and save it to a yaml file:

```bash
terraform output config-map > config-map-aws-auth.yaml
```

Apply the config map to EKS:

```bash
kubectl apply -f config-map-aws-auth.yaml
```

You can verify the worker nodes are joining the cluster

```bash
kubectl get nodes --watch
```

### Cleaning up

You can destroy this cluster entirely by running:

```bash
terraform plan -destroy
terraform destroy  --force
```

### Deploying the Kubernetes dashboard
``` bash
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
```
### Create an administrative account and cluster role binding
```bash
kubectl apply -f eks-admin-service-account.yaml
kubectl apply -f eks-admin-cluster-role-binding.yaml
```

#### Installing Heapster and InfluxDB
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml
```

### Start proxy to open kubernetes Dashoard UI
```bash
kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &
```
### Get a token
```bash
aws-iam-authenticator -i EKS_TEST token | jq .status.token
```
### Log in to dashboard 
[http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login ](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login ) 
![login screen](https://github.com/kshailen/terraform-aws-eks/blob/master/loginscreen.png "Dashbboard Login screen")

### Set up Visualiser
Fork the repository and deploy the visualizer on kubernetes
```bash 
git clone  https://github.com/schoolofdevops/kube-ops-view
kubectl apply -f kube-ops-view/deploy/
```



### Sample Support Page from aws
[https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-kubernetes-dashboard/](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-kubernetes-dashboard/)

