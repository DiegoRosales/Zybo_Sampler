# =============================================================================
# Zybo Sampler build flow
# -----------------------------------------------------------------------------
# Thin wrapper around scripts/run.tcl, following the "Build instructions"
# section of README.md. Each build stage is exposed as a make target.
#
# Requires (per README): Xilinx Vivado 2020.1 and Xilinx Vitis 2020.1 on PATH
# (source the settings64 scripts first).
#
# Quick start:
#   make all            # full build from scratch (PACK+INTEG+GEN_XILINX_IP+IMPL+EXPORT_WS)
#   make pack integ     # run individual stages
#   make fw             # generate the Vitis firmware workspace
#   make sim            # run the UVM simulation
#   make stages STAGES="INTEG+IMPL"
# =============================================================================

# ---- Tools (override on the command line if not on PATH) --------------------
VIVADO ?= vivado
XSCT   ?= xsct

# ---- Project configuration --------------------------------------------------
CFG     ?= cfg/zybo_sampler.cfg.json
RUN_TCL := scripts/run.tcl

# ---- Simulation defaults (override on the command line) ---------------------
SIM_TB ?= codec_unit_top_tb
SIM_TC ?= codec_unit_top_testcase_1

# ---- Optional per-stage arguments -------------------------------------------
# Pass extra stage args, e.g.:  make impl STAGE_ARGS='"IMPL_ARG1=1"'
STAGE_ARGS ?=

# ---- Internal helpers -------------------------------------------------------
VIVADO_BATCH := $(VIVADO) -mode batch -source $(RUN_TCL) -tclargs -cfg $(CFG)
VIVADO_TCL   := $(VIVADO) -mode tcl   -source $(RUN_TCL) -tclargs -cfg $(CFG)

# Only append the --stage_args ... -- block when STAGE_ARGS is non-empty
ifeq ($(strip $(STAGE_ARGS)),)
STAGE_ARGS_OPT :=
else
STAGE_ARGS_OPT := --stage_args $(STAGE_ARGS) --
endif

.DEFAULT_GOAL := help

# =============================================================================
# Primary build stages
# =============================================================================

## all: Full build from scratch (default stage set)
all:
	$(VIVADO_BATCH) $(STAGE_ARGS_OPT)

## pack: (1) Package the individual cores via the Vivado IP Packager
pack:
	$(VIVADO_BATCH) -stages "PACK" $(STAGE_ARGS_OPT)

## integ: (2) Import packaged cores and generate the top-level RTL
integ:
	$(VIVADO_BATCH) -stages "INTEG" $(STAGE_ARGS_OPT)

## xilinx-ip: (3) Individually synthesize the Xilinx IPs
xilinx-ip:
	$(VIVADO_BATCH) -stages "GEN_XILINX_IP" $(STAGE_ARGS_OPT)

## impl: (4) Synthesis and Place & Route
impl:
	$(VIVADO_BATCH) -stages "IMPL" $(STAGE_ARGS_OPT)

## fw: (5) Generate the Vitis firmware workspace (uses xsct)
fw:
	$(XSCT) $(RUN_TCL) -tclargs -cfg $(CFG) -stages "BUILD_WS"

# =============================================================================
# Optional stages
# =============================================================================

## lint: Compile-only syntax check (needs at least the xilinx-ip stage first)
lint:
	$(VIVADO_TCL) -stages "LINT" $(STAGE_ARGS_OPT)

## sim: Run the UVM testcase (override SIM_TB / SIM_TC as needed)
sim:
	$(VIVADO_TCL) -stages "SIM" --stage_args "SIM_TB=$(SIM_TB)" "SIM_TC=$(SIM_TC)" --

# =============================================================================
# Escape hatch: run an arbitrary "+"-separated stage list
#   make stages STAGES="INTEG+IMPL"
# =============================================================================
STAGES ?=
stages:
	@if [ -z '$(STAGES)' ]; then \
		echo "ERROR: set STAGES, e.g. make stages STAGES=\"INTEG+IMPL\""; exit 1; \
	fi
	$(VIVADO_BATCH) -stages "$(STAGES)" $(STAGE_ARGS_OPT)

# =============================================================================
# Housekeeping
# =============================================================================

## help: Show this help
help:
	@echo "Zybo Sampler build targets (CFG=$(CFG)):"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'
	@echo ""
	@echo "Common overrides: VIVADO=, XSCT=, CFG=, STAGES=, STAGE_ARGS=, SIM_TB=, SIM_TC="

.PHONY: all pack integ xilinx-ip impl fw lint sim stages help
