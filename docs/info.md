<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

SPI controlled PWM peripheral. An external SPI controller writes to configure registers over SCLK, COPI, nCS. 
Each write is 16 bits: a r/w bit, a 7 bit address, and 8 bits of data. No reads. 

| Address | Register        | Description                    |
|---------|-----------------|--------------------------------|
| 0x00    | en_reg_out_7_0  | Output enable for uo_out[7:0]  |
| 0x01    | en_reg_out_15_8 | Output enable for uio_out[7:0] |
| 0x02    | en_reg_pwm_7_0  | PWM enable for uo_out[7:0]     |
| 0x03    | en_reg_pwm_15_8 | PWM enable for uio_out[7:0]    |
| 0x04    | pwm_duty_cycle  | PWM duty cycle (0-255)         |

## How to test

Drive SCLK on ui_in[0], COPI on ui_in[1], and nCS on ui_in[2]. 
Send a 16-bit write with nCS low and the data clocked out MSB first. 
Run `make` in the test directory to run the cocotb testbench.

## External hardware

None.