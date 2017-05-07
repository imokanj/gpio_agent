/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO agent package. Contains :
 *                 - User specified input and output pins
 *                 - User specified initial output signal values
 *                 - All needed files for building the GPIO agent (except the GPIO interface)
 *                 - Convenience functions/tasks for writing/reading pin values

 *               GPIO agent inputs  == DUT outputs
 *               GPIO agent outputs == DUT inputs
 */

`ifndef _AGENT_GPIO_PKG_
`define _AGENT_GPIO_PKG_

package GpioAgentPkg;

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
    RST,
    ADDR_SPACE_1,
    ADDR_SPACE_0,
    LAST
  } gpio_output_t;
  gpio_output_t gpio_output_list;

  parameter W_IN  = gpio_input_list.num();
  parameter W_OUT = gpio_output_list.num();

  // set the initial values of the GPIO output pins
  logic [W_OUT-1:0] gpio_out_init = {
    1'b0, // LAST
    1'b0, // ADDR_SPACE_0
    1'b0, // ADDR_SPACE_1
    1'b1  // RST
  };

//==============================================================================
// System section
//==============================================================================

  typedef enum {
    RD_SYNC,
    RD_ASYNC,
    WR_SYNC,
    WR_ASYNC
  } op_type_t;

//******************************************************************************
// Imports
//******************************************************************************

  import uvm_pkg::*;

//******************************************************************************
// Includes
//******************************************************************************

  `include "uvm_macros.svh"

  // sequences
  `include "sequences/gpio_item.svh"
  `include "sequences/gpio_base_sequence.svh"
  `include "sequences/gpio_set_pin_sequence.svh"
  `include "sequences/gpio_get_pin_sequence.svh"

  // components
  `include "agent/gpio_agent_cfg.svh"
  `include "agent/gpio_driver.svh"
  `include "agent/gpio_monitor.svh"
  `include "agent/gpio_agent.svh"

//******************************************************************************
// Functions/Tasks
//******************************************************************************

  function automatic GpioAgentCfg configAgent(
    input uvm_active_passive_enum _is_active
  );
    GpioAgentCfg cfg = GpioAgentCfg::type_id::create("cfg");

    cfg.is_active = _is_active;
    return cfg;
  endfunction : configAgent

  //----------------------------------------------------------------------------

  function automatic string printPinEnumO(gpio_output_t a [], bit is_val);
    parameter DIGITS = "9876543210";
    string    str    = "";
    int       tmp;

    tmp = a.size();
    foreach(a[i]) begin
      if (!is_val) begin
        if (i != tmp-1) begin
          str = {str, a[i].name(), ", "};
        end else begin
          str = {str, a[i].name()};
        end
      end else begin
        if (i != tmp-1) begin
          str = {str, DIGITS[a[i]*8+:8], ", "};
        end else begin
          str = {str, DIGITS[a[i]*8+:8]};
        end
      end
    end
    return str;
  endfunction : printPinEnumO

  //----------------------------------------------------------------------------

  function automatic string printPinEnumI(gpio_input_t a [], bit is_val);
    parameter DIGITS = "9876543210";
    string    str    = "";
    int       tmp;

    tmp = a.size();
    foreach(a[i]) begin
      if (!is_val) begin
        if (i != tmp-1) begin
          str = {str, a[i].name(), ", "};
        end else begin
          str = {str, a[i].name()};
        end
      end else begin
        if (i != tmp-1) begin
          str = {str, DIGITS[a[i]*8+:8], ", "};
        end else begin
          str = {str, DIGITS[a[i]*8+:8]};
        end
      end
    end
    return str;
  endfunction : printPinEnumI

  //----------------------------------------------------------------------------

  function automatic string printPinEnumIO(
    gpio_input_t  a [],
    gpio_output_t b [],
    bit           is_val
  );
    string    str    = "";

    if (a.size() != 0) begin
      str = printPinEnumI(a, is_val);
      if (b.size() != 0) begin
        str = {str, ", "};
      end
    end

    if (b.size() != 0) begin
      str = {str, printPinEnumO(b, is_val)};
    end

    return str;
  endfunction : printPinEnumIO

  //----------------------------------------------------------------------------

  function automatic string printPinVal(logic v []);
    string    str    = "";
    string    val;
    int       tmp;

    tmp = v.size();
    foreach(v[i]) begin
      val = (v[i] === 1'bX) ? "X" :
            (v[i] === 1'bZ) ? "Z" :
            (v[i] === 1'b1) ? "1" : "0";
      if (i != tmp-1) begin
        str = {str, "1'b", val, ", "};
      end else begin
        str = {str, "1'b", val};
      end
    end
    return str;
  endfunction : printPinVal

  //----------------------------------------------------------------------------

  // write specified values to DUT inputs
  task automatic setPin(
    input  uvm_sequencer_base _sqcr,
    input  op_type_t          _op_type,
    input  gpio_output_t      _pin_name_o [],
    input  logic              _wr_data    [],
    input  bit [31:0]         _duration = 1
  );

    GpioSetPinSequence _seq;

    if (_sqcr == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent handle is NULL")
      return;
    end

    if (_op_type == WR_SYNC || _op_type == WR_ASYNC) begin
      _seq = GpioSetPinSequence::type_id::create("set_pin_seq");
    end else begin
      `uvm_error("GPIO_PKG", "\nWrong OP for this setPin task")
      return;
    end

    if (!(_seq.randomize() with {
      op_type           == _op_type;
      pin_name_o.size() == _pin_name_o.size();
      foreach(_pin_name_o[i])
        pin_name_o[i]   == _pin_name_o[i];
      gpio_out.size()   == _wr_data.size();
      foreach(_wr_data[i])
        gpio_out[i]     == _wr_data[i];
      duration          == _duration;
    })) `uvm_error("GPIO_PKG", "\nRandomization failed");

    `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Set OP:\n",
                             "-------------------------------------------------\n",
                             "OP Type  : %s\n",
                             "Pin Name : %s\n",
                             "Pin Num  : %s\n",
                             "Value    : %s\n"}
                             , _op_type.name(), printPinEnumO(_pin_name_o, 0), printPinEnumO(_pin_name_o, 1), printPinVal(_wr_data)
    ), UVM_LOW);

    _seq.start(_sqcr);

  endtask : setPin

  //----------------------------------------------------------------------------

  // read specified DUT pin values
  task automatic getPin(
    input  uvm_sequencer_base _sqcr,
    input  op_type_t          _op_type,
    input  gpio_input_t       _pin_name_i [] = null,
    input  gpio_output_t      _pin_name_o [] = null,
    output logic              _rd_data    []
  );

    GpioGetPinSequence _seq;

    if (_sqcr == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent handle is NULL")
      return;
    end

    if (_pin_name_i.size() == 0 && _pin_name_o.size() == 0) begin
      `uvm_error("GPIO_PKG", "\nNo input or output pins specified")
      return;
    end

    if (_op_type == RD_SYNC || _op_type == RD_ASYNC) begin
      _seq = GpioGetPinSequence::type_id::create("get_pin_seq");
    end else begin
      `uvm_error("GPIO_PKG", "\nWrong OP for this getPin task")
      return;
    end

    if (!(_seq.randomize() with {
      op_type           == _op_type;
      pin_name_i.size() == _pin_name_i.size();
      foreach(_pin_name_i[i])
        pin_name_i[i]   == _pin_name_i[i];
      pin_name_o.size() == _pin_name_o.size();
      foreach(_pin_name_o[i])
        pin_name_o[i]   == _pin_name_o[i];
      duration          == 1;
    })) `uvm_error("GPIO_PKG", "\nRandomization failed");

    _seq.start(_sqcr);

    _rd_data = new [_pin_name_i.size() + _pin_name_o.size()];// (_seq.rsp.gpio_in);

    foreach(_pin_name_i[i]) begin
      _rd_data[i] = _seq.rsp.gpio_in[i];
    end

    foreach(_pin_name_o[i]) begin
      _rd_data[i + _pin_name_i.size()] = _seq.rsp.gpio_out[i];
    end

    `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Get OP:\n",
                             "-------------------------------------------------\n",
                             "OP Type  : %s\n",
                             "Pin Name : %s\n",
                             "Pin Num  : %s\n",
                             "Value    : %s\n"}
                             , _op_type.name(), printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                             , printPinEnumIO(_pin_name_i, _pin_name_o, 1), printPinVal(_rd_data)
    ), UVM_LOW);

  endtask : getPin

endpackage : GpioAgentPkg

`endif
