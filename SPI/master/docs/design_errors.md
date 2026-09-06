# Design Errors

    module spi_master #(
        parameter DATA_WIDTH = 8,
        parameter CLK_DIV    = 10
    )(
        input                    clk,
        input                    rst,
        input                    start,
        input [DATA_WIDTH - 1:0] tx_data,
    
        output logic                    sclk,
        output logic                    mosi,
        input                           miso,
        output logic                    cs_n,
        output logic [DATA_WIDTH - 1:0] rx_data,
        output logic                    done
    );
        // States for FSM
        localparam IDLE = 2'b00, TRANSFER = 2'b01, DONE = 2'b10;
    
        // Internal clock and counter
        logic       sclk;
        logic [3:0] scounter;
    
        // State and internal registers
        logic [1:0] current_state, next_state;
        logic [DATA_WIDTH - 1:0] shift_reg;
        logic [$clog2(DATA_WIDTH) - 1:0] bit_cnt;
        logic op_en;
    
        assign op_en = start | (~cs_n_reg);
    
        // Internal driven outputs
        logic cs_n_reg;
        logic done_reg;
        logic [DATA_WIDTH-1:0] rx_data_reg;    
    
        assign cs_n    = cs_n_reg;
        assign done    = done_reg;
        assign rx_data = rx_data_reg;
    
        // Clock Divider counter
        always_ff @(posedge clk or posedge rst) begin : CLK_DIVISON
            if (rst) begin
                scounter <=  'b0;
                sclk     <= 1'b1;
            end
            else begin
                if (~op_en) begin
                    scounter <=  'b0;
                    sclk     <= 1'b1;
                end
                else begin
                    if (scounter == ((CLK_DIV / 2) - 1)) begin
                        scounter <=  'b0;
                        sclk     <= ~sclk;
                    end
                    else begin
                        scounter <= scounter + 1;
                        sclk     <= sclk;
                    end
                end
            end
        end
    
        // State Transition
        always_ff @(posedge sclk or posedge rst) begin
            if (rst) begin
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
                    if (bit_cnt == (DATA_WIDTH - 1)) 
                        next_state = DONE;
                    else 
                        next_state = TRANSFER;
                end
    
                DONE     : next_state = IDLE;
    
                default  : next_state = IDLE;
            endcase
        end
    
        always @(*) begin
            case(current_state) 
                IDLE     : begin
                    cs_n_reg    = 1'b1;
                    done_reg    = 1'b0;
                    mosi        = 1'bx;
                    shift_reg   = tx_data;
                    rx_data_reg =  'b0;
                end
    
                TRANSFER : begin
                    cs_n_reg             = 1'b0;
                    done_reg             = 1'b0;
                    mosi                 = shift_reg[bit_cnt];
                    rx_data_reg[bit_cnt] = miso;
                end
    
                DONE     : begin
                    cs_n_reg = 1'b1;
                    done_reg = 1'b1;
                    mosi     = 1'bx;
                end
    
                default  : begin
                    cs_n_reg  = 1'b1;
                    done_reg  = 1'b0;
                    mosi      = 1'bx;
                    shift_reg =  'b0;
                    rx_data_reg =  'b0;
                end
            endcase
        end
    
        always_ff @(posedge sclk or posedge rst) begin
            if (rst) begin
                bit_cnt <= 'b0;
            end
            else begin
                if (~cs_n_reg) begin
                    bit_cnt <= bit_cnt + 1;
                end
                else
                    bit_cnt <= 'b0;
            end
        end
    
    endmodule

1. Circular Deadlock (The FSM Never Wakes Up)

Your state transition relies on always_ff @(posedge sclk):

Code snippet

    always_ff @(posedge sclk or posedge rst) begin
        current_state <= next_state;
    end

While in IDLE, cs_n_reg is 1'b1.

If start goes low after a single pulse, op_en drops to 0, which forces sclk to stay statically high (1'b1).

Because sclk never toggles, there is no rising clock edge (posedge sclk) to trigger the state transition from IDLE to TRANSFER.

The clock generation relies on cs_n_reg, but cs_n_reg cannot update until the state changes—creating a circular lockup where the module waits forever.

2. Inferred Latches in Output Logic (always @(*))

You drive sequential registers (shift_reg and rx_data_reg) inside a combinational always @(*) block:

Code snippet

    always @(*) begin
        case(current_state)
            TRANSFER : begin
                rx_data_reg[bit_cnt] = miso; // Modifies only 1 bit at a time
            end
        ...

Combinational logic must define all bits for every possible path.

Updating only rx_data_reg[bit_cnt] means the synthesizer must remember the remaining unassigned bits, causing it to infer hardware latches.

Latches create timing glitches, race conditions, and static timing failure on ASICs and FPGAs.

3. Race Condition on start Pulse Width

Your clock divider uses op_en = start | (~cs_n_reg).

If start is a 1-cycle pulse on clk, it goes high and turns on scounter.

However, CLK_DIV = 10 means sclk won't see its first posedge until 5 cycles of clk later.

By the time that edge arrives, start has already returned to 0. If cs_n_reg hasn't dropped to 0 yet (because the state machine hasn't transitioned), op_en becomes 0, cutting off sclk before it ever ticks once.
