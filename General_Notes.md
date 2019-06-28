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



### S3 Backend:
[https://www.terraform.io/docs/backends/types/s3.html](https://www.terraform.io/docs/backends/types/s3.html)


### Backend S3 and Workspace Example
[https://dzone.com/articles/manage-multiple-environments-with-terraform-worksp](https://dzone.com/articles/manage-multiple-environments-with-terraform-worksp)
