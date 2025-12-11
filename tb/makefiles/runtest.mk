# Copyright © 2025 QuEL, Inc. All rights reserved.

ifeq "$(SIMULATOR)" "vivado"
SIM_BINARY_PATH := $(VIVADO_XSIM) $(VIVADO_XSIM_OPT)
RUN_FUNC        := run_vivado
endif

define run_vivado
	cd $(TEST_DIR)/$(TESTNAME) && \
	$(RM) -r xsim.dir sim.log && \
	ln -s $(BUILD_DIR)/xsim.dir . && \
	$(SIM_BINARY_PATH) --sv_seed $(SV_SEED) $(RUN_OPT) && mv xsim.log sim.log

endef

$(TEST_DIR)/$(TESTNAME):
	mkdir -p $(TEST_DIR)/$(TESTNAME)

run_test: build $(TEST_DIR)/$(TESTNAME)
	$(call $(RUN_FUNC))
