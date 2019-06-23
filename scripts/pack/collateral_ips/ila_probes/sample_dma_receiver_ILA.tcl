
#################################################################
## Sample info fetcher ILA
#################################################################
## Configuration Parameters
set component_name "sample_dma_receiver_ILA"

# Xilinx IP Settings
set ip_name        "ila"
set ip_version     6.2
set ip_vendor      "xilinx.com"
set ip_library     "ip"

set number_of_probes            24
set number_of_comparators       2
set number_of_input_pipe_stages 2


set configuration_parameters [list  \
                                    CONFIG.C_NUM_OF_PROBES ${number_of_probes} \
                                    CONFIG.C_PROBE0_WIDTH   {1} \
                                    CONFIG.C_PROBE1_WIDTH   {1} \
                                    CONFIG.C_PROBE2_WIDTH   {1} \
                                    CONFIG.C_PROBE3_WIDTH   {6} \
                                    CONFIG.C_PROBE4_WIDTH   {16} \
                                    CONFIG.C_PROBE5_WIDTH   {16} \
                                    CONFIG.C_PROBE6_WIDTH   {6} \
                                    CONFIG.C_PROBE7_WIDTH   {1} \
                                    CONFIG.C_PROBE8_WIDTH   {1} \
                                    CONFIG.C_PROBE9_WIDTH   {1} \
                                    CONFIG.C_PROBE10_WIDTH  {16} \
                                    CONFIG.C_PROBE11_WIDTH  {16} \
                                    CONFIG.C_PROBE12_WIDTH  {1} \
                                    CONFIG.C_PROBE13_WIDTH  {1} \
                                    CONFIG.C_PROBE14_WIDTH  {1} \
                                    CONFIG.C_PROBE15_WIDTH  {3} \
                                    CONFIG.C_PROBE16_WIDTH  {6} \
                                    CONFIG.C_PROBE17_WIDTH  {1} \
                                    CONFIG.C_PROBE18_WIDTH  {1} \
                                    CONFIG.C_PROBE19_WIDTH  {7} \
                                    CONFIG.C_PROBE20_WIDTH  {16} \
                                    CONFIG.C_PROBE21_WIDTH  {16} \
                                    CONFIG.C_PROBE22_WIDTH  {1} \
                                    CONFIG.C_PROBE23_WIDTH  {1} \
                                    CONFIG.C_INPUT_PIPE_STAGES ${number_of_input_pipe_stages} \
                                    CONFIG.C_PROBE0_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE1_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE2_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE3_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE4_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE5_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE6_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE7_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE8_MU_CNT  ${number_of_comparators} \
                                    CONFIG.C_PROBE10_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE11_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE12_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE13_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE14_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE15_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE16_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE17_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE18_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE19_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE20_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE21_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE22_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_PROBE23_MU_CNT ${number_of_comparators} \
                                    CONFIG.ALL_PROBE_SAME_MU_CNT ${number_of_comparators} \
                                    CONFIG.C_ADV_TRIGGER {false} \
                                    ]

generate_new_ip ${generated_ip_path} ${ip_name} ${ip_version} ${ip_vendor} ${ip_library} ${component_name} ${configuration_parameters}