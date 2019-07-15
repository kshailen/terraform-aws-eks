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
git clone  https://github.com/kshailen/kube-ops-view.git
kubectl apply -f kube-ops-view/deploy/
```
### Open Visualiser UI
Check if kubeproxy is running or not using following 

```bash
ps -ef | grep -i kubectl | grep proxy
```
It will show output like below
```
Shailendras-MacBook-Pro:terraform-aws-eks shaikuma$ ps -ef | grep -i kubectl | grep proxy
  501 39202 21611   0  3:41PM ttys002    0:00.28 kubectl proxy --address 0.0.0.0 --accept-hosts 
Shailendras-MacBook-Pro:terraform-aws-eks shaikuma$ 
```
It's proxy is not running then run it using following
```bash
kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &
```
Now direct your browser to http://localhost:8001/api/v1/namespaces/default/services/kube-ops-view/proxy/
It gives you view as below.

![lkube-ops-view-image](https://github.com/kshailen/terraform-aws-eks/blob/master/kube-ops-view-image.png "kops view")

You could read further about it [at this link.](https://kubernetes-operational-view.readthedocs.io/en/latest/)

[Kubernetes Operational View is also available as a Helm Chart](https://kubeapps.com/charts/stable/kube-ops-view)


## Adding docker hub secret

### Log in to Docker

On your laptop, you must authenticate with a registry in order to pull a private image:

```shell
docker login
```
When prompted, enter your Docker username and password.

The login process creates or updates a `config.json` file that holds an authorization token.

View the `config.json` file:

```shell
cat ~/.docker/config.json
```

The output contains a section similar to this:

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "c3R...zE2"
        }
    }
}
```

{{< note >}}
If you use a Docker credentials store, you won't see that `auth` entry but a `credsStore` entry with the name of the store as value.
{{< /note >}}

### Create a Secret based on existing Docker credentials {#registry-secret-existing-credentials}

A Kubernetes cluster uses the Secret of `docker-registry` type to authenticate with
a container registry to pull a private image.

If you already ran `docker login`, you can copy that credential into Kubernetes:

```shell
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```

If you need more control (for example, to set a namespace or a label on the new
secret) then you can customise the Secret before storing it.
Be sure to:

- set the name of the data item to `.dockerconfigjson`
- base64 encode the docker file and paste that string, unbroken
  as the value for field `data[".dockerconfigjson"]`
- set `type` to `kubernetes.io/dockerconfigjson`

Example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myregistrykey
  namespace: awesomeapps
data:
  .dockerconfigjson: UmVhbGx5IHJlYWxseSByZWVlZWVlZWVlZWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGx5eXl5eXl5eXl5eXl5eXl5eXl5eSBsbGxsbGxsbGxsbGxsbG9vb29vb29vb29vb29vb29vb29vb29vb29vb25ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubmdnZ2dnZ2dnZ2dnZ2dnZ2dnZ2cgYXV0aCBrZXlzCg==
type: kubernetes.io/dockerconfigjson
```

If you get the error message `error: no objects passed to create`, it may mean the base64 encoded string is invalid.
If you get an error message like `Secret "myregistrykey" is invalid: data[.dockerconfigjson]: invalid value ...`, it means
the base64 encoded string in the data was successfully decoded, but could not be parsed as a `.docker/config.json` file.

## Create a Secret by providing credentials on the command line

Create this Secret, naming it `regcred`:

```shell
kubectl create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

where:

* `<your-registry-server>` is your Private Docker Registry FQDN. (https://index.docker.io/v1/ for DockerHub)
* `<your-name>` is your Docker username.
* `<your-pword>` is your Docker password.
* `<your-email>` is your Docker email.

You have successfully set your Docker credentials in the cluster as a Secret called `regcred`.


Typing secrets on the command line may store them in your shell history unprotected, and
those secrets might also be visible to other users on your PC during the time that
`kubectl` is running.



## Inspecting the Secret `regcred`

To understand the contents of the `regcred` Secret you just created, start by viewing the Secret in YAML format:

```shell
kubectl get secret regcred --output=yaml
```

The output is similar to this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  ...
  name: regcred
  ...
data:
  .dockerconfigjson: eyJodHRwczovL2luZGV4L ... J0QUl6RTIifX0=
type: kubernetes.io/dockerconfigjson
```

The value of the `.dockerconfigjson` field is a base64 representation of your Docker credentials.

To understand what is in the `.dockerconfigjson` field, convert the secret data to a
readable format:

```shell
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

The output is similar to this:

```json
{"auths":{"your.private.registry.example.com":{"username":"janedoe","password":"xxxxxxxxxxx","email":"jdoe@example.com","auth":"c3R...zE2"}}}
```

To understand what is in the `auth` field, convert the base64-encoded data to a readable format:

```shell
echo "c3R...zE2" | base64 --decode
```

The output, username and password concatenated with a `:`, is similar to this:

```none
janedoe:xxxxxxxxxxx
```

Notice that the Secret data contains the authorization token similar to your local `~/.docker/config.json` file.

You have successfully set your Docker credentials as a Secret called `regcred` in the cluster.



### Logging into ecr
```bash
$(aws ecr get-login --no-include-email --region us-east-1)
```

### AWS Support Page:
[https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-kubernetes-dashboard/](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-kubernetes-dashboard/)

[EKS User Guide ](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)

[EKS WorkShop](https://eksworkshop.com/)

[How to setup ALB ingress Controller](https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/)