module uartrx #(parameter clk_freq = 1000000, parameter baud_rate = 9600)(
    input clk,
    input rst,
    input rx,
    output reg done,
    output reg [7:0] rxdata
    );
    
    // clk_freq : frequency of the transmitter 
    // baud_rate : data transmission rate
    localparam clkcount = (clk_freq/baud_rate);
  
    // count  : For keeping track of the slower clock - baud rate    
    integer count = 0;
    // counts : Keeps track of how many bits were received - here it is 8
    integer counts = 0;
    
    // Clock for bit duration : For how long the bit to be transfered is kept constant
    reg uclk = 0;
    
    // States in a the receiver
    // idle  : No data receive
    // start : Monitor data transfer
    enum bit {idle = 1'b0, start = 1'b1} state;
 
    // uart_clock_gen : Clock that represents baud rate
    always@(posedge clk) begin
        if(count < clkcount/2)
            count <= count + 1;
        else begin
            count <= 0;
            uclk <= ~uclk;
        end 
    end
    
    // The receiver state changes as per the baud rate (the slower clock)
    always@(posedge uclk) begin
        if(rst) begin
            rxdata <= 8'h00;
            counts <= 0;
            done   <= 1'b0;
        end
        else begin
            case(state)
                idle : 
                    begin
                        // Initialize signals to zero
                        rxdata <= 8'h00;
                        counts <= 0;
                        done <= 1'b0;
                        
                        // If the receiver detects a zero on the Rx line
                        if(rx == 1'b0)
                            state <= start;
                        else
                            state <= idle;
                        end
     
                start: 
                    begin
                        // If data transfer in process
                        if(counts <= 7) begin
                            counts <= counts + 1;
                            rxdata <= {rx, rxdata[7:1]};
                        end
                        // Reset the counter and indicate done
                        else begin
                            counts <= 0;
                            done <= 1'b1;
                            state <= idle;
                        end
                    end

                default : state <= idle;
            endcase
        end
    end
endmodule