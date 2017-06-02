/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : The GPIO agent is used to drive and read individual DUT pins.
 *               An object of this class should be instantiated in the user
 *               environment.
 */

class GpioAgent extends uvm_agent;
  `uvm_component_param_utils(GpioAgent)

  // Components
  uvm_sequencer #(GpioItem) sqcr;
  GpioDriver                drv;
  GpioMonitor               mon;

  // Configurations
  GpioAgentCfg cfg;

  // Ports
  uvm_analysis_port #(GpioItem) aport;

  // Constructor
  function new(string name = "GpioAgent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Function/Task declarations
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass: GpioAgent

//******************************************************************************
// Function/Task implementations
//******************************************************************************

  function void GpioAgent::build_phase(uvm_phase phase);
    aport = new("aport", this);

    // get the GPIO agent configuration
    if (!uvm_config_db #(GpioAgentCfg)::get(this, "", "gpio_agent_cfg", cfg)) begin
      `uvm_fatal("GPIO_AGT", "Couldn't get the GPIO agent configuration")
    end

    // check if the virtual interface reference is populated
    if (cfg.vif == null) begin
      `uvm_fatal("GPIO_AGT", "Virtual interface not found")
    end

    // create agent components
    if (cfg.is_active == UVM_ACTIVE) begin
      sqcr       = uvm_sequencer #(GpioItem)::type_id::create("sequencer", this);
      drv        = GpioDriver               ::type_id::create(   "driver", this);
      drv.vif    = cfg.vif;
      drv.mp_mas = cfg.vif;
      drv.mp_mon = cfg.vif;
    end

    mon     = GpioMonitor::type_id::create("monitor", this);
    mon.cfg = cfg;
    mon.mp  = cfg.vif;
  endfunction: build_phase

  //----------------------------------------------------------------------------

  function void GpioAgent::connect_phase(uvm_phase phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqcr.seq_item_export);
    end
    mon.aport.connect(aport);
  endfunction: connect_phase
