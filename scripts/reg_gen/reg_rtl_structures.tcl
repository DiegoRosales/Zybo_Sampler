## Register structures for synthesizable RTL

set generic_register_template {
  always @(posedge $CLK or negedge $RST)
    if (~$RST) $GENERIC_REGISTER <= $GENERIC_DEF_VAL;
    else $GENERIC_REGISTER <= ($GENERIC_WR) ? $GENERIC_WR_DATA : $GENERIC_REGISTER;
}

## Generata a register that is set by SW and cleared by HW
proc gen_REG_SW_WR1_HW_CLR {REG ADDR} {
  global generic_register_template
  global CLK
  global RST
  global WE_SIGNAL
  global WRITE_DATA_SIGNAL
  global READ_DATA_SIGNAL
  global ADDRESS_WRITE_SIGNAL

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME [dict get $REG rtl_name]
  set DEFAULT_VALUE 0

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
proc gen_REG_HW_WR1_SW_CLR {REG ADDR} {
  global generic_register_template
  global CLK
  global RST
  global WE_SIGNAL
  global WRITE_DATA_SIGNAL
  global READ_DATA_SIGNAL
  global ADDRESS_WRITE_SIGNAL
  
  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME [dict get $REG rtl_name]
  set DEFAULT_VALUE 0

  set update_signal       "UPDATE_${NAME}"
  set next_value_signal   "NEXT_${NAME}"
  set set_signal          "SET_${NAME}"
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
  append output_str "  assign $write_enable_signal     = ($ADDRESS_WRITE_SIGNAL == $ADDR) ? $WE_SIGNAL : 0;\n"
  append output_str "  assign $update_signal = ($write_enable_signal && $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \]) | $set_signal;\n"
  append output_str "  assign $next_value_signal   = ($write_enable_signal && $WRITE_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \]) ? 1'b0 : $set_signal;\n"
  append output_str [subst $generic_register_template]

  set input_signals   [list $set_signal 0]
  set output_signals  [list $GENERIC_REGISTER 0]
  set readback_signal "$READ_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] = $GENERIC_REGISTER;"

  return [list $output_str $input_signals $output_signals $readback_signal $write_signal]
}

## Generata a register that can be set by SW, but only read by HW
proc gen_REG_SW_RW_HW_RO {REG ADDR} {
  global generic_register_template
  global CLK
  global RST
  global WE_SIGNAL
  global WRITE_DATA_SIGNAL
  global READ_DATA_SIGNAL
  global ADDRESS_WRITE_SIGNAL

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME [dict get $REG rtl_name]
  set SIZE [expr [dict get $REG msb] - [dict get $REG lsb]]
  set DEFAULT_VALUE 0

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
  append output_str "  logic \[ [expr $SIZE - 1] : 0 \] $next_value_signal;\n"
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
proc gen_REG_HW_RW_SW_RO {REG ADDR} {
  global generic_register_template
  global CLK
  global RST
  global WE_SIGNAL
  global WRITE_DATA_SIGNAL
  global READ_DATA_SIGNAL
  global ADDRESS_WRITE_SIGNAL

  set output_str      ""
  set output_signals  ""
  set input_signals   ""
  set readback_signal ""
  set write_signal    ""

  set NAME [dict get $REG rtl_name]
  set SIZE [expr [dict get $REG msb] - [dict get $REG lsb]]
  set DEFAULT_VALUE 0

  set update_signal       "UPDATE_${NAME}"
  set next_value_signal   "NEXT_${NAME}"
  set write_enable_signal "WE_${NAME}"
  set write_data_signal   ${NAME}
  set GENERIC_REGISTER    "REG_${NAME}"
  set GENERIC_DEF_VAL     $DEFAULT_VALUE
  set GENERIC_WR          $update_signal
  set GENERIC_WR_DATA     $next_value_signal

  append output_str "  // Register name: $NAME\n"
  append output_str "  // Generata a register that can be set by HW, but only read by SW\n"
  append output_str "  logic $update_signal;\n"
  append output_str "  logic \[ [expr $SIZE - 1] : 0 \] $next_value_signal;\n"
  append output_str "  logic \[ [expr $SIZE - 1] : 0 \] $GENERIC_REGISTER;\n"
  append output_str "  assign $update_signal = $write_enable_signal;\n"
  append output_str "  assign $next_value_signal   = $write_data_signal;\n"
  append output_str [subst $generic_register_template]

  set input_signals   [list $write_enable_signal 0     \
                            $write_data_signal   $SIZE \
                            ]
  set readback_signal "$READ_DATA_SIGNAL\[ [dict get $REG msb] : [dict get $REG lsb] \] = $GENERIC_REGISTER;"

  return [list $output_str $input_signals $output_signals $readback_signal $write_signal]
}

###########################################

## Generate Read mux
proc generate_read_mux {MUX_DATA} {
  global ADDRESS_READ_SIGNAL
  global READ_DATA_SIGNAL

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

proc generate_reg_module {MODULE_NAME TOP_IO BODY READ_MUX} {
  global CLK
  global RST
  global WE_SIGNAL
  global WRITE_DATA_SIGNAL
  global READ_DATA_SIGNAL
  global ADDRESS_READ_SIGNAL
  global ADDRESS_WRITE_SIGNAL

  set output_str ""
  append output_str "// Register module generated automatically\n"
  append output_str "\n\n"
  append output_str "`default_nettype none\n"
  append output_str "\n\n"
  append output_str "module $MODULE_NAME (\n"
  append output_str "  // Clock and Reset\n"
  append output_str "  input wire $CLK,\n"
  append output_str "  input wire $RST,\n\n"
  append output_str "  // Register IO Signals\n"
  append output_str "  // $TOP_IO\n"
  append output_str "  // Data Bus Read/Write signals\n"
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