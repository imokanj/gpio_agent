/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent sequence used to write bit values to selected design
 *               input pins.
 */

class GpioSetPinSequence extends GpioBaseSequence;
  `uvm_object_utils(GpioSetPinSequence)

  // Constructor
  function new(string name = "GpioSetPinSequence");
    super.new(name);
  endfunction: new

  // Function/Task declarations
  extern virtual task body();

endclass: GpioSetPinSequence

//******************************************************************************
// Function/Task implementations
//******************************************************************************

  task GpioSetPinSequence::body();
    super.body(); // create the transaction item

    repeat (duration) begin
      start_item(it);
      void'(it.randomize() with {
        pin_name_o.size() == local::pin_name_o.size();
        foreach(local::pin_name_o[i])
          pin_name_o[i]   == local::pin_name_o[i];
        pin_name_i.size() == local::pin_name_i.size();
        foreach(local::pin_name_i[i])
          pin_name_i[i]   == local::pin_name_i[i];
        gpio_out.size()   == local::gpio_out.size();
        foreach(local::gpio_out[i])
          gpio_out[i]     == local::gpio_out[i];
        op_type           == local::op_type;
      });
      finish_item(it);
    end
  endtask: body
