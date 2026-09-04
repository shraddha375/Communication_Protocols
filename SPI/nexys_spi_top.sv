module nexys_spi_top (
    input  logic       clk,         // 100 MHz board clock
    input  logic       btnCpuReset, // Active-low CPU RESET button
    input  logic       btnC,        // Center button for 'start'
    input  logic [7:0] sw,          // 8 switches for TX data
    
    output logic [7:0] led,         // 8 LEDs for RX data
    output logic       led16_b,     // Blue RGB LED for 'done' status
    
    // SPI pins on Pmod JA
    output logic       ja_cs,       // JA[1]
    output logic       ja_mosi,     // JA[2]
    input  logic       ja_miso,     // JA[3]
    output logic       ja_sclk      // JA[4]
);

    // 1. Synchronize external asynchronous button input (2-stage FF)
    logic btnC_sync_0, btnC_sync_1;
    always_ff @(posedge clk or negedge btnCpuReset) begin
        if (~btnCpuReset) begin
            btnC_sync_0 <= 1'b0;
            btnC_sync_1 <= 1'b0;
        end else begin
            btnC_sync_0 <= btnC;
            btnC_sync_1 <= btnC_sync_0;
        end
    end

    // 2. Debounce & Pulse Generation (Ignores button bounce for ~10ms)
    logic start_pulse;
    logic [19:0] db_counter;
    logic btn_state;

    always_ff @(posedge clk or negedge btnCpuReset) begin
        if (~btnCpuReset) begin
            db_counter  <= '0;
            btn_state   <= 1'b0;
            start_pulse <= 1'b0;
        end else begin
            start_pulse <= 1'b0; // Default low
            if (btnC_sync_1 != btn_state) begin
                db_counter <= db_counter + 1'b1;
                if (db_counter == 20'hFFFFF) begin // ~10.4ms delay at 100MHz
                    btn_state   <= btnC_sync_1;
                    db_counter  <= '0;
                    if (btnC_sync_1) begin
                        start_pulse <= 1'b1; // Generate clean single pulse on press
                    end
                end
            end else begin
                db_counter <= '0;
            end
        end
    end

    // 3. Instantiate SPI Master
    logic spi_done;
    logic done_led;

    spi_master #(
        .DATA_WIDTH(8),
        .CLK_DIV(100)
    ) spi_inst (
        .clk(clk),
        .rst_n(btnCpuReset),
        .start(start_pulse),
        .tx_data(sw),
        .sclk(ja_sclk),
        .mosi(ja_mosi),
        .miso(ja_miso),
        .cs_n(ja_cs),
        .rx_data(led),
        .done(spi_done)
    );

    always_ff @(posedge clk or negedge btnCpuReset) begin
        if (!btnCpuReset) begin
            done_led <= 1'b0;
        end
        else if (start_pulse) begin
            done_led <= 1'b0;
        end
        else if (spi_done) begin
            done_led <= 1'b1;
        end
    end

    assign led16_b = done_led;

endmodule