/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent base sequence. All other sequences are extended from
 *               this one.
 */

class GpioBaseSequence extends uvm_sequence #(GpioItem);
  `uvm_object_utils(GpioBaseSequence)

  // Variables
  GpioItem             it, rsp;   // item and response
  static int           inst_cnt;  // current instance number

         logic         gpio_in    [];
  rand   logic         gpio_out   [];
  rand   gpio_input_t  pin_name_i [];
  rand   gpio_output_t pin_name_o [];
  rand   bit [31:0]    duration;
  rand   op_type_t     op_type;

  // Constructor
  function new(string name = "GpioBaseSequence");
    super.new(name);
  endfunction: new

  extern virtual task body();

endclass: GpioBaseSequence

//******************************************************************************
// Function/Task implementations
//******************************************************************************

  task GpioBaseSequence::body();
    inst_cnt++;
    it = GpioItem::type_id::create("spi_it");
  endtask: body
