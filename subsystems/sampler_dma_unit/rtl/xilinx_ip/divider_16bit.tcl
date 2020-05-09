#################################################################
## AXI Stream divider
#################################################################
## Configuration Parameters
set component_name "divider_16bit"
set xci_path       ${generated_ip_path}/${sample_dma_fifo_component_name}/${sample_dma_fifo_component_name}.xci

## Xilinx IP Settings
set ip_name        "div_gen"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     5.1

## Settings

set configuration_parameters [list \
                               CONFIG.algorithm_type              {Radix2} \
                               CONFIG.dividend_has_tlast          {false} \
                               CONFIG.divisor_width               {8} \
                               CONFIG.divisor_has_tlast           {false} \
                               CONFIG.clocks_per_division         {1} \
                               CONFIG.divide_by_zero_detect       {false} \
                               CONFIG.FlowControl                 {Blocking} \
                               CONFIG.OptimizeGoal                {Performance} \
                               CONFIG.OutTready                   {true} \
                               CONFIG.latency_configuration       {Automatic} \
                               CONFIG.dividend_and_quotient_width {16} \
                               CONFIG.remainder_type              {Remainder} \
                               CONFIG.fractional_width            {8} \
                               CONFIG.OutTLASTBehv                {Null} \
                               CONFIG.latency                     {23} \
                             ]

generate_new_ip ${generated_ip_path} \
                ${ip_name} \
                ${ip_version} \
                ${ip_vendor} \
                ${ip_library} \
                ${component_name} \
                ${configuration_parameters}