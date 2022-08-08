# oci-postgresql
OCI Resource Manager Stack to deploy Postgresql on OCI.  This repo is based on https://github.com/oracle-devrel/terraform-oci-arch-postgresql

replace 

module "arch-postgresql" {
  source                   = "./module-postgresql"
  
to   

module "arch-postgresql" {
  source                   = "https://github.com/oracle-devrel/terraform-oci-arch-postgresql"
  

Go to OCI Resource Manager and pull this repository. 

