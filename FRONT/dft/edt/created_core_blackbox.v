//--------------------------------------------------------------------------------
//
//  Unpublished work. Copyright 2022 Siemens
//
//  This material contains trade secrets or otherwise confidential 
//  information owned by Siemens Industry Software Inc. or its affiliates 
//  (collectively, SISW), or its licensors. Access to and use of this 
//  information is strictly limited as set forth in the Customer's 
//  applicable agreements with SISW.
//
//--------------------------------------------------------------------------------
//  File created by: Tessent Shell
//          Version: 2022.4
//       Created on: Fri Sep 18 11:53:46 IST 2026
//
//       IP version: 8
//--------------------------------------------------------------------------------


module sync_fifo (
   input  wire       clk_i,
   input  wire       rst_i,
   input  wire       wr_en_i,
   input  wire       rd_en_i,
   input  wire [7:0] wr_data_i,
   output wire [7:0] rd_data_o,
   output wire       full_o,
   output wire       empty_o,
   output wire       error_o,
   input  wire [2:0] ts_si,
   output wire [2:0] ts_so,
   input  wire       scan_en
);
endmodule


