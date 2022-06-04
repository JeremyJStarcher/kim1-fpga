//#######################################################################
//#
//#	Copyright 	Earth People Technology Inc. 2012
//#
//#
//# File Name: eptWireOR.v
//# Author:     R. Jolly
//# Date:       July 5, 2012
//# Revision:   A
//#
//# Development: USB Earth People Technology Active Transfer Library 
//# Description: This file contains verilog code which will allow the 
//#              Earth People Technology Active Transfer Library
//#				 to OR multiple user interface module ouputs to the
//#              library.
//#               
//#              
//#
//#************************************************************************
//#
//# Revision History:	
//#			DATE		VERSION		DETAILS		
//#			07/5/12 	A			Created			RJJ
//#
//#									
//#
//#######################################################################

`default_nettype none
`timescale 1ns / 1ps

module eptWireOR # (parameter N = 1)	(
	output reg  [21:0]     uc_out,
	input  wire [N*22-1:0] uc_out_m
	);

	integer i;
	always @(uc_out_m)
	begin
		uc_out = 0;
		for (i=0; i<N; i=i+1) begin: wireOR
			uc_out = uc_out | uc_out_m[ i*22 +: 22 ];
		end
	end
endmodule
