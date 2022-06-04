# Quartus script to create project for the EP2C5T144 minimal board
#
# Invoke with quartus_sh -t KIM_EP2C5.tcl
#

project_new KIM_EP2C5 -overwrite

foreach {name value} {
    FAMILY "Cyclone II"
    DEVICE EP2C5T144C8
    TOP_LEVEL_ENTITY KIM_EP2C5        
    STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"
    RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED WITH WEAK PULL-UP"

    MIN_CORE_JUNCTION_TEMP 0
    MAX_CORE_JUNCTION_TEMP 85
} { set_global_assignment -name $name $value }

foreach svfile {
    KIM_1.sv
    mcs6530.sv
    KIM_EP2C5.sv
} { set_global_assignment -name SYSTEMVERILOG_FILE $svfile }

foreach vfile {
    mcs6502.v
} { set_global_assignment -name VERILOG_FILE $vfile }

# HP 5301 Common Anode 7-segment display pinout
#
#  g f A a b
# 10 9 8 7 6
#
#
#  1 2 3 4 5
#  e d A c DP

foreach {signal pin} {
    clk50  PIN_17
    LED[0] PIN_3
    LED[1] PIN_7
    LED[2] PIN_9
    KEY    PIN_144

    LED_DIG[4] PIN_65
    LED_DIG[5] PIN_67
    LED_DIG[6] PIN_69
    LED_DIG[7] PIN_70
    LED_DIG[8] PIN_71
    LED_DIG[9] PIN_72

    LED_SEG[0] PIN_26
    LED_SEG[1] PIN_41
    LED_SEG[2] PIN_27
    LED_SEG[3] PIN_30
    LED_SEG[4] PIN_32
    LED_SEG[5] PIN_28
    LED_SEG[6] PIN_31

    RS_KEY PIN_64
    ST_KEY PIN_63

    KB_ROW[0] PIN_40
    KB_ROW[1] PIN_43
    KB_ROW[2] PIN_42
    
    KB_ROW[3] PIN_99

    KB_COL[0] PIN_44
    KB_COL[1] PIN_45
    KB_COL[2] PIN_47
    KB_COL[3] PIN_48
    KB_COL[4] PIN_51
    KB_COL[5] PIN_52
    KB_COL[6] PIN_53

    ENABLE_TTY PIN_113
    TTYO  PIN_112
    TTYI  PIN_114

    PA[0] PIN_120
    PA[1] PIN_121
    PA[2] PIN_122
    PA[3] PIN_125
    PA[4] PIN_126
    PA[5] PIN_129
    PA[6] PIN_132
    PA[7] PIN_133

    PB[0] PIN_134
    PB[1] PIN_135
    PB[2] PIN_136
    PB[3] PIN_137
    PB[4] PIN_139
    PB[5] PIN_141
    PB[6] PIN_142
    PB[7] PIN_143
   
    AUDIOO  PIN_104
    AUDIOI  PIN_101

} {
    set_location_assignment $pin -to $signal
    set_instance_assignment -name OUTPUT_PIN_LOAD 20 -to $signal
}

# Turn on the weak pull-up resistors on various inputs

foreach signal {
    KEY
    KB_COL[0]
    KB_COL[1]
    KB_COL[2]
    KB_COL[3]
    KB_COL[4]
    KB_COL[5]
    KB_COL[6]
    RS_KEY
    ST_KEY
    ENABLE_TTY
} { set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to $signal }

export_assignments

package require ::quartus::flow
execute_flow -compile


set unused {
}
