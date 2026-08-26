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
