/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent monitor. Used for recording DUT pins on every clock
 *               cycle and sending that information through the analysis port.
 */

class GpioMonitor extends uvm_monitor;
  `uvm_component_utils(GpioMonitor)

  // Components
  virtual GpioIf.mp_monitor     mp;

  // Configurations
  GpioAgentCfg cfg;

  // Ports
  uvm_analysis_port #(GpioItem) aport;

  // Constructor
  function new(string name = "GpioMonitor", uvm_component parent);
    super.new(name, parent);
    aport = new("aport", this);
  endfunction

  // Function/Task declarations
  extern virtual function void checkXZ  (GpioItem it);
  extern virtual task          run_phase(uvm_phase phase);
  extern virtual task          readPins (GpioItem it);

endclass: GpioMonitor

//******************************************************************************
// Function/Task implementations
//******************************************************************************

  function void GpioMonitor::checkXZ(input GpioItem it);
    string warn_string_x;
    string warn_string_z;

    for (int i = 0; i < W_IN; i++) begin
      if          (it.gpio_in[i] === 1'bX) begin
        warn_string_x = $sformatf({warn_string_x, " %s"}, it.pin_name_i[i].name());
      end else if (it.gpio_in[i] === 1'bZ) begin
        warn_string_z = $sformatf({warn_string_z, " %s"}, it.pin_name_i[i].name());
      end
    end

    for (int i = 0; i < W_OUT; i++) begin
      if          (it.gpio_out[i] === 1'bX) begin
        warn_string_z = $sformatf({warn_string_z, " %s"}, it.pin_name_o[i].name());
      end else if (it.gpio_out[i] === 1'bZ) begin
        warn_string_z = $sformatf({warn_string_z, " %s"}, it.pin_name_o[i].name());
      end
    end

    if          (warn_string_x != "") begin
      `uvm_warning("GPIO_MON", {"Value 'X' detected on pin(s) :", warn_string_x})
    end else if (warn_string_z != "") begin
      `uvm_warning("GPIO_MON", {"Value 'Z' detected on pin(s) :", warn_string_z})
    end
  endfunction : checkXZ

  //----------------------------------------------------------------------------

  task GpioMonitor::readPins(input GpioItem it);
    @mp.cb_monitor;

    for (int i = 0; i < W_IN; i++) begin
      it.gpio_in[i]  = mp.cb_monitor.gpio_in[i];
    end

    for (int i = 0; i < W_OUT; i++) begin
      it.gpio_out[i] = mp.cb_monitor.gpio_out[i];
    end
  endtask: readPins

  //----------------------------------------------------------------------------

  task GpioMonitor::run_phase(uvm_phase phase);
    GpioItem it;
    it          = GpioItem::type_id::create("it_mon");
    it.gpio_in  = new [W_IN];
    it.gpio_out = new [W_OUT];

    forever begin
      readPins(it);

      // perform checking for 'X' and 'Z' values
      if (cfg.is_x_z_check) begin
        checkXZ(it);
      end
      
      aport.write(GpioItem'(it.clone()));
    end
  endtask: run_phase
