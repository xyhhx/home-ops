.PHONY: tofu
tofu:
	tofu -chdir=tofu $(filter-out $@, $(MAKECMDGOALS))

%:
	@:
