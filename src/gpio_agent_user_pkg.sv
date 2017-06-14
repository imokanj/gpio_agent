/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent user package. This file should be edited by the user
 *               to specify the input and output GPIO agent pins, and set the
 *               initial values of the output pins.
 *
 *               GPIO agent inputs  == DUT outputs
 *               GPIO agent outputs == DUT inputs
 */

`ifndef _AGENT_GPIO_USER_PKG_
`define _AGENT_GPIO_USER_PKG_

package GpioAgentUserPkg;

  timeunit        1ns;
  timeprecision 100ps; 

//==============================================================================
// User section
//==============================================================================

  // agent input pins list
  typedef enum {
    READY,
    IRQ
  } gpio_input_t;
  gpio_input_t gpio_input_list;

  // agent output pins list
  typedef enum {
    ADDR_SPACE_1,
    ADDR_SPACE_0,
    LAST
  } gpio_output_t;
  gpio_output_t gpio_output_list;

  // if your simulator does not support built-in functions in constant expressions
  // please manually count the number of input and output pins and write them here,
  // and delete the *.num() calls
  parameter W_IN  = 2; // gpio_input_list.num();
  parameter W_OUT = 3; // gpio_output_list.num();

  // set the initial values of the GPIO output pins
  logic [W_OUT-1:0] gpio_out_init = {
    1'b0, // LAST
    1'b0, // ADDR_SPACE_0
    1'b0  // ADDR_SPACE_1
  };
  
endpackage : GpioAgentUserPkg

`endif
