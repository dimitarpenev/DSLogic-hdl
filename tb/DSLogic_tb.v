/*
 * DSLogic-hdl test bench
 *
 * Author: Dimitar Penev
 * Copyright (C) 2015 Switchfin <dpn@switchfin.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 */
`timescale 1ns/100ps

`include "mt48lc16m16a2.v"

module DSlogic_tb; 

	reg sys_clk;
        reg cclk;            
        inout wire ext_clk;
        wire sd_clk_out;
        wire sd_clk_fb;
        reg sys_rst;     
        reg sys_clr;
        reg sys_en;
        
	wire ledn;
        
	inout wire ext_trig;
        wire ext_out;
        reg [15:0] ext_data;
        
	reg scl;
        inout wire sda;

        reg usb_en;
        reg usb_rdwr;
        wire usb_rdy;
        wire usb_overflow;
        reg  [15:0] usb_data_reg;
	wire [15:0] usb_data;
        
	wire [12:0] Addr;
        wire [1:0] Ba;
        inout wire [15:0] Dq;
        wire Ras_n;
        wire Cas_n;
        wire We_n;
        wire [1:0 ] Dqm;
        wire Cs_n;


	DSLogic #(.MODE("SIM")) DSlogic(
        	// -- clock & reset
        	.sys_clk(sys_clk),	//*input 48Mhz
        	.cclk(cclk),		//*input 30MHz
        	.ext_clk(ext_clk),	//inout, This is CK on the DSLogic connector
        	.sd_clk_out(sd_clk_out),//*output 120 MHz from PLL for the RAM clock
       		.sd_clk_fb(sd_clk_fb), 	//*input, get 120MHz from sd_clk_out external wire  
        	.sys_rst(sys_rst),	//*input, this is master #RESET
        	.sys_clr(sys_clr),	//*input, kind of wake up signal, best is to tick with sys_clk so no clear condition? 
        	.sys_en(sys_en),	//input Slave FIFO output enable set by the CPU, used to read memory from the CPU

        	// control
        	.ledn(ledn), //output

        	// -- external signal 
        	.ext_trig(ext_trig), 	//inout, TI on the DSlogic connector 	
        	.ext_out(ext_out),  	//output,TO on the DSLogic connector
        	.ext_data(ext_data), 	//*[14:0] input

        	// -- i2c
        	.scl(scl), //input, CPU can store up to 256 registers in the FPGA as if EEPROM connected. 
        	.sda(sda), //inout

        	// -- Slave FIFO interface
        	.usb_en(usb_en), 		//input
        	.usb_rdwr(usb_rdwr), 		//input
        	.usb_rdy(usb_rdy), 		//output
        	.usb_overflow(usb_overflow), 	//output
        	.usb_data(usb_data), 		//[15:0] inout

        	// -- SDRAM interface
        	.sd_addr(Addr), 	//[12:0]  output 
        	.sd_ba(Ba), 		//[1:0]  output
        	.sd_dq(Dq), 		//[15:0] inout 
        	.sd_ras_(Ras_n), 	//output 
        	.sd_cas_(Cas_n), 	//output 
        	.sd_we_(We_n), 	//output 
        	.sd_dqml(Dqm[0]), 	//output 
        	.sd_dqmh(Dqm[1]), 	//output 
        	//output sd_cke,
        	.sd_cs_(Cs_n) 		//output 
	);	

	
       	mt48lc16m16a2 mt48lc16m16a2(
		.Dq(Dq), 
		.Addr(Addr), 
		.Ba(Ba), 
		.Clk(Clk), 
		.Cke(Cke), 
		.Cs_n(Cs_n), 
		.Ras_n(Ras_n), 
		.Cas_n(Cas_n), 
		.We_n(We_n), 
		.Dqm(Dqm)
	);
	


	assign sd_clk_fb = sd_clk_out; 	//Wire externaly for the FPGA
//	assign sys_clr	= sys_clk; 	//We tick this input regularly so we keep FPGA awake 	
	assign usb_data = usb_data_reg; //We have wire and reg for the inouts 

	initial begin
	        sys_clk <= 0;
        	cclk <= 0;
		sys_rst <= 0;
		sys_en <= 0;
		sys_clr<= 1; 		//high for inactive
		//ext_trig <= 0;
		ext_data <= 16'h0000;
		usb_en <= 1;
		usb_rdwr <= 1;
		usb_data_reg <= 16'h0000;

		#1000  sys_rst <= 1'b1;	//Release the #RESET
		#100  sys_en  <= 1'b1;  //It seems this starts the sampling system 
	end 

 
	always  begin 
		#10  sys_clk <= ~sys_clk;//50MHz instead of 48MHz
	end

        always  begin
                #16  cclk <= ~cclk; 	//31.25MHz instead of 30MHz
        end

	initial begin			//Port data

		#133000	ext_data <= 16'h0001;
		 #17000 ext_data <= 16'h0000;

	end
	
	initial  begin
		$dumpfile ("DSLogic.lxt2"); 
		$dumpvars; 
	end 
/*
	initial  begin
		$display("\t\ttime,\tclk,\treset,\tenable,\tcount"); 
		$monitor("%d,\t%b,\t%b,\t%b,\t%d",$time, clk,reset,enable,count); 
	end 
*/
	initial 
		#200000  $finish; 
 	
	//Rest of testbench code after this line 
endmodule
