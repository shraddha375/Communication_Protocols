module spi_master #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV    = 10
)(
    input                           clk,
    input                           rst_n,
    input                           start,
    input        [DATA_WIDTH - 1:0] tx_data,

    output logic                    sclk,
    output logic                    mosi,
    input                           miso,
    output logic                    cs_n,
    output logic [DATA_WIDTH - 1:0] rx_data,
    output logic                    done
);
    // States for FSM and Sate Registers
    localparam IDLE = 2'b00, TRANSFER = 2'b01, DONE = 2'b10;
    logic [1:0] current_state, next_state;

    // Internal clock and counter
    logic [3:0] scounter;
    logic       sclk_tick;

    // Internal registers
    logic [DATA_WIDTH - 1:0] shift_reg;
    logic [$clog2(DATA_WIDTH) - 1:0] bit_cnt;

    // Internal driven outputs
    logic [DATA_WIDTH-1:0] rx_data_reg;    

    assign rx_data = rx_data_reg;

    // Clock Divider counter
    always_ff @(posedge clk or negedge rst_n) begin : CLK_DIVISON
        if (~rst_n) begin
            scounter  <=  'b0;
            sclk      <= 1'b1;
            sclk_tick <= 1'b0;
        end
        else begin
            if (cs_n) begin
                scounter  <=  'b0;
                sclk      <= 1'b1;
                sclk_tick <= 1'b0;
            end
            else begin
                if (scounter == ((CLK_DIV / 2) - 1)) begin
                    scounter  <=  'b0;
                    sclk      <= ~sclk;
                    sclk_tick <= 1'b1;
                end
                else begin
                    scounter  <= scounter + 1;
                    sclk      <= sclk;
                    sclk_tick <= 1'b0;
                end
            end
        end
    end

    // State Transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // Next State Logic
    always @(*) begin
        case(current_state) 
            IDLE     : begin
                if (start)
                    next_state = TRANSFER;
                else
                    next_state = IDLE;
            end

            TRANSFER : begin
                if (sclk_tick && (sclk == 1'b0) && (bit_cnt == 0)) 
                    next_state = DONE;
                else 
                    next_state = TRANSFER;
            end

            DONE     : next_state = IDLE;

            default  : next_state = IDLE;
        endcase
    end

    // Output Logic
    always @(*) begin
        case(current_state) 
            IDLE     : begin
                cs_n = 1'b1;
                done = 1'b0;
            end

            TRANSFER : begin
                cs_n = 1'b0;
                done = 1'b0;
                
            end

            DONE     : begin
                cs_n = 1'b1;
                done = 1'b1;
                
            end

            default  : begin
                cs_n = 1'b1;
                done = 1'b0;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            bit_cnt     <= '0;
            shift_reg   <= '0;
            rx_data_reg <= '0;
            mosi        <= 1'b0;
        end
        else begin
            case (current_state)
                IDLE     : begin
                    if (start) begin
                        shift_reg <= tx_data;
                        bit_cnt   <= DATA_WIDTH - 1;
                        mosi      <= tx_data[DATA_WIDTH - 1];
                    end
                end

                TRANSFER : begin
                    if (sclk_tick) begin
                        if (sclk == 1'b1) begin
                            // Rising edge of sclk : Master shifts MOSI out
                            mosi <= shift_reg[bit_cnt]; // MSB first
                        end 
                        else begin
                            // Falling edge of sclk : Master samples MISO in
                            rx_data_reg[bit_cnt] <= miso; 
                            if (bit_cnt != 0) begin
                                bit_cnt <= bit_cnt - 1'b1;
                            end
                        end
                    end
                end

                DONE     : begin
                    // No change
                end
            endcase
        end
    end

endmodule