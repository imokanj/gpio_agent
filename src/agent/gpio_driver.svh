/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent driver. Used for translating sequence items into pin
 *               wiggles.
 */

class GpioDriver extends uvm_driver #(GpioItem);
  `uvm_component_utils(GpioDriver)

  // Components
  virtual GpioIf.mp_master        mp;
  virtual GpioIf.mp_master_async  mp_async;
  virtual GpioIf.mp_monitor       mp_mon;
  virtual GpioIf.mp_monitor_async mp_mon_async;

  // Constructor
  function new(string name = "GpioDriver", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Function/Task declarations
  extern virtual function void driveInit();
  extern virtual task          driveGpioPins     (input GpioItem it, input bit is_sync);
  extern virtual task          readGpioPins      (input GpioItem it, output GpioItem rsp, input bit is_sync);
  extern virtual task          run_phase   (uvm_phase phase);

endclass: GpioDriver

//******************************************************************************
// Function/Task implementations
//******************************************************************************

  function void GpioDriver::driveInit();
    mp.cb_master.gpio_out <= gpio_out_init;
  endfunction: driveInit

  //----------------------------------------------------------------------------

  task GpioDriver::driveGpioPins(input GpioItem it, input bit is_sync);
    // wait for clock only if synchronous write
    if (is_sync) begin
      @mp.cb_master;
    end

    foreach (it.pin_name_o[i]) begin
      if (is_sync) begin
        mp.cb_master.gpio_out[it.pin_name_o[i]] <= it.gpio_out[i];
      end else begin
        mp_async.gpio_out[it.pin_name_o[i]]     <= it.gpio_out[i];
      end
    end
  endtask: driveGpioPins

  //----------------------------------------------------------------------------

  task GpioDriver::readGpioPins(input GpioItem it, output GpioItem rsp, input bit is_sync);
    rsp = GpioItem::type_id::create("rsp");
    rsp.gpio_in  = new [it.pin_name_i.size()];
    rsp.gpio_out = new [it.pin_name_o.size()];

    // wait for clock only if synchronous read
    if (is_sync) begin
      @mp_mon.cb_monitor;
    end

    foreach (it.pin_name_i[i]) begin
      if (is_sync) begin
        rsp.gpio_in[i] = mp_mon.cb_monitor.gpio_in[it.pin_name_i[i]];
      end else begin
        rsp.gpio_in[i] = mp_mon_async.gpio_in[it.pin_name_i[i]];
      end
    end

    foreach (it.pin_name_o[i]) begin
      if (is_sync) begin
        rsp.gpio_out[i] = mp_mon.cb_monitor.gpio_out[it.pin_name_o[i]];
      end else begin
        rsp.gpio_out[i] = mp_mon_async.gpio_out[it.pin_name_o[i]];
      end
    end

    rsp.set_id_info(it);
  endtask: readGpioPins

  //----------------------------------------------------------------------------

  task GpioDriver::run_phase(uvm_phase phase);
    GpioItem it, rsp;

    driveInit();
    forever begin
      seq_item_port.get_next_item(it);
      rsp = null;

      case(it.op_type)
        RD_SYNC:  readGpioPins (it, rsp, 1'b1);
        RD_ASYNC: readGpioPins (it, rsp, 1'b0);
        WR_SYNC:  driveGpioPins(it, 1'b1);
        WR_ASYNC: driveGpioPins(it, 1'b0);
      endcase

      // get next transaction on rising clk edge
      // @mp.cb_master;
      if (rsp == null) begin
        `uvm_info("GPIO_DRV", "Processed Set Pin OP", UVM_HIGH)
        seq_item_port.item_done();
      end else begin
        `uvm_info("GPIO_DRV", "Processed Get Pin OP", UVM_HIGH)
         seq_item_port.item_done(rsp);
      end
    end
  endtask: run_phase
