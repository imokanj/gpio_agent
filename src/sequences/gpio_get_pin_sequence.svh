/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent sequence used to read the current bit values of
 *               selected design input/output pins.
 */

class GpioGetPinSequence extends GpioSetPinSequence;
  `uvm_object_utils(GpioGetPinSequence)

  // Constructor
  function new(string name = "GpioGetPinSequence");
    super.new(name);
  endfunction: new

  // Function/Task declarations
  extern virtual task body();

endclass: GpioGetPinSequence

//******************************************************************************
// Function/Task implementations
//******************************************************************************

  task GpioGetPinSequence::body();
    // create the transaction item and call set pin sequence
    super.body();

    get_response(rsp);
  endtask: body
