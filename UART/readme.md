# UART Protocol

- Universal Asynchronous Receiver Transmitter
- Asynchronous Communication Interface
- Full/Half Duplex
- It is used to transmite data at a lower date rate and where the distance of transmission is small.
- In asynchronous communication, baud rate measures the speed of data transmission. Baud rate accounts for all bits sent, including start, stop, and parity bits.
- The actual data transfer speed, represented as bit rate (bps), indicates the amount of data transmitted from the sender to the receiver.
- UART speeds are expressed in bits per second (bit/s or bps).
- Standard baud rates are as follows: 110, 300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 76800, 115200, 230400, 460800, 921600, 1382400, 1843200, and 2764800 bit/s.
- 8250 -> 9600, 19200
- 16450 -> 38.4 kbps
- 16550A

## Agenda

- UART with only single baud rate.
- UART 16550 -> FIFO, TX Logic, RX Logic, UART Registers
