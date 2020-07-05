## Lint stage

## Create the base project
source $build_stages_path/stage_impl_base.tcl

## Only do elaboration
synth_design -rtl -name lint
