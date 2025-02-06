$global_IDs = "wTacos","wBurgers"


# foreach($global_id in $global_IDs){
#     write-host "processing global id: $global_id"
#     terraform init -upgrade -backend-config="path=./workload/build/$($global_id)/$($global_id).tfstate" -reconfigure
#     terraform plan -var="global_id=build/$($global_id)"
#     terraform apply -auto-approve -var="global_id=build/$($global_id)"
# }
foreach($global_id in $global_IDs){
    write-host "processing global id: $global_id"
    terraform -chdir="./vending_module" init -upgrade -backend-config="path=../../workload/build/$($global_id)/$($global_id).tfstate" -reconfigure 
    terraform -chdir="./vending_module" plan -var="global_id=./workload/build/$($global_id)"
    terraform -chdir="./vending_module" apply -auto-approve -var="global_id=../../workload/build/$($global_id)"
    start-sleep 10s
    terraform -chdir="./vending_module" destroy -auto-approve -var="global_id=../../workload/build/$($global_id)"
}