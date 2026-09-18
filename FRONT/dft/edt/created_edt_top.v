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


module sync_fifo_edt_top (
   input  wire       clk_i,
   input  wire       rst_i,
   input  wire       wr_en_i,
   input  wire       rd_en_i,
   input  wire [7:0] wr_data_i,
   output wire [7:0] rd_data_o,
   output wire       full_o,
   output wire       empty_o,
   output wire       error_o,
   input  wire       scan_en,
   input  wire       edt_clock,
   input  wire       edt_update,
   input  wire       edt_bypass,
   input  wire       edt_channels_in1,
   input  wire       edt_channels_in2,
   input  wire       edt_channels_in3,
   output wire       edt_channels_out1,
   output wire       edt_channels_out2,
   output wire       edt_channels_out3
);


   wire   [2:0] edt_scan_in;
   wire   [2:0] edt_scan_out;


   sync_fifo sync_fifo_i (.clk_i(clk_i),
                          .rst_i(rst_i),
                          .wr_en_i(wr_en_i),
                          .rd_en_i(rd_en_i),
                          .wr_data_i(wr_data_i),
                          .rd_data_o(rd_data_o),
                          .full_o(full_o),
                          .empty_o(empty_o),
                          .error_o(error_o),
                          .ts_si(edt_scan_in),
                          .ts_so(edt_scan_out),
                          .scan_en(scan_en));

   sync_fifo_edt sync_fifo_edt_i (.edt_clock(edt_clock),
                                  .edt_update(edt_update),
                                  .edt_bypass(edt_bypass),
                                  .edt_channels_in({edt_channels_in3, edt_channels_in2, edt_channels_in1}),
                                  .edt_channels_out({edt_channels_out3, edt_channels_out2, edt_channels_out1}),
                                  .edt_scan_in(edt_scan_in),
                                  .edt_scan_out(edt_scan_out));

endmodule


