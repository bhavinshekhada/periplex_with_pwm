
// Efinity Top-level template
// Version: 2023.2.307
// Date: 2024-05-08 09:53

// Copyright (C) 2013 - 2023 Efinix Inc. All rights reserved.

// This file may be used as a starting point for Efinity synthesis top-level target.
// The port list here matches what is expected by Efinity constraint files generated
// by the Efinity Interface Designer.

// To use this:
//     #1)  Save this file with a different name to a different directory, where source files are kept.
//              Example: you may wish to save as C:\Users\Dell\Downloads\periplex_design_5_write_read (5)\periplex_design_5_write_read\periplex_design_5_write_read\periplex_design_4.v
//     #2)  Add the newly saved file into Efinity project as design file
//     #3)  Edit the top level entity in Efinity project to:  periplex_design_4
//     #4)  Insert design content.


module periplex_design_4
(
  input clk1_in,
  input clk2_in,
  input [7:0] gpio_in,
  input [0:0] i_rx_serial,
  input i_test_rx,
  input clk1,
  input clk2,
  output [7:0] gpio_out,
  output [7:0] gpio_oe,
  output hold,
  output o_test_tx,
  output [0:0] o_tx_serial,
  output [2:0] pwm_out,
  output led
);


endmodule

