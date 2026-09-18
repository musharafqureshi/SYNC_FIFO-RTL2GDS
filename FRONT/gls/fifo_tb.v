`timescale 1ns/1ps
//=============================================================
// Self-checking testbench for sync_fifo
// - Golden (behavioral) reference model runs alongside the DUT
// - Automatic checks every clock: full_o, empty_o, error_o, rd_data_o
// - X/Z detection on every DUT output every cycle
// - Directed boundary tests (overflow write, underflow read)
// - Randomized read/write stress test
// - Simultaneous read+write corner case
// - Final PASS/FAIL summary with error count
//=============================================================

module testbench;

  parameter DEPTH = 16;
  parameter DW    = 8;

  reg              clk_i, rst_i, wr_en_i, rd_en_i;
  reg  [DW-1:0]    wr_data_i;
  wire [DW-1:0]    rd_data_o;
  wire             full_o, empty_o, error_o;

  integer errors;
  integer checks;

  //-----------------------------------------------------------
  // DUT
  //-----------------------------------------------------------
  sync_fifo dut (
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .wr_en_i  (wr_en_i),
    .rd_en_i  (rd_en_i),
    .wr_data_i(wr_data_i),
    .rd_data_o(rd_data_o),
    .full_o   (full_o),
    .empty_o  (empty_o),
    .error_o  (error_o)
  );

  //-----------------------------------------------------------
  // Clock
  //-----------------------------------------------------------
  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i;

  //-----------------------------------------------------------
  // Golden reference model (mirrors the DUT's exact behavior)
  //-----------------------------------------------------------
  reg [DW-1:0] gmem [0:DEPTH-1];
  reg [4:0]    g_wr_ptr, g_rd_ptr;   // 5 bits: extra bit encodes wrap (acts like toggle flag)
  reg          g_error_exp;
  wire         g_full, g_empty;
  wire [DW-1:0] g_rd_data_exp;

  assign g_full  = (g_wr_ptr[3:0] == g_rd_ptr[3:0]) && (g_wr_ptr[4] != g_rd_ptr[4]);
  assign g_empty = (g_wr_ptr[3:0] == g_rd_ptr[3:0]) && (g_wr_ptr[4] == g_rd_ptr[4]);
  assign g_rd_data_exp = gmem[g_rd_ptr[3:0]];

  // golden model update - same clock edge, same semantics as DUT RTL
  always @(posedge clk_i) begin
    if (rst_i) begin
      g_wr_ptr <= 5'd0;
      g_rd_ptr <= 5'd0;
    end else begin
      if (wr_en_i && !g_full) begin
        gmem[g_wr_ptr[3:0]] <= wr_data_i;
        g_wr_ptr <= g_wr_ptr + 5'd1;
      end
      if (rd_en_i && !g_empty) begin
        g_rd_ptr <= g_rd_ptr + 5'd1;
      end
    end
  end

  //-----------------------------------------------------------
  // Checker - runs every posedge, sampled just before next edge
  // so all non-blocking updates have settled
  //-----------------------------------------------------------
  reg checking_enabled;
  initial checking_enabled = 1'b0;

  always @(posedge clk_i) begin
    #1; // let non-blocking assigns (DUT + golden model) settle
    if (checking_enabled && !rst_i) begin
      checks = checks + 1;

      // X/Z propagation check on every DUT output
      if (^rd_data_o === 1'bx) begin
        $display("[%0t] ERROR: rd_data_o is X/Z (%b)", $time, rd_data_o);
        errors = errors + 1;
      end
      if (full_o === 1'bx) begin
        $display("[%0t] ERROR: full_o is X", $time);
        errors = errors + 1;
      end
      if (empty_o === 1'bx) begin
        $display("[%0t] ERROR: empty_o is X", $time);
        errors = errors + 1;
      end
      if (error_o === 1'bx) begin
        $display("[%0t] ERROR: error_o is X", $time);
        errors = errors + 1;
      end

      // full_o / empty_o must never both be high
      if (full_o === 1'b1 && empty_o === 1'b1) begin
        $display("[%0t] ERROR: full_o and empty_o both asserted", $time);
        errors = errors + 1;
      end

      // flags vs golden model
      if (full_o !== g_full) begin
        $display("[%0t] ERROR: full_o=%b expected=%b", $time, full_o, g_full);
        errors = errors + 1;
      end
      if (empty_o !== g_empty) begin
        $display("[%0t] ERROR: empty_o=%b expected=%b", $time, empty_o, g_empty);
        errors = errors + 1;
      end
    end
  end

  //-----------------------------------------------------------
  // Tasks
  //-----------------------------------------------------------
  task do_reset;
    begin
      rst_i     = 1'b1;
      wr_en_i   = 1'b0;
      rd_en_i   = 1'b0;
      wr_data_i = 8'h00;
      repeat (3) @(posedge clk_i);
      @(negedge clk_i);
      rst_i = 1'b0;
      @(posedge clk_i);
      checking_enabled = 1'b1;
    end
  endtask

  task write_word(input [DW-1:0] data);
    begin
      @(negedge clk_i);
      wr_data_i = data;
      wr_en_i   = 1'b1;
      @(posedge clk_i);
      #1;
      @(negedge clk_i);
      wr_en_i   = 1'b0;
    end
  endtask

  task read_word;
    reg [DW-1:0] expected;
    begin
      @(negedge clk_i);
      expected = g_rd_data_exp;      // captured BEFORE the read edge (matches read latency)
      rd_en_i  = 1'b1;
      @(posedge clk_i);
      #1;
      if (rd_data_o !== expected) begin
        $display("[%0t] ERROR: rd_data_o=%h expected=%h", $time, rd_data_o, expected);
        errors = errors + 1;
      end
      checks = checks + 1;
      @(negedge clk_i);
      rd_en_i  = 1'b0;
    end
  endtask

  task check_error_flag(input expected);
    begin
      #1;
      checks = checks + 1;
      if (error_o !== expected) begin
        $display("[%0t] ERROR: error_o=%b expected=%b", $time, error_o, expected);
        errors = errors + 1;
      end
    end
  endtask

  //-----------------------------------------------------------
  // Main stimulus
  //-----------------------------------------------------------
  integer i;
  reg [DW-1:0] rand_data;

  initial begin
    errors = 0;
    checks = 0;

    $dumpfile("sync_fifo.vcd");
    $dumpvars(0, testbench);

    // 1. Reset check
    do_reset;
    checks = checks + 1;
    if (empty_o !== 1'b1 || full_o !== 1'b0 || error_o !== 1'b0) begin
      $display("[%0t] ERROR: post-reset state wrong (empty=%b full=%b error=%b)",
                $time, empty_o, full_o, error_o);
      errors = errors + 1;
    end

    // 2. Fill FIFO completely (16 writes), verify full_o asserts exactly at word 16
    $display("[%0t] --- Fill test ---", $time);
    for (i = 0; i < DEPTH; i = i + 1) begin
      rand_data = $random;
      write_word(rand_data);
    end
    checks = checks + 1;
    if (full_o !== 1'b1) begin
      $display("[%0t] ERROR: full_o not asserted after %0d writes", $time, DEPTH);
      errors = errors + 1;
    end

    // 3. Overflow write while full -> must raise error_o, must not corrupt data
    $display("[%0t] --- Overflow test ---", $time);
    write_word(8'hFF);
    check_error_flag(1'b1);

    // 4. Drain FIFO completely (16 reads), verify data order + empty_o at the end
    $display("[%0t] --- Drain test ---", $time);
    for (i = 0; i < DEPTH; i = i + 1) begin
      read_word;
    end
    checks = checks + 1;
    if (empty_o !== 1'b1) begin
      $display("[%0t] ERROR: empty_o not asserted after %0d reads", $time, DEPTH);
      errors = errors + 1;
    end

    // 5. Underflow read while empty -> must raise error_o
    // NOTE: intentionally NOT using read_word here. On an underflow read the
    // DUT correctly performs no data transfer (rd_data_o simply holds its
    // previous value), so read_word's data-vs-golden-memory check does not
    // apply. We just pulse rd_en_i and confirm error_o asserts.
    $display("[%0t] --- Underflow test ---", $time);
    @(negedge clk_i);
    rd_en_i = 1'b1;
    @(posedge clk_i);
    check_error_flag(1'b1);
    @(negedge clk_i);
    rd_en_i = 1'b0;

    // 6. Randomized interleaved read/write stress
    $display("[%0t] --- Randomized stress test ---", $time);
    for (i = 0; i < 200; i = i + 1) begin
      @(negedge clk_i);
      wr_en_i   = $random;
      rd_en_i   = $random;
      wr_data_i = $random;
      @(posedge clk_i);
      #1;
    end
    @(negedge clk_i);
    wr_en_i = 1'b0;
    rd_en_i = 1'b0;

    // 7. Simultaneous read+write corner case, done explicitly a few times
    $display("[%0t] --- Simultaneous read+write test ---", $time);
    write_word(8'hA5);   // ensure at least one entry so simultaneous op is legal
    for (i = 0; i < 10; i = i + 1) begin
      @(negedge clk_i);
      wr_data_i = $random;
      wr_en_i   = 1'b1;
      rd_en_i   = 1'b1;
      @(posedge clk_i);
      #1;
    end
    @(negedge clk_i);
    wr_en_i = 1'b0;
    rd_en_i = 1'b0;

    // drain whatever is left so final state is clean
    while (empty_o !== 1'b1) begin
      read_word;
    end

    //-----------------------------------------------------------
    // Summary
    //-----------------------------------------------------------
    #20;
    $display("=====================================================");
    if (errors == 0)
      $display("TEST PASSED  (%0d checks, 0 errors)", checks);
    else
      $display("TEST FAILED  (%0d checks, %0d errors)", checks, errors);
    $display("=====================================================");
    $finish;
  end

  // watchdog
  initial begin
    #100000;
    $display("[%0t] ERROR: TIMEOUT - simulation did not finish", $time);
    $display("TEST FAILED (timeout)");
    $finish;
  end

endmodule
