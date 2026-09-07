# AGENTS.md

Guidance for AI coding agents working in the **Zybo Sampler** repo.

## What this project is

A hardware audio sampler for the Digilent **Zybo** (Zynq-7000, `xc7z010clg400-1`). It is a
split hardware/firmware design:

- **PL (FPGA)** — SystemVerilog subsystems: an SSM2603 CODEC controller (I2C + I2S), a custom
  64-slot sample DMA engine, and a stream mixer. Packaged as Vivado IP and stitched together
  by a Tcl integration script.
- **PS (ARM Cortex-A9)** — FreeRTOS firmware with a UART CLI, FreeRTOS+FAT SD-card access, a
  JSON/SF2 patch loader, and a MIDI bridge.

`README.md` has the project background, milestones, and the instrument-JSON format.
`filestructure.md` and the per-subsystem `README.md` files describe the block architecture.

## Repo layout

| Path | Contents |
| --- | --- |
| `cfg/zybo_sampler.cfg.json` | Top-level project config: core list, part numbers, constraints, output dirs |
| `cfg/zybo_sampler_integ/` | Integration script — where blocks are instantiated and wired together |
| `scripts/run.tcl` | Entry point for every build stage |
| `scripts/build_stages/` | One Tcl file per stage (`stage_pack.tcl`, `stage_integ.tcl`, …) |
| `scripts/{pack,integ,reg_gen,utils}/` | Tcl helper libraries used by the stages |
| `subsystems/<unit>/` | One packaged core each: `rtl/`, `fw/`, `reg/`, `verif/`, `cfg/` |
| `subsystems/verification_components/` | UVM BFMs (AXI4-Lite, clock/reset, I2S) |
| `source/common/` | Shared RTL, shared firmware (`fw/src`), global register map |
| `source/constraints/` | XDC timing / pin / physical constraints |
| `source/verif/` | Top-level and unit testbenches |
| `board_files/` | Digilent board definitions + custom I2S interface definition |
| `target/` | **Generated** build output (gitignored) |

## Build and test

Everything runs through `scripts/run.tcl`; the `Makefile` is a thin wrapper. Prefer the make
targets:

```bash
make            # help
make all        # PACK+INTEG+GEN_XILINX_IP+IMPL+EXPORT_WS
make pack       # (1) package each core as Vivado IP
make integ      # (2) run the integration script, generate top-level RTL
make xilinx-ip  # (3) synthesize Xilinx IPs
make impl       # (4) synthesis + place & route
make fw         # (5) generate the Vitis workspace (xsct)
make lint       # compile-only syntax check (needs stage 3 first)
make sim SIM_TB=codec_unit_top_tb SIM_TC=codec_unit_top_testcase_1
make stages STAGES="INTEG+IMPL"
```

**You almost certainly cannot run these.** They require a local install of Xilinx Vivado 2020.1
and Vitis 2020.1 with `settings64.sh` sourced; the tools are not vendored and the flake does not
provide them. Do not claim a change builds unless you actually ran a stage successfully. When
you cannot verify, say so explicitly and describe what the user should run.

On NixOS, `nix develop` drops you into an FHS sandbox (`xilinx-env`) that lets the Xilinx
binaries run — but Vivado itself still has to be installed separately.

Firmware is **not** compiled by this repo. `make fw` only creates a Vitis workspace of symlinks
into `source/` and `subsystems/`; the actual compile and board programming happen in the Vitis
GUI. There is no way to type-check firmware edits from the CLI here.

## Things that will bite you

**Source files are not globbed.** Every RTL file must be listed explicitly in the owning core's
`cfg/core.cfg.json` under `synthesis_rtl_file_list` (and `simulation.simulation_compile` for
testbench files). Adding a `.sv` file without registering it there means it silently never gets
compiled.

**The `.cfg.json` files are JSONC, not JSON.** They contain `//` comments and `${var}`
interpolation (`${git_root}`, `${project_root}`, `${core_root}`, `${project_name}`), and are
parsed by `scripts/utils/json_parser.tcl`. Standard JSON tools (`jq`, `json.load`) will fail on
them — edit them as text and keep the existing comment style.

**Adding a new core** means: create `<core>/cfg/core.cfg.json`, write a
`<core>/cfg/pack/pack_core.tcl` packaging script, and add the core root to `project_cores` in
`cfg/zybo_sampler.cfg.json`. Firmware belonging to a core is exposed to the Vitis workspace via
the `firmware.softlinks` / `firmware.incdirs` keys in its `core.cfg.json`.

**Register generation is half-wired.** Registers are described declaratively in
`subsystems/<unit>/reg/regs.tcl` and assembled in `reg_assemble.tcl`; `stage_reg_gen.tcl`
generates both RTL and a UVM register model into `<core>/gen/` (gitignored, regenerated). But
the `REG_GEN` stage is currently **commented out** in `scripts/run.tcl` — check there before
assuming a register change propagates automatically.

**Don't touch vendored code.** These are third-party imports and should be left alone unless
explicitly asked: `source/common/fw/repo/**` (Xilinx FreeRTOS BSP, sdps driver),
`source/common/fw/src/{FreeRTOS-Plus-FAT,FreeRTOS-Plus-CLI,jsmn}`,
`subsystems/codec_unit/rtl/controller_unit/i2c_core/verilog-i2c/`, and `board_files/`.

**Never commit build output.** `target/`, `.Xil/`, `vivado*.log`, `vivado*.jou`, `*.str`, and
`gen/` are all gitignored. Stray `vivado_*.backup.{log,jou}` files may already be sitting
untracked in the repo root — leave them, don't add them.

## Conventions

- **SystemVerilog**: 2-space indent, `snake_case` modules and signals, active-low resets named
  `reset_n`/`aresetn`, banner comment block at the top of each module (title, author,
  description, revision). Some modules use `` `default_nettype none `` — follow the file you're
  in. AXI port lists were generated from Xilinx templates and use tabs; don't reformat them.
- **C firmware**: FreeRTOS-style prefixed names (`ulPlayInstrumentKey`, `usGetMIDINoteNumber`,
  `pv...`), typedefs in `SCREAMING_CASE_t`. CLI commands live in
  `source/common/fw/src/sampler/FreeRTOS_CLI_Apps/`, one file per command; long-running work
  goes into a matching task in `FreeRTOS_Tasks/`.
- **Tcl**: helper procs live in namespaces (`proj_utils::`, `pack_utils::`, `integ_utils::`);
  named-argument style (`-project_name $x`).
- **Editor**: `.vscode/settings.json` sets `tabSize: 2`, spaces, no tabs.
- **Commits**: short imperative subject lines, no body (`Add Makefile`, `DAC bug fixes`).

## Scope

Do what was asked. This is a hobby project with a specific build flow — don't introduce new
build systems, reformat vendored files, restructure the config schema, or "fix" the commented-out
stages unless that is the task.
