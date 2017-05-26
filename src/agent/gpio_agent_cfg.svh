/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent configuration class. An object of this class should
 *               be put in the configuration database so that the GPIO agent can
 *               get the user configuration.
 */

class GpioAgentCfg extends uvm_object;
  `uvm_object_utils(GpioAgentCfg)

  // Variables
  uvm_active_passive_enum is_active    = UVM_PASSIVE;
  bit                     is_x_z_check = 1'b0;
  virtual GpioIf          vif;

  // Constructor
  function new(string name = "GpioAgentCfg");
    super.new(name);
  endfunction

endclass: GpioAgentCfg
