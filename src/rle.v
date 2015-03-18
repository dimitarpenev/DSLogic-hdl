/*
 * This file is part of the DSLogic-hdl project.
 * It implements Run Length Encoding to optimize the memory usage 
 * of the DSLogic instrument.   
 * Dimitar Penev 
 * Copyright (C) 2014 Switchfin Org. <dpn@switchfin.org>
 *
 *  If RLE is used last bit in data streem notifies sample/count
 *  samples are capturing allbut 16th data bit  
 *  Streem with equal samples is represented by the pair   
 *	 {0 sample} {1 how_much_extra_equal_samples} ...   
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
`define D #1

module rle(
	// -- clock & reset
	input   core_clk,
	input   core_rst,
	
	//trigger hit starts RLE
	input		trig_hit,

	// -- data
	input   [15:0]  capture_data,
	output  [15:0]  rle_data,
	output          rle_valid,
	output  [24:0]  rle_sample_cnt 	
);

// --
// internal registers definition
// --
reg     [14:0] 	old;     //Old sample
reg     [14:0] 	cnt;     //counter of the equal samples in series
reg	[15:0] 	rle_data_reg;
reg		rle_valid_reg;
reg	[24:0] 	rle_sample_cnt_reg; 	

reg		rle_start;

assign rle_data=rle_data_reg;
assign rle_valid=rle_valid_reg;
assign rle_sample_cnt=rle_sample_cnt_reg;
	
//old keeps track of the previous data sample
always @(posedge core_clk or posedge core_rst)
begin
	if (core_rst | ~rle_start)
		old <= 15'b0;
	else
		old <= capture_data[14:0];
end

//Actual RLE encoding
always @(posedge core_clk or posedge core_rst)
begin
	if (core_rst | ~rle_start)
	begin
		cnt <= 15'b0;
		rle_valid_reg <= 0;
		rle_data_reg <= 0;		
	end
	else if (old == capture_data[14:0])
	begin 
		if (cnt == 15'b0)       // -- write first sample of the series
		begin
			rle_data_reg <= {1'b0, capture_data[14:0]};
			rle_valid_reg <= 1; 
		end
		else if (cnt[14:0] == 15'b111111111111111)  // -- counter overflow
		begin
			cnt <= 15'b0;   // -- reset counter
			rle_data_reg <= 16'b1111111111111111;
			rle_valid_reg <= 1;
		end
		else
			rle_valid_reg <= 0;
		cnt <= cnt + 1'b1;
	end
	else                            // -- end of series 
	begin
		if (cnt != 15'b0)
			rle_data_reg <= {1'b1, cnt};
		else
			rle_data_reg <= {1'b0, old};
		cnt <= 15'b0;
		rle_valid_reg <= 1;
	end
end

//Set rle_start when get a trig_hit 
//
//rle_sample_cnt counts the amount of RLE samples we have process
//This is used in capture module to stop the acquisition
always @(posedge core_clk or posedge core_rst)
begin
	if (core_rst)
	begin
		rle_sample_cnt_reg <= 0;
		rle_start <= 0;
	end
	else if (~rle_start & trig_hit)
			rle_start <= 1'b1;	
	else if (rle_start & rle_valid_reg )
	begin
		rle_sample_cnt_reg <= rle_sample_cnt_reg +1;
		if (rle_sample_cnt_reg == 25'Hffff)//25'H1000000) //16 MSamples memory
		begin
			rle_sample_cnt_reg <= 0;
			rle_start <=1'b0;
		end	
	end
end
endmodule
