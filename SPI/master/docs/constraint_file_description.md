## **Keyword Glossary**

* **`#`**: Comment marker. Anything following this on the same line is ignored by Vivado.
* **`set_property`**: Tcl command used to assign a specific attribute or property to a hardware object in the design.
* **`-dict`**: Argument allowing multiple property-value pairs to be passed together inside a dictionary (`{ ... }`).
* **`PACKAGE_PIN`**: Property defining the physical pin coordinate on the FPGA chip (e.g., `E3`, `J15`).
* **`IOSTANDARD`**: Property defining the electrical signaling standard and voltage level for an I/O pin (e.g., `LVCMOS33` = 3.3V Low-Voltage CMOS).
* **`[get_ports { ... }]`**: Tcl query function that searches the top-level Verilog/SystemVerilog module wrapper and returns the matching top-level port signal name.
* **`create_clock`**: Timing constraint command that instructs Vivado's static timing analysis (STA) engine to treat a signal as an active clock tree.
* **`-add`**: Allows defining additional clocks on a port without overwriting existing ones.
* **`-name`**: Assigns an internal identifier to the clock object for timing reports.
* **`-period`**: Specifies the clock cycle time in nanoseconds ($ns$).
* **`-waveform`**: Defines the `{rising_edge_time falling_edge_time}` in nanoseconds within one period to establish the clock duty cycle.

---

## **Line-by-Line Breakdown**

### **Clock Signal Constraints**

* `set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];`
* Maps the top-level port `clk` to physical FPGA pin **E3** (the 100 MHz oscillator on the Nexys A7) using 3.3V logic levels.


* `create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];`
* Tells the timing engine that `clk` is a 100 MHz clock source ($T = 10.00\text{ ns}$). `-waveform {0 5}` sets the rising edge at $0\text{ ns}$ and falling edge at $5\text{ ns}$, producing a 50% duty cycle.



### **Control Inputs (Reset & Start Buttons)**

* `set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { btnCpuReset }];`
* Maps `btnCpuReset` to pin **C12** (the red CPU RESET pushbutton).


* `set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports { btnC }];`
* Maps `btnC` to pin **N17** (the center push button on the 5-button d-pad).



### **Data Input Switches (`sw[7:0]`)**

* `set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];` through `... [get_ports { sw[7] }];`
* Maps the 8-bit input vector `sw` bit-by-bit to the board's 8 rightmost slide switches (**J15**, **L16**, **M13**, **R15**, **R17**, **T18**, **U18**, **R13**).



### **Data Output LEDs (`led[7:0]`)**

* `set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { led[0] }];` through `... [get_ports { led[7] }];`
* Maps the 8-bit output vector `led` bit-by-bit to the 8 rightmost green LEDs (**H17**, **K15**, **J13**, **N14**, **R18**, **V17**, **U17**, **U16**).



### **Status Indicator LED**

* `set_property -dict { PACKAGE_PIN R12 IOSTANDARD LVCMOS33 } [get_ports { led16_b }];`
* Maps `led16_b` to pin **R12** (the blue element of RGB LED 16).



### **Pmod JA Header (SPI Interface)**

* `set_property -dict { PACKAGE_PIN C17 IOSTANDARD LVCMOS33 } [get_ports { ja_cs }];`
* Maps Chip Select (`cs_n`) output to pin **C17** (Pmod JA Pin 1).


* `set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports { ja_mosi }];`
* Maps Master-Out Slave-In (`mosi`) output to pin **D18** (Pmod JA Pin 2).


* `set_property -dict { PACKAGE_PIN E18 IOSTANDARD LVCMOS33 } [get_ports { ja_miso }];`
* Maps Master-In Slave-Out (`miso`) input to pin **E18** (Pmod JA Pin 3).


* `set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports { ja_sclk }];`
* Maps Serial Clock (`sclk`) output to pin **G17** (Pmod JA Pin 4).
