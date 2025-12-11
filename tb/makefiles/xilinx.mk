# Copyright © 2025 QuEL, Inc. All rights reserved.

VIVADO_XVHDL := $(VIVADO_BIN_PATH)xvhdl
VIVADO_XVLOG := $(VIVADO_BIN_PATH)xvlog
VIVADO_XELAB := $(VIVADO_BIN_PATH)xelab

VIVADO_XVLOG_SV_OPT      := --incr $(LIBS) --sv --work work
VIVADO_XELAB_OPT         := --incr $(LIBS) work.$(TOP_MODULE) -s work.$(TOP_MODULE) --timescale	1ns/1ps
VIVADO_XSIM_OPT          := --maxdeltaid -1

# DEBUG
ifeq "$(DEBUG)" "0"
VIVADO_XVLOG_OPT    +=
VIVADO_XELAB_OPT    += --standalone
VIVADO_XSIM_OPT     += --runall
VIVADO_XSIM         := $(BUILD_DIR)/axsim.sh
VIVADO_BUILD_TARGET := $(BUILD_DIR)/xsim.dir/work/axsim
else
ifeq "$(DEBUG)" "1"
VIVADO_XVLOG_OPT    +=
VIVADO_XELAB_OPT    += --debug all
VIVADO_XSIM_OPT     += work.$(TOP_MODULE) --gui
VIVADO_XSIM         := $(VIVADO_BIN_PATH)xsim
VIVADO_BUILD_TARGET := $(BUILD_DIR)/xsim.dir/work/xsimk
else
VIVADO_XVHDL_OPT    +=
VIVADO_XVLOG_OPT    +=
VIVADO_XELAB_OPT    += --stats
VIVADO_XSIM_OPT     += --stats --runall work.$(TOP_MODULE)
VIVADO_XSIM         := $(VIVADO_BIN_PATH)xsim
VIVADO_BUILD_TARGET := $(BUILD_DIR)/xsim.dir/work/xsimk
endif
endif

DEPEND_OBJS :=

ifneq "$(DEPEND_SV_SRCS)" ""
DEPEND_OBJS += $(BUILD_DIR)/xsim.dir/work/.done_xvlog_sv
endif

VIVADO_XELAB_OPT_EXT :=

build_vivado: $(VIVADO_BUILD_TARGET)

$(BUILD_DIR)/xsim.dir/work/.done_xvlog_sv: $(DEPEND_SV_SRCS)
	cd $(BUILD_DIR) && \
	$(VIVADO_XVLOG) $(VIVADO_XVLOG_SV_OPT) $(TB_OPTS) $(DEPEND_SV_SRCS) && \
	touch $@

$(BUILD_DIR)/xsim.dir/work/xsimk: $(DEPEND_OBJS)
	cd $(BUILD_DIR) && \
	$(VIVADO_XELAB) $(VIVADO_XELAB_OPT) $(VIVADO_XELAB_OPT_EXT)

$(BUILD_DIR)/xsim.dir/work/axsim: $(DEPEND_OBJS)
	cd $(BUILD_DIR) && \
	$(VIVADO_XELAB) $(VIVADO_XELAB_OPT) $(VIVADO_XELAB_OPT_EXT)
