tofu_dir:=tofu
tofu_cmd:=tofu -chdir=${tofu_dir}

CLUSTER?=pve-talos
VAR_FILE=vars/$(CLUSTER).tfvars

cluster:
	$(MAKE) plan
	$(MAKE) apply
	$(MAKE) write-confs

down:
	$(MAKE) tofu destroy
	rm $(KUBECONFIG) $(TALOSCONFIG)
	rm -rf ${tofu_dir}/.terraform ${tofu_dir}/*.tfstate 

validate-varfile:
	@if [ ! -f "${tofu_dir}/$(VAR_FILE)" ]; then echo "File '$(VAR_FILE)' does not exist. Use CLUSTER=<your-cluster> make $(MAKECMDGOALS)"; exit 1; fi

init:
	${tofu_cmd} init -upgrade

plan: init plan-fast

plan-fast: validate-varfile
	${tofu_cmd} workspace select -or-create=true "$(CLUSTER)"
	${tofu_cmd} plan -var-file="$(VAR_FILE)" -out "$(CLUSTER).tfplan"

apply:
	${tofu_cmd} apply "$(CLUSTER).tfplan"

write-confs: $(KUBECONFIG) $(TALOSCONFIG)
	${tofu_cmd} output -raw kubeconfig > $(KUBECONFIG) 
	${tofu_cmd} output -raw talosconfig > $(TALOSCONFIG) 
	chmod 600 $(KUBECONFIG)
	chmod 600 $(TALOSCONFIG)

.PHONY: tofu
tofu:
	${tofu_cmd} $(filter-out $@, $(MAKECMDGOALS))

%:
	@:
