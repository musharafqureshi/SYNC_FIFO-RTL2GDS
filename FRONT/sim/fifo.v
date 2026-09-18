`timescale 1ns/1ps

module sync_fifo(clk_i,rst_i,wr_en_i,rd_en_i,wr_data_i,rd_data_o,full_o,empty_o,error_o);
  input  clk_i,rst_i,wr_en_i,rd_en_i;
  input [7:0]wr_data_i;                 //declaration of inputs and outputs
  output reg [7:0]rd_data_o;
  output reg full_o,empty_o,error_o;

  //declare pointers and memory unit
  reg [3:0]wr_ptr;                 //fifo is a memory block of 16 locations, each location is 8 bits
  reg [3:0]rd_ptr;                 //4-bit ptr is required to point to address of 16 locations
  reg wr_toggle_flag,rd_toggle_flag;
  reg [7:0]fifo[15:0];
  integer i;

  always@(posedge clk_i)
    begin
      if(rst_i==1)
        begin
          rd_data_o<=0;      //reset output ports and internal registers
          error_o<=0;
          // full_o/empty_o are purely combinational (see always@(*) below),
          // driven from wr_ptr/rd_ptr/toggle flags only - do NOT also drive
          // them here, that created a multiple-driver race that left them
          // stuck at stale values right after reset.
          wr_ptr<=0;
          rd_ptr<=0;
          wr_toggle_flag<=0;
          rd_toggle_flag<=0;
          for(i=0;i<16;i=i+1)
            begin
              fifo[i]<=0;
            end
        end
      else
        begin  //normal operation
          error_o<=0;
          if(wr_en_i==1)
            begin
              if(full_o==1)
                begin   //if full_o is high, raise error
                  error_o<=1;
                end
              else
                begin                     //write operation
                  fifo[wr_ptr]<=wr_data_i;
                  if(wr_ptr==15)
                    begin
                      wr_ptr<=0;
                      wr_toggle_flag<=~wr_toggle_flag;
                    end
                  else
                    begin
                      wr_ptr<=wr_ptr+1;
                    end
                end
            end
          if(rd_en_i==1)
            begin
              if(empty_o==1)
                begin      //if empty flag is high, raise error
                  error_o<=1;
                end
              else
                begin
                  rd_data_o<=fifo[rd_ptr];   // read operation
                  if(rd_ptr==15)
                    begin
                      rd_ptr<=0;
                      rd_toggle_flag<=~rd_toggle_flag;
                    end
                  else
                    begin
                      rd_ptr<=rd_ptr+1;
                    end
                end
            end
        end
    end

  // combinational flag logic â€” blocking assignments, since this is not a
  // clocked block. Using <= here was likely why full_o synthesized with
  // unexpected (possibly sequential) behavior at the gate level.
  always@(*)
    begin
      full_o = 0;
      empty_o = 0;
      if(wr_ptr==rd_ptr)
        begin
          if(wr_toggle_flag==rd_toggle_flag)
            begin
              empty_o = 1'b1;
            end
          else
            begin
              full_o = 1'b1;
            end
        end
    end
endmodule
