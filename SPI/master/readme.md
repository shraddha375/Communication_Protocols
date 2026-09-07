# SPI Master

This repository contains a modular System Verilog implementation of an SPI Master interface designed for the **Nexys A7 (Artix-7)** FPGA board. The system is split into two distinct modules: a top-level FPGA hardware wrapper (`nexys_spi_top`) and a reusable SPI Master controller core (`spi_master`).

---

## 1. Top-Level Module: `nexys_spi_top`

The `nexys_spi_top` module serves as the hardware interface wrapper for the Nexys A7 board. It handles asynchronous signal synchronization, edge detection for clean control triggering, hardware pin connections, and output status display.

### Key Responsibilities

* **Button Input Synchronization**: Synchronizes the asynchronous center push button (`btnC`) through a two-stage flip-flop register chain (`btnC_sync_0`, `btnC_sync_1`) to prevent metastability issues across clock domains.
* **Rising Edge Detection**: Implements a single flip-flop delay (`btnC_dly`) alongside logic gating (`btnC_sync_1 && !btnC_dly`) to generate a clean, single clock-cycle wide `start_pulse` every time `btnC` is pressed.
* **Onboard Peripheral Mapping**: Maps the FPGA's physical slide switches (`sw[7:0]`) to transmit data and drives the standard LEDs (`led[7:0]`) with received data.
* **Transaction Status Latch**: Tracks the SPI transaction state using an internal register (`done_led`). The status resets low when `start_pulse` fires and latches high when `spi_done` is asserted, driving the board's blue RGB LED (`led16_b`).

### Module Interface & Pinout Mapping

<img width="640" height="269" alt="image" src="https://github.com/user-attachments/assets/c6b69091-55cc-4eb9-8eda-f37e89dce2cf" />

| Port Name | Direction | Data Type | FPGA Pin | Description |
| --- | --- | --- | --- | --- |
| `clk` | Input | `logic` | `E3` | Primary 100 MHz oscillator |
| `btnCpuReset` | Input | `logic` | `C12` | Active-Low system reset button |
| `btnC` | Input | `logic` | `N17` | Center button (triggers single transfer) |
| `sw[7:0]` | Input | `logic [7:0]` | Switches | Transmit data byte payload |
| `led[7:0]` | Output | `logic [7:0]` | Standard LEDs | Latched received data byte |
| `led16_b` | Output | `logic` | `R12` | Blue RGB LED (`DONE` status indicator) |
| `ja_cs` | Output | `logic` | Pmod JA[1] | Chip Select line (`cs_n`, Active Low) |
| `ja_mosi` | Output | `logic` | Pmod JA[2] | Master Out Slave In line |
| `ja_miso` | Input | `logic` | Pmod JA[3] | Master In Slave Out line |
| `ja_sclk` | Output | `logic` | Pmod JA[4] | Serial SPI Clock output |

---

## 2. Core Controller Module: `spi_master`

The `spi_master` module is a generic, fully parameterized SPI Master core that executes SPI Mode 0 transfers (CPOL = 0, CPHA = 0). It uses an explicit finite state machine (FSM) architecture to manage data shifting, clock generation, and handshake signals.

### Key Responsibilities

* **Dynamic Parameterization**: Accepts configuration parameters for data width (`DATA_WIDTH`, default 8 bits) and clock division (`CLK_DIV`, default 100). The clock divider scales the input `clk` down to generate `sclk` (e.g., 100 MHz / 100 = 1 MHz SPI clock).
* **Clock Division Logic**: Maintains an internal counter (`scounter`) to generate half-period toggles for `sclk` and outputs a single-cycle strobe (`sclk_tick`) to synchronize internal state shifts.
* **SPI Mode 0 Timing**:
* **Data Output (MOSI)**: Updates on the **rising edge** of `sclk` (MSB first).
* **Data Input (MISO)**: Samples on the **falling edge** of `sclk` into the internal register (`rx_data_reg`).


* **FSM State Control**: Implements a 3-state state machine:
* `IDLE` (`2'b00`): Keeps `cs_n` High and `done` Low. On `start`, captures `tx_data` into `shift_reg` and prepares the MSB bit on `mosi`.
* `TRANSFER` (`2'b01`): Pulls `cs_n` Low. Increments bit counters, toggles `sclk`, shifts out MOSI bits, and samples MISO bits.
* `DONE` (`2'b10`): Returns `cs_n` High, asserts the `done` signal for one clock cycle, and returns to `IDLE`.



### Parameter Definitions

| Parameter | Default Value | Description |
| --- | --- | --- |
| `DATA_WIDTH` | `8` | Width of the SPI data bus in bits |
| `CLK_DIV` | `100` | Integer division ratio (`System Clock / Target SPI Clock`) |


### Module Interface & I/O Ports

<img width="640" height="273" alt="image" src="https://github.com/user-attachments/assets/cba97c9d-da1b-4d98-9148-7b5af92675d4" />

| Port Name | Direction | Data Type / Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | `wire` / 1-bit | Primary system clock input |
| `rst_n` | Input | `wire` / 1-bit | Active-Low asynchronous reset signal |
| `start` | Input | `wire` / 1-bit | High pulse trigger to initiate transfer |
| `tx_data` | Input | `wire` / `[DATA_WIDTH-1:0]` | Data payload to transmit to SPI slave |
| `sclk` | Output | `logic` / 1-bit | Serial SPI Clock output |
| `mosi` | Output | `logic` / 1-bit | Master Out Slave In serial data line |
| `miso` | Input | `wire` / 1-bit | Master In Slave Out serial data line |
| `cs_n` | Output | `logic` / 1-bit | Active-Low Chip Select line |
| `rx_data` | Output | `logic` / `[DATA_WIDTH-1:0]` | Parallel received data byte from SPI slave |
| `done` | Output | `logic` / 1-bit | Single clock cycle pulse indicating transfer completion |

---

---

## Hardware Testing & Verification

1. **Hardware Requirements**: AMD Vivado Design Suite and a Digilent Nexys A7 FPGA Board (`xc7a100tcsg324-1`).
2. **Loopback Testing**: Connect a physical jumper wire between Pmod header pin **JA[2] (`ja_mosi`)** and pin **JA[3] (`ja_miso`)**.
3. **Execution**: Set `sw[7:0]` to any test byte and press `btnC`. The values set on `sw[7:0]` will instantly display on `led[7:0]`, and `led16_b` will light up blue to indicate a successful 8-bit transaction.

---

## License

This project is open-source software made available under the **MIT License**.


# SystemVerilog SPI Controller (Nexys A7)

This repository contains a modular SystemVerilog implementation of an SPI Master interface designed for the **Nexys A7 (Artix-7)** FPGA board. The system is split into two distinct modules: a top-level FPGA hardware wrapper (`nexys_spi_top`) and a reusable SPI Master controller core (`spi_master`).

---

## 1. Top-Level Module: `nexys_spi_top`

The `nexys_spi_top` module serves as the hardware interface wrapper for the Nexys A7 board. It handles asynchronous signal synchronization, edge detection for clean control triggering, hardware pin connections, and output status display.

### Key Responsibilities

* **Button Input Synchronization**: Synchronizes the asynchronous center push button (`btnC`) through a two-stage flip-flop register chain (`btnC_sync_0`, `btnC_sync_1`) to prevent metastability issues across clock domains.
* **Rising Edge Detection**: Implements a single flip-flop delay (`btnC_dly`) alongside logic gating (`btnC_sync_1 && !btnC_dly`) to generate a clean, single clock-cycle wide `start_pulse` every time `btnC` is pressed.
* **Onboard Peripheral Mapping**: Maps the FPGA's physical slide switches (`sw[7:0]`) to transmit data and drives the standard LEDs (`led[7:0]`) with received data.
* **Transaction Status Latch**: Tracks the SPI transaction state using an internal register (`done_led`). The status resets low when `start_pulse` fires and latches high when `spi_done` is asserted, driving the board's blue RGB LED (`led16_b`).

### Module Interface & Pinout Mapping

| Port Name | Direction | Data Type | FPGA Pin | Description |
| --- | --- | --- | --- | --- |
| `clk` | Input | `logic` | `E3` | Primary 100 MHz oscillator |
| `btnCpuReset` | Input | `logic` | `C12` | Active-Low system reset button |
| `btnC` | Input | `logic` | `N17` | Center button (triggers single transfer) |
| `sw[7:0]` | Input | `logic [7:0]` | Switches | Transmit data byte payload |
| `led[7:0]` | Output | `logic [7:0]` | Standard LEDs | Latched received data byte |
| `led16_b` | Output | `logic` | `R12` | Blue RGB LED (`DONE` status indicator) |
| `ja_cs` | Output | `logic` | Pmod JA[1] | Chip Select line (`cs_n`, Active Low) |
| `ja_mosi` | Output | `logic` | Pmod JA[2] | Master Out Slave In line |
| `ja_miso` | Input | `logic` | Pmod JA[3] | Master In Slave Out line |
| `ja_sclk` | Output | `logic` | Pmod JA[4] | Serial SPI Clock output |

---

## 2. Core Controller Module: `spi_master`

The `spi_master` module is a generic, fully parameterized SPI Master core that executes SPI Mode 0 transfers (CPOL = 0, CPHA = 0). It uses an explicit finite state machine (FSM) architecture to manage data shifting, clock generation, and handshake signals.

### Key Responsibilities

* **Dynamic Parameterization**: Accepts configuration parameters for data width (`DATA_WIDTH`, default 8 bits) and clock division (`CLK_DIV`, default 100). The clock divider scales the input `clk` down to generate `sclk` (e.g., 100 MHz / 100 = 1 MHz SPI clock).
* **Clock Division Logic**: Maintains an internal counter (`scounter`) to generate half-period toggles for `sclk` and outputs a single-cycle strobe (`sclk_tick`) to synchronize internal state shifts.
* **SPI Mode 0 Timing**:
* **Data Output (MOSI)**: Updates on the **rising edge** of `sclk` (MSB first).
* **Data Input (MISO)**: Samples on the **falling edge** of `sclk` into the internal register (`rx_data_reg`).


* **FSM State Control**: Implements a 3-state state machine:
* `IDLE` (`2'b00`): Keeps `cs_n` High and `done` Low. On `start`, captures `tx_data` into `shift_reg` and prepares the MSB bit on `mosi`.
* `TRANSFER` (`2'b01`): Pulls `cs_n` Low. Increments bit counters, toggles `sclk`, shifts out MOSI bits, and samples MISO bits.
* `DONE` (`2'b10`): Returns `cs_n` High, asserts the `done` signal for one clock cycle, and returns to `IDLE`.



### Parameter Definitions

| Parameter | Default Value | Description |
| --- | --- | --- |
| `DATA_WIDTH` | `8` | Width of the SPI data bus in bits |
| `CLK_DIV` | `100` | Integer division ratio (`System Clock / Target SPI Clock`) |



## Hardware Testing & Verification

1. **Hardware Requirements**: AMD Vivado Design Suite and a Digilent Nexys A7 FPGA Board (`xc7a100tcsg324-1`).
2. **Loopback Testing**: Connect a physical jumper wire between Pmod header pin **JA[2] (`ja_mosi`)** and pin **JA[3] (`ja_miso`)**.
3. **Execution**: Set `sw[7:0]` to any test byte and press `btnC`. The values set on `sw[7:0]` will instantly display on `led[7:0]`, and `led16_b` will light up blue to indicate a successful 8-bit transaction.

Testcase 1: When all `sw[7:0] = {0, 0, 0, 0, 0, 0, 0, 0}` 

<img width="1600" height="883" alt="image" src="https://github.com/user-attachments/assets/b1d54aca-b03a-453e-b904-65b14e582610" />

Testcase 2: When all `sw[7:0] = {1, 1, 1, 1, 1, 1, 1, 1}`

<img width="1600" height="936" alt="image" src="https://github.com/user-attachments/assets/e837ddd9-0681-4e65-8181-87a35d3ec3f3" />

Testcase 3: When all `sw[7:0] = {1, 0, 1, 1, 1, 0, 1, 0}`

<img width="1600" height="929" alt="image" src="https://github.com/user-attachments/assets/c202755a-b0d6-4914-b326-e8cabd4153ed" />

---
