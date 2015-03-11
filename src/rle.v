/*
 * This file is part of the DSLogic-hdl project.
 * It implements Run Length Encoding to optimize the memory usage 
 * of the DSLogic instrument 
 *
 * Dimitar Penev 
 * Copyright (C) 2014 Switchfin Org. <dpn@switchfin.org>
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

	// -- data
	input   [15:0]  capture_data,
	output  [15:0]  rle_data,
	output          rle_valid
);

// --
// internal registers definition
// --
reg     [14:0] old;     //Old sample
reg     [14:0] cnt;     //counter of the equal samples in series

always @(posedge core_clk or posedge core_rst)
begin
	if (core_rst)
		old <= 14'b0;
	else
		old <= capture_data[14:0];
end

always @(posedge core_clk or posedge core_rst)
begin
	if (core_rst)
	begin
		cnt <= 14'b0;
		rle_valid <=0;
	end
	else if (old == capture_data[14:0])
	begin 
		if (cnt == 14'b0)       // -- write first sample of the series
		begin
			rle_data <= {1'b0, capture_data[14:0]};
			rle_valid <=0;
		end
		else if (cnt == 14'b1)  // -- counter overflow
		begin
			cnt <= 14'b0;   // -- reset counter
			rle_data <= 15'b1;                     
			rle_valid <=0;
		end
		else
			rle_valid <=0;
		cnt <= cnt + 1;
	end
	else                            // -- end of series 
	begin
		if (cnt != 14'b0)
			rle_data <= {1'b1, cnt};
		else
			rle_data <= {1'b0, old};
		cnt <= 14'b0;
		rle_valid <=0;
	end
end
