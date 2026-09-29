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

always @(posedge clk or negedge rst_n) begin        // use +ve edge of clk for spi signals, -ve edge for resets
    if (!rst_n) begin
        en_reg_out_7_0 <= 8'h00;            // when reset is 0, set all registers to 0
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0 <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle <= 8'h00;
    end else begin
        // spi logic to read data from the spi bus and update the regs, placeholder
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


endmodule