#################################################################
## AXI Stream divider
#################################################################
## Xilinx IP Settings
set ip_name        "div_gen"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     5.1

## Settings
lappend {*}configuration_parameters CONFIG.algorithm_type              {Radix2}
lappend {*}configuration_parameters CONFIG.dividend_has_tlast          {false}
lappend {*}configuration_parameters CONFIG.divisor_width               {8}
lappend {*}configuration_parameters CONFIG.divisor_has_tlast           {false}
lappend {*}configuration_parameters CONFIG.clocks_per_division         {1}
lappend {*}configuration_parameters CONFIG.divide_by_zero_detect       {false}
lappend {*}configuration_parameters CONFIG.FlowControl                 {Blocking}
lappend {*}configuration_parameters CONFIG.OptimizeGoal                {Performance}
lappend {*}configuration_parameters CONFIG.OutTready                   {true}
lappend {*}configuration_parameters CONFIG.latency_configuration       {Automatic}
lappend {*}configuration_parameters CONFIG.dividend_and_quotient_width {16}
lappend {*}configuration_parameters CONFIG.remainder_type              {Remainder}
lappend {*}configuration_parameters CONFIG.fractional_width            {8}
lappend {*}configuration_parameters CONFIG.OutTLASTBehv                {Null}
lappend {*}configuration_parameters CONFIG.latency                     {23}