tf_dir:=tofu
tf_cmd:=tofu -chdir=tofu

up:
	$(MAKE) tofu plan
	$(MAKE) tofu apply
	$(MAKE) write-confs

write-confs:
	${tf_cmd} output -raw kubeconfig > $(KUBECONFIG) 
	${tf_cmd} output -raw talosconfig > $(TALOSCONFIG) 

.PHONY: tofu
tofu:
	${tf_cmd} $(filter-out $@, $(MAKECMDGOALS))

%:
	@:
