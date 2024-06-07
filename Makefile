tofu_dir:=tofu
tofu_cmd:=tofu -chdir=${tofu_dir}

cluster:
	$(MAKE) tofu plan
	$(MAKE) tofu apply
	$(MAKE) write-confs

down:
	$(MAKE) tofu destroy
	rm $(KUBECONFIG) $(TALOSCONFIG)

write-confs: $(KUBECONFIG) $(TALOSCONFIG)
	${tofu_cmd} output -raw kubeconfig > $(KUBECONFIG) 
	${tofu_cmd} output -raw talosconfig > $(TALOSCONFIG) 

.PHONY: tofu
tofu:
	${tofu_cmd} $(filter-out $@, $(MAKECMDGOALS))

%:
	@:
