##########################################
## MIDI to UART bridge
##########################################

import sys
import struct

import mido as mido
import serial as serial

## Global settings
BAUD_RATE   = 115200
DATA_BITS   = 8
STOP_BITS   = 1
PARITY_BITS = 0

MIDI_CMD    = b'midi'

def list_serial_ports():
    """ Lists serial port names

        :raises EnvironmentError:
            On unsupported or unknown platforms
        :returns:
            A list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*')
    else:
        raise EnvironmentError('Unsupported platform')

    result = []
    for port in ports:
        try:
            s = serial.Serial(port)
            s.close()
            result.append(port)
        except (OSError, serial.SerialException):
            pass
    return result

def request_serial_port():
    ## Get all serial ports
    serial_ports = list_serial_ports()

    if serial_ports == []:
        print "[ERROR] - There are no serial ports!"
        return None

    valid_input = False

    while valid_input == False:
        print "Please select one of the serial ports...\n"

        for i in range (0, len(serial_ports)):
            print "[{}] -> \"{}\"".format(i, serial_ports[i])

        print ""
        key_input = raw_input("NUMBER>> ")

        selection = int(key_input)

        if selection in range(0, len(serial_ports)): valid_input = True


    return serial_ports[selection]

def request_midi_port():
    ## Get all the MIDI devices
    input_names = mido.get_input_names()

    if input_names == []:
        print "[ERROR] - There are no MIDI ports!"
        return None

    valid_input = False

    while valid_input == False:
        print "Please select one of the MIDI devices as the input port...\n"

        for i in range (0, len(input_names)):
            print "[{}] -> \"{}\"".format(i, input_names[i])

        print ""
        key_input = raw_input("NUMBER>> ")

        selection = int(key_input)

        if selection in range(0, len(input_names)): valid_input = True


    return input_names[selection]


def main():
    print "================================="
    print " Welcome to the MIDI-UART bridge"
    print "=================================\n\n"

    midi_port   = request_midi_port()
    serial_port = request_serial_port()

    if ( ( midi_port == None ) or ( serial_port == None ) ):
        return 1

    ## Open MIDI port
    inport = mido.open_input()


    ## Open the Serial Port
    ser          = serial.Serial()
    ser.baudrate = BAUD_RATE
    ser.port     = serial_port
    ser.parity   = serial.PARITY_NONE
    ser.stopbits = serial.STOPBITS_ONE
    ser.bytesize = serial.EIGHTBITS
    ser.timeout  = 0

    ser.open()

    for msg in inport:
        msg_bytes = msg.bytes()
        values    = bytearray( msg_bytes )

        #print "{}".format( " ".join( hex(x) for x in values) )
        #print "--"
        ser.write( values )


    return 0


if __name__ == "__main__":
    error = main()
    sys.exit( error )