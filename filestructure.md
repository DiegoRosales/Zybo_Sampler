```bash
## Files copied from Digilent's website regarding IO connections and Zynq DDR configurations (for Xilinx's block view)
## The interfaces directory contains custom interfaces for the connection automation
board_files/
├── interfaces
│   └── i2s
│       ├── i2s_rtl.xml
│       └── i2s.xml
├── zybo
│   └── B.3
│       ├── board.xml
│       ├── part0_pins.xml
│       └── preset.xml
├── zybo-z7-10
│   └── A.0
│       ├── board.xml
│       ├── part0_pins.xml
│       └── preset.xml
└── zybo-z7-20
    └── A.0
        ├── board.xml
        ├── part0_pins.xml
        └── preset.xml

## The <PROJECT_NAME>.cfg file contains all the dependencies required to build/simulate that particular project
## The <PROJECT_NAME>_integ directory contains the integration script (connections between blocks) for the project
cfg
├── zybo_sampler.cfg
└── zybo_sampler_integ
    ├── zybo_sampler_integ_sim.tcl
    ├── zybo_sampler_integ_synth.tcl
    └── zybo_sampler_integ.tcl

## Environment scripts
scripts

## This directory contains all the block components used to building a project
subsystems/
├── codec_unit
│   ├── cfg
│   ├── fw
│   ├── gen
│   ├── README.md
│   ├── reg
│   ├── rtl
│   └── verif
├── sampler_dma_unit
│   ├── cfg
│   ├── fw
│   ├── README.md
│   └── rtl
└── sampler_mixer_unit
    ├── cfg
    ├── README.md
    └── rtl
```