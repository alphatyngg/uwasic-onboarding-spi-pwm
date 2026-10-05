`default_nettype none

module spi_peripheral (
    input wire clk,
    input wire rst_n,
    input wire sclk,
    input wire copi,
    input wire ncs,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

reg transaction_ready;
reg transaction_processed;

always @(posedge clk or negedge rst_n) begin        // use +ve edge of clk for spi signals, -ve edge for resets
    if (!rst_n) begin
        en_reg_out_7_0 <= 8'h00;            // when reset is 0, set all registers to 0
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0 <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle <= 8'h00;
        transaction_processed <= 1'b0;
    end else begin
        if (transaction_ready && !transaction_processed) begin
            if (spi_shift_reg[15]) begin                                            // checks r/w bit. if write, proceed. reject read
                case (spi_shift_reg[14:8])                                          // basically a nested if-else, routing addresses to regs
                    7'h00:   en_reg_out_7_0  <= spi_shift_reg[7:0];
                    7'h01:   en_reg_out_15_8 <= spi_shift_reg[7:0];
                    7'h02:   en_reg_pwm_7_0  <= spi_shift_reg[7:0];
                    7'h03:   en_reg_pwm_15_8 <= spi_shift_reg[7:0];
                    7'h04:   pwm_duty_cycle  <= spi_shift_reg[7:0];
                    default: ;                                                      // rejects invalid addresses
                endcase
            end

            transaction_processed <= 1'b1;                                          // bits are ready to be processed, flag up

        end else begin
            if (!transaction_ready && transaction_processed) begin
                transaction_processed <= 1'b0;                                      // bits are processed & no longer ready, flag down
            end
        end
    end
end



reg[2:0] sclk_sync;         // metastability regs to avoid metastability 
reg[2:0] copi_sync;
reg[2:0] ncs_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_sync <= 3'b000;                // ensures all sigals are reset to 0
        copi_sync <= 3'b000;
        ncs_sync <= 3'b000;
    end else begin
        sclk_sync <= {sclk_sync[1:0], sclk};        // shift in the new values of the signals on each clock edge, 
        copi_sync <= {copi_sync[1:0], copi};        // 2 (old val lower bits) + 1 (new) = 3 bits to avoid metastability
        ncs_sync <= {ncs_sync[1:0], ncs};
    end

end



// use b2 & b1 to compare, since b0 might be unstable
wire sclk_rising = (sclk_sync[1] == 1'b1) && (sclk_sync[2] == 1'b0);        // detect rising edge of sclk
wire ncs_rising = (ncs_sync[1] == 1'b1) && (ncs_sync[2] == 1'b0);           // detect rising edge of ncs

wire ncs_falling = (ncs_sync[1] == 1'b0) && (ncs_sync[2] == 1'b1);          // detect falling edge of ncs




reg[15:0] spi_shift_reg;        // shift register to hold the incoming data from spi, 16 bits
reg[4:0] bit_count;             // count the number of bits received, 5 bits to count up to 16 (0-15)


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_shift_reg <= 16'h0000;        // reset shift register to 0
        bit_count <= 5'b00000;            // reset bit count to 0
        transaction_ready <= 1'b0;
    end else begin
        if (ncs_falling) begin
            bit_count <= 5'b00000;        // reset count to 0 on ncs falling edge, indicates start of new transaction
        end else begin
            if (ncs_sync[1] == 1'b0 && sclk_rising) begin                    // if ncs is low and sclk rising edge,
                spi_shift_reg <= {spi_shift_reg[14:0], copi_sync[1]};        // shift in the new bit from copi on sclk rising edge
                bit_count <= bit_count + 1;                                  // increment the bit count
            end else begin
                if (ncs_rising && bit_count == 5'd16) begin
                    transaction_ready <= 1'b1;                               // full 16 bits data recieved, flag ready
                end else begin
                    if (transaction_processed) begin
                        transaction_ready <= 1'b0;                           // task finished, flag down
                    end
                end     
            end     
        end
    end
end



endmodule