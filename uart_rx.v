`timescale 1ns/1ps

module uart_rx 
#( parameter BAUD_RATE = 9600) // Use this value to check functionality on actual baud rate, also needed for FPGA testing
//#( parameter BAUD_RATE = 10000000) // Use this value to check post-synthesis waveform on EDA playground
(
    input clk,
    input nrst,
    input rx,
    output reg [7:0] data_out,
    output reg valid
);

reg prev_rx;

reg [13:0] baud_ctr;
reg baud_ctr_en;
reg state;
reg [3:0] bit_ctr;
reg [7:0] r;
reg baud_run;
localparam CLOCK_FREQUENCY = 100000000;
localparam BAUD_CYCLE = CLOCK_FREQUENCY/BAUD_RATE;

// frequency divider for the baud rate
always@(posedge clk  or negedge nrst) begin
    if (!nrst) begin
        baud_ctr <= 'd0;
        baud_ctr_en <= 0;
    end else begin
        if (baud_run) begin
            if (baud_ctr < BAUD_CYCLE) begin
                baud_ctr    <= baud_ctr + 1;
                baud_ctr_en <= 0;
            end else begin
                baud_ctr    <= 0;
                baud_ctr_en <= 1'b1;
            end
        end
        else begin
            baud_ctr <= 0;
            baud_ctr_en <= 1'b0;
        end
        
    end
end

always@(posedge clk or negedge nrst) begin
    if (!nrst) begin
        data_out <= 8'd0;
        valid <= 0;
        state <= 1'd0;
        bit_ctr <= 0;
        r <= 0;
        baud_run <= 0;
    end else begin
        case (state)
            1'd0: begin
                if (prev_rx == 1 && rx == 0) begin
                    baud_run <= 1;
                    state <= 1;
                    //data_out <= 0;
                end
                else begin
                    valid <= 0;
                    prev_rx <= rx;
                end
            end
            1'd1: begin
                if (( baud_ctr == (BAUD_CYCLE/2) && (bit_ctr > 0) )) begin
                    data_out[bit_ctr-1] <= rx;
                end
                else if (baud_ctr_en) begin
                    if (bit_ctr == 8) begin
                        state <= 0;
                        valid <= 1;
                        baud_run <= 0;
                        bit_ctr <= 0;
                    end
                    else begin
                        bit_ctr = bit_ctr + 1;
                    end
                end
                else begin
                    valid <= 0;
                end
            end
        endcase
    end
end

endmodule
