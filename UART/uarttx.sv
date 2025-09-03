module uarttx #(parameter clk_freq = 1000000, parameter baud_rate = 9600)(
    input clk,rst,
    input newd,
    input [7:0] tx_data,
    output reg tx,
    output reg donetx
    );
    
    // clk_freq : frequency of the transmitter 
    // baud_rate : data transmission rate
    localparam clkcount = (clk_freq/baud_rate); ///x
    
    // count  : For keeping track of the slower clock - baud rate
    integer count = 0;
    // counts : Keeps track of how many bits to be sent - here it is 8
    integer counts = 0;
    
    // Clock for bit duration : For how long the bit to be transfered is kept constant
    reg uclk = 0;
    
    // States in a the transmitter
    // idle     : No data transmission
    // transfer : Actual data transfer
    enum bit {idle = 1'b0, transfer = 1'b1} state;
 
    // uart_clock_gen : Clock that represents baud rate
    always@(posedge clk) begin
        if(count < clkcount/2)
            count <= count + 1;
        else begin
            count <= 0;
            uclk <= ~uclk;
        end 
    end
    
    // Temporary variable
    reg [7:0] din;

    // The transmitter state changes as per the baud rate (the slower clock)
    always@(posedge uclk) begin
        if(rst) begin
            state <= idle;
        end
        else begin
            case(state)
                idle:
                    begin
                        counts <= 0;
                        tx <= 1'b1;
                        donetx <= 1'b0;
                        
                        if(newd) begin
                            state <= transfer;
                            din <= tx_data;
                            tx <= 1'b0; 
                        end
                        else
                            state <= idle;       
                    end
       
                transfer: 
                    begin
                        if(counts <= 7) begin
                            counts <= counts + 1;
                            tx <= din[counts];
                            state <= transfer;
                        end
                        else begin
                            counts <= 0;
                            tx <= 1'b1;
                            state <= idle;
                            donetx <= 1'b1;
                        end
                    end
                
                default : state <= idle;
            endcase
        end
    end
 
endmodule
 
