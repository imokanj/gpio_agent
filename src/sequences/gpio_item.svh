/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent sequence item.
 */

class GpioItem extends uvm_sequence_item;

  // Variables
  rand op_type_t     op_type;

       logic         gpio_in    [];
  rand logic         gpio_out   [];
  rand gpio_input_t  pin_name_i [];
  rand gpio_output_t pin_name_o [];

  // Constructor
  function new(string name = "GpioItem");
    super.new(name);
  endfunction

  `uvm_object_utils_begin(GpioItem)
    `uvm_field_enum      (   op_type_t,     op_type, UVM_DEFAULT | UVM_NOPACK)
    `uvm_field_array_int (                  gpio_in, UVM_DEFAULT)
    `uvm_field_array_int (                 gpio_out, UVM_DEFAULT)
    `uvm_field_array_enum( gpio_input_t, pin_name_i, UVM_DEFAULT | UVM_NOPACK)
    `uvm_field_array_enum(gpio_output_t, pin_name_o, UVM_DEFAULT | UVM_NOPACK)
  `uvm_object_utils_end

endclass: GpioItem
