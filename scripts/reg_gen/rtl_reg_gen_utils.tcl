##################################################
## Script to synthesizable RTL register blocks
##################################################

set generic_register_template {
  always @(posedge $CLK or negedge $RST)
    if (~$RST) $GENERIC_REGISTER <= \'h$GENERIC_DEF_VAL;
    else $GENERIC_REGISTER <= ($GENERIC_WR) ? $GENERIC_WR_DATA : $GENERIC_REGISTER;
}

set generic_simple_register_template {
  always @(posedge $CLK or negedge $RST)
    if (~$RST) $GENERIC_REGISTER <= \'h$GENERIC_DEF_VAL;
    else $GENERIC_REGISTER <= $GENERIC_WR_DATA;
}

## Generata a register that is set by SW and cleared by HW
proc gen_REG_SW_WR1_HW_CLR {REG ADDR SIG_PARAMS} {
  global generic_register_template
  set CLK                  [dict get $SIG_PARAMS CLK]
  set RST                  [dict get $SIG_PARAMS RST]
  set WE_SIGNAL            [dict get $SIG_PARAMS WE_SIGNAL]
  set WRITE_DATA_SIGNAL    [dict get $SIG_PARAMS WRITE_DATA_SIGNAL]
  set READ_DATA_SIGNAL     [dict get $SIG_PARAMS READ_DATA_SIGNAL]
  set ADDRESS_WRITE_SIGNAL [dict get $SIG_PARAMS ADDRESS_WRITE_SIGNAL]

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME          [dict get $REG rtl_name]
  set DEFAULT_VALUE [dict get $REG default_value]

  set update_signal       "UPDATE_${NAME}"
  set next_value_signal   "NEXT_${NAME}"
  set clear_signal        "CLEAR_${NAME}"
  set write_enable_signal "WE_${NAME}"
  set GENERIC_REGISTER    "REG_${NAME}"
  set GENERIC_DEF_VAL     $DEFAULT_VALUE
  set GENERIC_WR          $update_signal
  set GENERIC_WR_DATA     $next_value_signal

  append output_str "  // Register name: $NAME\n"
  append output_str "  // Generata a register that is set by SW and cleared by HW\n"
  append output_str "  logic $update_signal;\n"
  append output_str "  logic $next_value_signal;\n"
  append output_str "  logic $write_enable_signal;\n"
  append output_str "  assign $write_enable_signal     = ($ADDRESS_WRITE_SIGNAL == $ADDR) ? $WE_SIGNAL : 0;\n"
  append output_str "  assign $update_signal = ($write_enable_signal && $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \]) | $clear_signal;\n"
  append output_str "  assign $next_value_signal   = $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] && ~$clear_signal;\n"
  append output_str [subst $generic_register_template]

  set input_signals   [list $clear_signal 0]
  set output_signals  [list $GENERIC_REGISTER 0]
  set readback_signal "$READ_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] = $GENERIC_REGISTER;"

  return [list $output_str $input_signals $output_signals $readback_signal $write_signal]
}

## Generata a register that is set by HW and cleared by SW
proc gen_REG_HW_WR1_SW_CLR {REG ADDR SIG_PARAMS} {
  global generic_register_template
  set CLK                  [dict get $SIG_PARAMS CLK]
  set RST                  [dict get $SIG_PARAMS RST]
  set WE_SIGNAL            [dict get $SIG_PARAMS WE_SIGNAL]
  set WRITE_DATA_SIGNAL    [dict get $SIG_PARAMS WRITE_DATA_SIGNAL]
  set READ_DATA_SIGNAL     [dict get $SIG_PARAMS READ_DATA_SIGNAL]
  set ADDRESS_WRITE_SIGNAL [dict get $SIG_PARAMS ADDRESS_WRITE_SIGNAL]

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME          [dict get $REG rtl_name]
  set DEFAULT_VALUE [dict get $REG default_value]

  set update_signal       "UPDATE_${NAME}"
  set next_value_signal   "NEXT_${NAME}"
  set set_signal          "${NAME}"
  set write_enable_signal "WE_${NAME}"
  set GENERIC_REGISTER    "REG_${NAME}"
  set GENERIC_DEF_VAL     $DEFAULT_VALUE
  set GENERIC_WR          $update_signal
  set GENERIC_WR_DATA     $next_value_signal

  append output_str "  // Register name: $NAME\n"
  append output_str "  // Generata a register that is set by HW and cleared by SW\n"
  append output_str "  logic $update_signal;\n"
  append output_str "  logic $next_value_signal;\n"
  append output_str "  logic $write_enable_signal;\n"
  append output_str "  logic $GENERIC_REGISTER;\n"
  append output_str "  assign $write_enable_signal     = ($ADDRESS_WRITE_SIGNAL == $ADDR) ? $WE_SIGNAL : 0;\n"
  append output_str "  assign $update_signal = ($write_enable_signal && $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \]) | $set_signal;\n"
  append output_str "  assign $next_value_signal   = ($write_enable_signal && $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \]) ? 1'b0 : $set_signal;\n"
  append output_str [subst $generic_register_template]

  set input_signals   [list $set_signal 0]
  #set output_signals  [list $GENERIC_REGISTER 0]
  set readback_signal "$READ_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] = $GENERIC_REGISTER;"

  return [list $output_str $input_signals $output_signals $readback_signal $write_signal]
}

## Generata a register that can be set by SW, but only read by HW
proc gen_REG_SW_RW_HW_RO {REG ADDR SIG_PARAMS} {
  global generic_register_template
  set CLK                  [dict get $SIG_PARAMS CLK]
  set RST                  [dict get $SIG_PARAMS RST]
  set WE_SIGNAL            [dict get $SIG_PARAMS WE_SIGNAL]
  set WRITE_DATA_SIGNAL    [dict get $SIG_PARAMS WRITE_DATA_SIGNAL]
  set READ_DATA_SIGNAL     [dict get $SIG_PARAMS READ_DATA_SIGNAL]
  set ADDRESS_WRITE_SIGNAL [dict get $SIG_PARAMS ADDRESS_WRITE_SIGNAL]

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME          [dict get $REG rtl_name]
  set SIZE          [expr [dict get $REG msb] - [dict get $REG lsb]]
  set DEFAULT_VALUE [dict get $REG default_value]

  set update_signal       "UPDATE_${NAME}"
  set next_value_signal   "NEXT_${NAME}"
  set write_enable_signal "WE_${NAME}"
  set GENERIC_REGISTER    "REG_${NAME}"
  set GENERIC_DEF_VAL     $DEFAULT_VALUE
  set GENERIC_WR          $update_signal
  set GENERIC_WR_DATA     $next_value_signal

  append output_str "  // Register name: $NAME\n"
  append output_str "  // Generata a register that can be set by SW, but only read by HW\n"
  append output_str "  logic $update_signal;\n"
  append output_str "  logic \[ $SIZE : 0 \] $next_value_signal;\n"
  append output_str "  logic $write_enable_signal;\n"
  append output_str "  assign $write_enable_signal     = ($ADDRESS_WRITE_SIGNAL == $ADDR) ? $WE_SIGNAL : 0;\n"
  append output_str "  assign $update_signal = $write_enable_signal;\n"
  append output_str "  assign $next_value_signal   = $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \];\n"
  append output_str [subst $generic_register_template]

  set output_signals  [list $GENERIC_REGISTER $SIZE]
  set readback_signal "$READ_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] = $GENERIC_REGISTER;"

  return [list $output_str $input_signals $output_signals $readback_signal $write_signal]
}

## Generata a register that can be set by HW, but only read by SW
proc gen_REG_HW_RW_SW_RO {REG ADDR SIG_PARAMS} {
  global generic_simple_register_template
  set CLK                  [dict get $SIG_PARAMS CLK]
  set RST                  [dict get $SIG_PARAMS RST]
  set WE_SIGNAL            [dict get $SIG_PARAMS WE_SIGNAL]
  set WRITE_DATA_SIGNAL    [dict get $SIG_PARAMS WRITE_DATA_SIGNAL]
  set READ_DATA_SIGNAL     [dict get $SIG_PARAMS READ_DATA_SIGNAL]
  set ADDRESS_WRITE_SIGNAL [dict get $SIG_PARAMS ADDRESS_WRITE_SIGNAL]

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME          [dict get $REG rtl_name]
  set SIZE          [expr [dict get $REG msb] - [dict get $REG lsb]]
  set DEFAULT_VALUE [dict get $REG default_value]

  set next_value_signal   "NEXT_${NAME}"
  set write_data_signal   ${NAME}
  set GENERIC_REGISTER    "REG_${NAME}"
  set GENERIC_DEF_VAL     $DEFAULT_VALUE
  set GENERIC_WR_DATA     $next_value_signal

  append output_str "  // Register name: $NAME\n"
  append output_str "  // Generata a register that can be set by HW, but only read by SW\n"
  append output_str "  logic \[ $SIZE : 0 \] $next_value_signal;\n"
  append output_str "  logic \[ $SIZE : 0 \] $GENERIC_REGISTER;\n"
  append output_str "  assign $next_value_signal = $write_data_signal;\n"
  append output_str [subst $generic_simple_register_template]

  set input_signals   [list $write_data_signal   $SIZE ]
  set readback_signal "$READ_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] = $GENERIC_REGISTER;"

  return [list $output_str $input_signals $output_signals $readback_signal $write_signal]
}

###########################################

## Generate Read mux
proc generate_read_mux {MUX_DATA SIG_PARAMS} {
  set ADDRESS_READ_SIGNAL [dict get $SIG_PARAMS ADDRESS_READ_SIGNAL]
  set READ_DATA_SIGNAL    [dict get $SIG_PARAMS READ_DATA_SIGNAL]

  set    output_str "  // Readback mux\n"
  append output_str "  always_comb begin\n"
  append output_str "    $READ_DATA_SIGNAL \[ 31 : 0 \] = 'h0;\n"
  append output_str "    case($ADDRESS_READ_SIGNAL)\n"

  foreach {assignments address reg_name} $MUX_DATA {
    append output_str "      'h[format %0x $address] : begin // $reg_name\n"
    #append output_str "        $READ_DATA_SIGNAL \[ 31 : 0 \] = 'h0;\n"
    foreach assignment $assignments {
      append output_str "        $assignment\n"
    }
    append output_str "      end\n"
  }

  append output_str "      default: $READ_DATA_SIGNAL \[ 31 : 0 \] = 32'hbeefdded;\n"
  append output_str "    endcase\n"
  append output_str "  end\n"
  return $output_str
}

## Generate the top-level IO
proc generate_top_io {INPUTS OUTPUTS} {

  set output_str ""
  foreach reg $INPUTS {
    if {[lindex $reg 1] == ""} {continue}
    append output_str "  // [lindex $reg 0]\n"
    foreach {name size} [lindex $reg 1] {
      append output_str "  input wire \[ [expr $size] : 0 ] $name,\n"
    }
  }

  append output_str "\n\n"

  foreach reg $OUTPUTS {
    if {[lindex $reg 1] == ""} {continue}
    append output_str "  // [lindex $reg 0]\n"
    foreach {name size} [lindex $reg 1] {
      append output_str "  output logic \[ [expr $size] : 0 ] $name,\n"
    }
  }

  return $output_str 
}

proc generate_reg_module {MODULE_NAME TOP_IO BODY READ_MUX SIG_PARAMS} {
  set CLK                  [dict get $SIG_PARAMS CLK]
  set RST                  [dict get $SIG_PARAMS RST]
  set WE_SIGNAL            [dict get $SIG_PARAMS WE_SIGNAL]
  set WRITE_DATA_SIGNAL    [dict get $SIG_PARAMS WRITE_DATA_SIGNAL]
  set READ_DATA_SIGNAL     [dict get $SIG_PARAMS READ_DATA_SIGNAL]
  set ADDRESS_READ_SIGNAL  [dict get $SIG_PARAMS ADDRESS_READ_SIGNAL]
  set ADDRESS_WRITE_SIGNAL [dict get $SIG_PARAMS ADDRESS_WRITE_SIGNAL]

  set output_str ""
  append output_str "// Register module generated automatically\n"
  append output_str "\n\n"
  append output_str "`default_nettype none\n"
  append output_str "\n\n"
  append output_str "module $MODULE_NAME (\n"
  append output_str "  // Clock and Reset\n"
  append output_str "  input wire $CLK,\n"
  append output_str "  input wire $RST,\n\n"
  append output_str "  // Register IO Signals //\n"
  append output_str "$TOP_IO\n"
  append output_str "  // Data Bus Read/Write signals //\n"
  append output_str "  input  wire  \[ 31 : 0 \] $ADDRESS_READ_SIGNAL,\n"
  append output_str "  output logic \[ 31 : 0 \] $READ_DATA_SIGNAL,\n"
  append output_str "  input  wire  \[ 31 : 0 \] $ADDRESS_WRITE_SIGNAL,\n"
  append output_str "  input  wire  \[ 31 : 0 \] $WRITE_DATA_SIGNAL,\n"
  append output_str "  input  wire             $WE_SIGNAL\n"
  append output_str ");\n"
  append output_str "\n\n"
  append output_str "  // -----------------------------------------\n"
  append output_str "  // Registers\n"
  append output_str "  // -----------------------------------------\n\n"
  append output_str "$BODY"
  append output_str "\n\n"
  append output_str "  // -----------------------------------------\n"
  append output_str "  // Register read mechanism\n"
  append output_str "  // -----------------------------------------\n\n"
  append output_str "$READ_MUX"
  append output_str "\n\n"
  append output_str "endmodule\n"
  append output_str "`default_nettype wire\n"

  return $output_str

}

## Generate RTL Register files
proc generate_rtl_registers {module_name register_blocks output_directory sig_params} {
  if {$module_name == ""} {
    puts "ERROR: No module name specified!"
    return
  }
  puts "------------------------------------"
  puts "Generating registers for $module_name"
  puts "------------------------------------"

  set inputs   [list]
  set outputs  [list]
  set mux_data [list]
  set reg_body ""

  foreach {reg addr} $register_blocks {
    global $reg
    array  set new_reg [array get $reg]
    set    reg_name    [dict get $reg name]
    set    reg_fields  [dict get $reg fields]
    puts   "Reg = $reg_name | Addr = $addr"

    set readback [list]

    append reg_body "  /////////////////////////\n"
    append reg_body "  //  Register $reg_name\n"
    append reg_body "  //  Address  [format "'h%0x" $addr]\n"
    append reg_body "  /////////////////////////\n\n"

    ## Generate all the register fields
    foreach {name field} $reg_fields {
      set     reg_generator "gen_[dict get $field type]"
      lassign [$reg_generator $field [format "'h%0x" $addr] $sig_params] curr_body curr_inputs curr_outputs curr_readback curr_write
      append  reg_body $curr_body
      append  reg_body "\n\n"
      lappend inputs   [list $name $curr_inputs]
      lappend outputs  [list $name $curr_outputs]
      lappend readback $curr_readback
    }

    lappend mux_data $readback $addr $reg_name
  }

  set reg_top_io   [generate_top_io     $inputs $outputs]
  set reg_read_mux [generate_read_mux   $mux_data        $sig_params]
  set reg_module   [generate_reg_module $module_name     $reg_top_io $reg_body $reg_read_mux $sig_params]

  ## Write to output
  if {![file exists $output_directory]} {
    file mkdir $output_directory
  }
  set fp [open "${output_directory}/${module_name}.sv" w]
  puts $fp $reg_module
  close $fp
}