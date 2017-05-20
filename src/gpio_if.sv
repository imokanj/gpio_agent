/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent interface signal definitions. Interface is connected
 *               to the DUT and used by the GPIO agent to read/write pins.
 *
 *               GPIO agent inputs  == DUT outputs
 *               GPIO agent outputs == DUT inputs
 */

interface GpioIf(
  input logic clk
);

  timeunit        1ns;
  timeprecision 100ps;

//******************************************************************************
// Ports
//******************************************************************************

  wire  [1023:0] gpio_in;
  logic [1023:0] gpio_out;

//******************************************************************************
// Clocking Blocks
//******************************************************************************

  // GPIO Master clocking block
  clocking cb_master @(posedge clk);
    default input #1step output #1step;
    input  gpio_in;
    output gpio_out;
  endclocking

  // GPIO Monitor clocking block
  clocking cb_monitor @(posedge clk);
    default input #1step;
    input  gpio_in, gpio_out;
  endclocking

//******************************************************************************
// Modports
//******************************************************************************

  // GPIO Master modport
  modport mp_master (input clk, clocking cb_master);

  // GPIO Monitor modport
  modport mp_monitor(input clk, clocking cb_monitor);

endinterface : GpioIf
