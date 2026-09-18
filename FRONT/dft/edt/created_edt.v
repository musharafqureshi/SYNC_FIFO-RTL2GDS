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


module sync_fifo_edt_decompressor (
   input  wire       edt_clock,
   input  wire       edt_update,
   input  wire [2:0] edt_channels_in,
   output reg  [2:0] edt_scan_in
);
   reg    [15:0] lfsm_vec;
   reg    [15:0] lfsm_vec_lockup;

   always @(posedge edt_clock)
   begin : lfsm
      if (edt_update == 1'b1) begin
         lfsm_vec <= 16'b0000000000000000;
      end
      else begin
         lfsm_vec[ 0] <= lfsm_vec[ 1];
         lfsm_vec[ 1] <= lfsm_vec[ 2];
         lfsm_vec[ 2] <= lfsm_vec[ 3] ^ edt_channels_in[1];
         lfsm_vec[ 3] <= lfsm_vec[ 4];
         lfsm_vec[ 4] <= lfsm_vec[ 5];
         lfsm_vec[ 5] <= lfsm_vec[ 6] ^ edt_channels_in[2];
         lfsm_vec[ 6] <= lfsm_vec[ 7];
         lfsm_vec[ 7] <= lfsm_vec[ 8] ^ edt_channels_in[1];
         lfsm_vec[ 8] <= lfsm_vec[ 9] ^ lfsm_vec[ 6];
         lfsm_vec[ 9] <= lfsm_vec[10];
         lfsm_vec[10] <= lfsm_vec[11] ^ edt_channels_in[0];
         lfsm_vec[11] <= lfsm_vec[12] ^ lfsm_vec[ 5];
         lfsm_vec[12] <= lfsm_vec[13] ^ lfsm_vec[ 3];
         lfsm_vec[13] <= lfsm_vec[14] ^ edt_channels_in[2];
         lfsm_vec[14] <= lfsm_vec[15];
         lfsm_vec[15] <= lfsm_vec[ 0] ^ edt_channels_in[0];
      end
   end

   always @(negedge edt_clock)
   begin : lockup_cells
      lfsm_vec_lockup[ 1] <= lfsm_vec[ 1];
      lfsm_vec_lockup[ 3] <= lfsm_vec[ 3];
      lfsm_vec_lockup[ 4] <= lfsm_vec[ 4];
      lfsm_vec_lockup[ 6] <= lfsm_vec[ 6];
      lfsm_vec_lockup[ 8] <= lfsm_vec[ 8];
      lfsm_vec_lockup[ 9] <= lfsm_vec[ 9];
      lfsm_vec_lockup[10] <= lfsm_vec[10];
      lfsm_vec_lockup[13] <= lfsm_vec[13];
      lfsm_vec_lockup[15] <= lfsm_vec[15];
   end

   always @(lfsm_vec_lockup)
   begin : phase_shifter
      edt_scan_in[0] = lfsm_vec_lockup[ 6] ^ lfsm_vec_lockup[ 8] ^ lfsm_vec_lockup[ 9];
      edt_scan_in[1] = lfsm_vec_lockup[ 1] ^ lfsm_vec_lockup[ 4] ^ lfsm_vec_lockup[13];
      edt_scan_in[2] = lfsm_vec_lockup[ 3] ^ lfsm_vec_lockup[10] ^ lfsm_vec_lockup[15];
   end

endmodule


module sync_fifo_edt_onehot_decoder_1_to_1 (
   input  wire      encoded_masks,
   output reg       decoded_masks
);
   always @(encoded_masks)
   begin
      case (encoded_masks)
         1'b0:    decoded_masks = 1'b0;
         1'b1:    decoded_masks = 1'b1;
      endcase
   end
endmodule


module sync_fifo_edt_xor_decoder (
   input  wire [2:0] encoded_masks,
   output wire       decoded_masks_0,
   output wire       decoded_masks_1,
   output wire       decoded_masks_2
);
   assign decoded_masks_0 = encoded_masks[0];

   assign decoded_masks_1 = encoded_masks[1];

   assign decoded_masks_2 = encoded_masks[2];

endmodule


module sync_fifo_edt_controller (
   input  wire       edt_clock,
   input  wire       edt_update,
   input  wire [2:0] edt_channels_in,
   output wire [2:0] edt_channels_out_from_controller,
   output wire       masks_for_compactor_0,
   output wire       masks_for_compactor_1,
   output wire       masks_for_compactor_2
);
   reg    [1:0] masks_shift_reg_0;
   reg          masks_shift_reg_1;
   reg          masks_shift_reg_2;
   reg    [1:0] masks_hold_reg_0;
   reg          masks_hold_reg_1;
   reg          masks_hold_reg_2;
   wire         control_bit;
   wire         onehot_encoded_masks_0;
   wire         onehot_encoded_masks_1;
   wire         onehot_encoded_masks_2;
   wire   [2:0] xor_encoded_masks;
   wire         onehot_decoded_masks_0;
   wire         onehot_decoded_masks_1;
   wire         onehot_decoded_masks_2;
   wire         xor_decoded_masks_0;
   wire         xor_decoded_masks_1;
   wire         xor_decoded_masks_2;
   wire         masks_shift_reg_sync_reset;

   assign masks_shift_reg_sync_reset = edt_update;

   always @(posedge edt_clock)
   begin : shift_masks_regs
      if (masks_shift_reg_sync_reset == 1'b1) begin
         masks_shift_reg_0 <= 2'b00;
         masks_shift_reg_1 <= 1'b0;
         masks_shift_reg_2 <= 1'b0;
      end
      else begin
         masks_shift_reg_0 <= {edt_channels_in[0], masks_shift_reg_0[1]};
         masks_shift_reg_1 <= edt_channels_in[1];
         masks_shift_reg_2 <= edt_channels_in[2];
      end
   end

   always @(posedge edt_clock)
   begin : update_masks_regs
      if (edt_update == 1'b1) begin
         masks_hold_reg_0 <= masks_shift_reg_0;
         masks_hold_reg_1 <= masks_shift_reg_1;
         masks_hold_reg_2 <= masks_shift_reg_2;
      end
   end

   assign edt_channels_out_from_controller[0] = masks_shift_reg_0[0];
   assign edt_channels_out_from_controller[1] = masks_shift_reg_1;
   assign edt_channels_out_from_controller[2] = masks_shift_reg_2;

   assign control_bit = masks_hold_reg_0[1];

   assign xor_encoded_masks = {masks_hold_reg_2, masks_hold_reg_1, masks_hold_reg_0[0]};

   assign onehot_encoded_masks_0 = masks_hold_reg_0[0];
   assign onehot_encoded_masks_1 = masks_hold_reg_1;
   assign onehot_encoded_masks_2 = masks_hold_reg_2;

   sync_fifo_edt_xor_decoder xor_decoder (
      .encoded_masks(xor_encoded_masks),
      .decoded_masks_0(xor_decoded_masks_0),
      .decoded_masks_1(xor_decoded_masks_1),
      .decoded_masks_2(xor_decoded_masks_2));

   sync_fifo_edt_onehot_decoder_1_to_1 decoder1 (.encoded_masks(onehot_encoded_masks_0),
                                                 .decoded_masks(onehot_decoded_masks_0));
   sync_fifo_edt_onehot_decoder_1_to_1 decoder2 (.encoded_masks(onehot_encoded_masks_1),
                                                 .decoded_masks(onehot_decoded_masks_1));
   sync_fifo_edt_onehot_decoder_1_to_1 decoder3 (.encoded_masks(onehot_encoded_masks_2),
                                                 .decoded_masks(onehot_decoded_masks_2));

   assign masks_for_compactor_0 = control_bit ? onehot_decoded_masks_0 : xor_decoded_masks_0;
   assign masks_for_compactor_1 = control_bit ? onehot_decoded_masks_1 : xor_decoded_masks_1;
   assign masks_for_compactor_2 = control_bit ? onehot_decoded_masks_2 : xor_decoded_masks_2;
endmodule


module sync_fifo_edt_compactor (
   input  wire [2:0] edt_scan_out,
   input  wire       masks_for_compactor_0,
   input  wire       masks_for_compactor_1,
   input  wire       masks_for_compactor_2,
   output wire [2:0] edt_channels_out
);
   wire         masked_scan_outputs_0;
   wire         masked_scan_outputs_1;
   wire         masked_scan_outputs_2;

   assign masked_scan_outputs_0 = edt_scan_out[0] & masks_for_compactor_0;
   assign masked_scan_outputs_1 = edt_scan_out[1] & masks_for_compactor_1;
   assign masked_scan_outputs_2 = edt_scan_out[2] & masks_for_compactor_2;


   assign edt_channels_out[0] = masked_scan_outputs_0;
   assign edt_channels_out[1] = masked_scan_outputs_1;
   assign edt_channels_out[2] = masked_scan_outputs_2;
endmodule


module sync_fifo_edt_bypass_logic (
   input  wire       edt_bypass,
   input  wire [2:0] edt_channels_in,
   output wire [2:0] edt_channels_out,
   output wire [2:0] edt_scan_in,
   input  wire [2:0] edt_scan_out,
   input  wire [2:0] edt_bypass_in,
   input  wire [2:0] edt_bypass_out
);

   assign edt_scan_in[0] = edt_bypass ? edt_channels_in[0] : edt_bypass_in[0];
   assign edt_scan_in[1] = edt_bypass ? edt_channels_in[1] : edt_bypass_in[1];
   assign edt_scan_in[2] = edt_bypass ? edt_channels_in[2] : edt_bypass_in[2];

   assign edt_channels_out[0] = edt_bypass ? edt_scan_out[0] : edt_bypass_out[0];
   assign edt_channels_out[1] = edt_bypass ? edt_scan_out[1] : edt_bypass_out[1];
   assign edt_channels_out[2] = edt_bypass ? edt_scan_out[2] : edt_bypass_out[2];
endmodule


module sync_fifo_edt (
   input  wire       edt_clock,
   input  wire       edt_update,
   input  wire       edt_bypass,
   input  wire [2:0] edt_channels_in,
   output wire [2:0] edt_channels_out,
   output wire [2:0] edt_scan_in,
   input  wire [2:0] edt_scan_out
);
   wire   [2:0] edt_bypass_in;
   wire   [2:0] edt_bypass_out;
   wire         masks_for_compactor_0;
   wire         masks_for_compactor_1;
   wire         masks_for_compactor_2;
   wire   [2:0] edt_channels_out_from_controller;

   sync_fifo_edt_decompressor sync_fifo_edt_decompressor_i (
      .edt_clock(edt_clock),
      .edt_update(edt_update),
      .edt_channels_in(edt_channels_out_from_controller),
      .edt_scan_in(edt_bypass_in));

   sync_fifo_edt_compactor sync_fifo_edt_compactor_i (
      .edt_scan_out(edt_scan_out),
      .masks_for_compactor_0(masks_for_compactor_0),
      .masks_for_compactor_1(masks_for_compactor_1),
      .masks_for_compactor_2(masks_for_compactor_2),
      .edt_channels_out(edt_bypass_out));

   sync_fifo_edt_controller sync_fifo_edt_controller_i (
      .edt_clock(edt_clock),
      .edt_update(edt_update),
      .edt_channels_in(edt_channels_in),
      .edt_channels_out_from_controller(edt_channels_out_from_controller),
      .masks_for_compactor_0(masks_for_compactor_0),
      .masks_for_compactor_1(masks_for_compactor_1),
      .masks_for_compactor_2(masks_for_compactor_2));

   sync_fifo_edt_bypass_logic sync_fifo_edt_bypass_logic_i (
      .edt_bypass(edt_bypass),
      .edt_channels_in(edt_channels_in),
      .edt_channels_out(edt_channels_out),
      .edt_scan_in(edt_scan_in),
      .edt_scan_out(edt_scan_out),
      .edt_bypass_in(edt_bypass_in),
      .edt_bypass_out(edt_bypass_out));
endmodule


