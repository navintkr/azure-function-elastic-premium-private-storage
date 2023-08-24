# Azure Functions Elastic Premium with Private Storage using Terraform

Azure Funcions + Private Endpoint + Storage + Terraform.

The project is divided in two main files:

- `main.tf`: Terraform file with resources that creates the function app infra.
- `variables.tf`: Terraform file with variables.


**NOTE: Latest Terraform and azcli must be isntalled**

### Local Run

To run locally you must login to azure :

```
az login
az account set --subscription <name or id>
terraform init
terraform plan
terraform apply
```

## Infrastructure 

### **Main**

This Terrafform project creates the Azure Function App (Elastic Premium) with private storage and the function envrionment properties. Application insights is not included.



## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

