### Terraform Workspaces: 
[https://www.terraform.io/docs/state/workspaces.html](https://www.terraform.io/docs/state/workspaces.html)

### Commands:
```bash 
shailendras-mbp:terraform-aws-eks shaikuma$ terraform workspace
Usage: terraform workspace

  New, list, select and delete Terraform workspaces.
shailendras-mbp:terraform-aws-eks shaikuma$ terraform workspace list
* default
shailendras-mbp:terraform-aws-eks shaikuma$ 
```

### Terraform Workspace Interpolation:
```hcl
${terraform.workspace}
```

### * refresents current namespace
```hcl
shailendras-mbp:terraform-aws-eks shaikuma$ terraform workspace list
  default
* dev

shailendras-mbp:terraform-aws-eks shaikuma$ 
```

### S3 Backend:
[https://www.terraform.io/docs/backends/types/s3.html](https://www.terraform.io/docs/backends/types/s3.html)

### Kubernetes cheatsheet
[kubectl cheatsheet ](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
[kubectl explain](https://blog.heptio.com/kubectl-explain-heptioprotip-ee883992a243)
[Kubernetes Learning Resources](https://docs.google.com/spreadsheets/d/10NltoF_6y3mBwUzQ4bcQLQfCE1BWSgUDcJXy-Qp2JEU/edit#gid=0)
[rbac Examples](https://unofficial-kubernetes.readthedocs.io/en/latest/admin/authorization/rbac/)



### Backend S3 and Workspace Example
[https://dzone.com/articles/manage-multiple-environments-with-terraform-worksp](https://dzone.com/articles/manage-multiple-environments-with-terraform-worksp)
[https://scraly.github.io/posts/manage-multiple-environments-with-terraform-workspaces/](https://scraly.github.io/posts/manage-multiple-environments-with-terraform-workspaces/)
