`timescale 1ns/1ps

module tb_spi_master;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam CLK_DIV    = 10;
    localparam CLK_PERIOD = 10; // 100 MHz System Clock

    // DUT Signals
    logic                  clk;
    logic                  rst_n;
    logic                  start;
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  sclk;
    logic                  mosi;
    logic                  miso;
    logic                  cs_n;
    logic [DATA_WIDTH-1:0] rx_data;
    logic                  done;

    // SPI Slave Emulation Variables
    logic [DATA_WIDTH-1:0] slave_tx_data;
    logic [DATA_WIDTH-1:0] slave_rx_data;
    integer                slave_bit_cnt;

    // Instantiate DUT (Device Under Test)
    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n),
        .rx_data(rx_data),
        .done(done)
    );

    // 1. System Clock Generator
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 2. SPI Slave Emulation Logic & Signal Monitors
    // CS_N activates slave
    always @(negedge cs_n) begin
        slave_bit_cnt = DATA_WIDTH - 1;
        miso <= slave_tx_data[slave_bit_cnt]; // Drive MSB on select
        $display("[%0t ps] [SLAVE] CS_N dropped low. Pre-driving MISO bit[%0d] = %b", $time, slave_bit_cnt, slave_tx_data[slave_bit_cnt]);
    end

    // Master shifts MOSI out / Slave shifts MISO out on SCLK Rising Edge
    always @(posedge sclk) begin
        if (!cs_n) begin
            $display("[%0t ps] [BUS] SCLK Rising Edge  | MOSI = %b | Master shifts next bit", $time, mosi);
            if (slave_bit_cnt > 0) begin
                slave_bit_cnt <= slave_bit_cnt - 1;
                miso          <= slave_tx_data[slave_bit_cnt - 1];
                $display("[%0t ps] [SLAVE] Shifted next MISO bit[%0d] = %b", $time, slave_bit_cnt - 1, slave_tx_data[slave_bit_cnt - 1]);
            end
        end
    end

    // Master samples MISO in / Slave samples MOSI in on SCLK Falling Edge
    always @(negedge sclk) begin
        if (!cs_n) begin
            slave_rx_data[slave_bit_cnt] <= mosi;
            $display("[%0t ps] [BUS] SCLK Falling Edge | MISO = %b | Slave captured MOSI = %b (Bit %0d)", $time, miso, mosi, slave_bit_cnt);
        end
    end

    // 3. Test Sequence
    initial begin
        // Initialize Inputs
        clk     = 0;
        rst_n   = 0;
        start   = 0;
        tx_data = 8'h00;
        miso    = 1'b0;

        // Apply Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("\n=======================================================");
        $display("   TEST 1: Master TX = 0x3A | Slave TX = 0xA5");
        $display("=======================================================");
        
        tx_data       = 8'h3A;
        slave_tx_data = 8'hA5;

        // Start Transmission Pulse
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // Wait for Completion
        wait(done == 1'b1);
        @(posedge clk);

        $display("\n--- TEST 1 RESULTS ---");
        if (rx_data === slave_tx_data)
            $display("[%0t ps] SUCCESS: Master Received = 0x%0h (Expected 0x%0h)", $time, rx_data, slave_tx_data);
        else
            $error("[%0t ps] ERROR: Master Received = 0x%0h (Expected 0x%0h)", $time, rx_data, slave_tx_data);

        if (slave_rx_data === tx_data)
            $display("[%0t ps] SUCCESS: Slave Received  = 0x%0h (Expected 0x%0h)", $time, slave_rx_data, tx_data);
        else
            $error("[%0t ps] ERROR: Slave Received  = 0x%0h (Expected 0x%0h)", $time, slave_rx_data, tx_data);

        #(CLK_PERIOD * 20);

        $display("\n=======================================================");
        $display("   TEST 2: Master TX = 0xF0 | Slave TX = 0x0F");
        $display("=======================================================");
        
        tx_data       = 8'hF0;
        slave_tx_data = 8'h0F;

        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        wait(done == 1'b1);
        @(posedge clk);

        $display("\n--- TEST 2 RESULTS ---");
        if (rx_data === slave_tx_data && slave_rx_data === tx_data)
            $display("[%0t ps] SUCCESS: Transaction 2 Flawless!", $time);
        else
            $error("[%0t ps] ERROR: Transaction 2 Failed!", $time);

        #(CLK_PERIOD * 10);
        $display("=== Verification Complete ===");
        $finish;
    end

endmodule