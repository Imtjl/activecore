/*
 * tb.v
 *
 *  Created on: 17.10.2019
 *      Author: Alexander Antonov <antonov.alex.alex@gmail.com>
 *     License: See LICENSE file for details
 */


`timescale 1ns / 1ps

`define HALF_PERIOD			5						//external 100 MHZ
`define DIVIDER_115200		32'd8680
`define DIVIDER_19200		32'd52083
`define DIVIDER_9600		32'd104166
`define DIVIDER_4800		32'd208333
`define DIVIDER_2400		32'd416666


module tb ();
//
logic CLK_100MHZ, RST, rx;
logic [15:0] SW;
logic [15:0] LED;

always #`HALF_PERIOD CLK_100MHZ = ~CLK_100MHZ;

always #1000 SW = SW + 8'h1;
	
NEXYS4_DDR
#(
	.SIM("YES")
) DUT (
	.CLK100MHZ(CLK_100MHZ)
    , .CPU_RESETN(!RST)
    
    , .SW(SW)
    , .LED(LED)

    , .UART_TXD_IN(rx)
    , .UART_RXD_OUT()
);

////reset all////
task RESET_ALL ();
    begin
    CLK_100MHZ = 1'b0;
    RST = 1'b1;
    rx = 1'b1;
    #(`HALF_PERIOD/2);
    RST = 1;
    #(`HALF_PERIOD*6);
    RST = 0;
    while (DUT.srst) WAIT(10);
    end
endtask

////wait////
task WAIT
    (
     input logic [15:0] periods
     );
    begin
    integer i;
    for (i=0; i<periods; i=i+1)
        begin
        #(`HALF_PERIOD*2);
        end
    end
endtask

`define UDM_RX_SIGNAL rx
`define UDM_BLOCK DUT.udm
`include "udm.svh"
udm_driver udm = new();

/////////////////////////
// main test procedure //
localparam CSR_LED_ADDR         = 32'h00000000;
localparam CSR_SW_ADDR          = 32'h00000004;
localparam TESTMEM_ADDR         = 32'h80000000;
localparam CSR_SQRT_X_ADDR      = 32'h10000000;
localparam CSR_SQRT_Y_ADDR      = 32'h20000000;

int sqrt_checks = 0;
int sqrt_errors = 0;

task automatic check_sqrt (input logic [31:0] x, input logic [31:0] y_exp);
    logic [31:0] y;
    udm.wr32(CSR_SQRT_X_ADDR, x);
    udm.rd32(CSR_SQRT_Y_ADDR);
    y = `UDM_BLOCK.bus_rdata_bi;
    sqrt_checks++;
    if (y !== y_exp) begin
        sqrt_errors++;
        $display("SQRT ERROR: x: 0x%8x, y: 0x%8x, expected: 0x%8x", x, y, y_exp);
    end
endtask

initial
    begin
    logic [31:0] wrdata [];
    integer ARRSIZE=10;
    
	$display ("### SIMULATION STARTED ###");
	
	SW = 8'h30;
	RESET_ALL();
	WAIT(100);

	udm.cfg(`DIVIDER_115200, 2'b00);
	udm.check();
	udm.hreset();
	WAIT(100);
	
	// memory initialization
	udm.wr32(32'h80000000, 32'h112233cc);
	udm.wr32(32'h80000004, 32'h55aa55aa);
	udm.wr32(32'h80000008, 32'h01010202);
	udm.wr32(32'h8000000C, 32'h44556677);
	udm.wr32(32'h80000010, 32'h00000003);
	udm.wr32(32'h80000014, 32'h00000004);
	udm.wr32(32'h80000018, 32'h00000005);
	udm.wr32(32'h8000001C, 32'h00000006);
	udm.wr32(32'h80000020, 32'h00000007);
	udm.wr32(32'h80000024, 32'hdeadbeef);
	udm.wr32(32'h80000028, 32'hfefe8800);
	udm.wr32(32'h8000002C, 32'h23344556);
	udm.wr32(32'h80000030, 32'h05050505);
	udm.wr32(32'h80000034, 32'h07070707);
	udm.wr32(32'h80000038, 32'h99999999);
	udm.wr32(32'h8000003C, 32'hbadc0ffe);
	
	WAIT(100);
	
	// writing to LED
	udm.wr32(32'h00000000, 32'h5a5a5a5a);
	
	// reading SW
	udm.rd32(32'h00000004);
	
	// sqrt_comb test, vectors from designs/rtl/sqrt/sqrt_vectors.py
	check_sqrt(32'h00000000, 32'h00000000);
	check_sqrt(32'h00000001, 32'h00000001);
	check_sqrt(32'h00000002, 32'h00000001);
	check_sqrt(32'h00000003, 32'h00000001);
	check_sqrt(32'h00000004, 32'h00000002);
	check_sqrt(32'h0000000f, 32'h00000003);
	check_sqrt(32'h00000010, 32'h00000004);
	check_sqrt(32'h00000011, 32'h00000004);
	check_sqrt(32'h00000063, 32'h00000009);
	check_sqrt(32'h00000064, 32'h0000000a);
	check_sqrt(32'h000000ff, 32'h0000000f);
	check_sqrt(32'h00000100, 32'h00000010);
	check_sqrt(32'h0000ffff, 32'h000000ff);
	check_sqrt(32'h00010000, 32'h00000100);
	check_sqrt(32'h7fffffff, 32'h0000b504);
	check_sqrt(32'h80000000, 32'h0000b504);
	check_sqrt(32'hfffe0000, 32'h0000fffe);
	check_sqrt(32'hfffe0001, 32'h0000ffff);
	check_sqrt(32'hffffffff, 32'h0000ffff);
	check_sqrt(32'hcb1855fe, 32'h0000e404);
	check_sqrt(32'h92e5dfe8, 32'h0000c1ec);
	check_sqrt(32'hd26b9496, 32'h0000e818);
	check_sqrt(32'h14a03569, 32'h000048aa);
	check_sqrt(32'h7c2b3abe, 32'h0000b24a);
	check_sqrt(32'hc320a473, 32'h0000df80);
	check_sqrt(32'h42f9a039, 32'h000082f0);
	check_sqrt(32'h096d3737, 32'h0000311f);
	check_sqrt(32'h001d9a88, 32'h00000570);
	check_sqrt(32'h254499c7, 32'h000061ad);
	check_sqrt(32'ha9ae7a34, 32'h0000d06b);
	check_sqrt(32'h9623d7cf, 32'h0000c40c);
	check_sqrt(32'h78629522, 32'h0000af8d);
	check_sqrt(32'hf72c2c26, 32'h0000fb8c);
	check_sqrt(32'hc27db4ec, 32'h0000df22);
	check_sqrt(32'hbc1e3ac1, 32'h0000db73);
	$display ("### SQRT: %0d checks, %0d errors ###", sqrt_checks, sqrt_errors);

	WAIT(1000);

	$display ("### TEST PROCEDURE FINISHED ###");
	$stop;
    end


endmodule
