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
    RST,
    ADDR_SPACE_1,
    ADDR_SPACE_0,
    LAST
  } gpio_output_t;
  gpio_output_t gpio_output_list;

  // if your simulator does not support built-in functions in constant expressions
  // please manually count the number of input and output pins and write them here,
  // and delete the *.num() calls
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
    WR_ASYNC,
    WR_WIN_SYNC,
    WR_WIN_ASYNC
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
    string    str = "";
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
    input  bit                _print_info = 1'b1,
    input  uvm_sequencer_base _sqcr,
    input  op_type_t          _op_type,
    input  gpio_output_t      _pin_name_o [],
    input  logic              _wr_data    [],
    input  bit [31:0]         _delay = 0      // ignored for WR_SYNC and WR_ASYNC
  );

    GpioSetPinSequence _seq;
    string             _delay_str;

    if (_op_type == WR_SYNC || _op_type == WR_ASYNC) begin
      if (_sqcr == null) begin
        `uvm_error("GPIO_PKG", "\nGPIO Agent handle is NULL\n")
        return;
      end
    end

    if (_op_type == WR_SYNC     || _op_type == WR_ASYNC ||
        _op_type == WR_WIN_SYNC || _op_type == WR_WIN_ASYNC
    ) begin
      _seq = GpioSetPinSequence::type_id::create("set_pin_seq");
    end else begin
      `uvm_error("GPIO_PKG", "\nWrong OP for this setPin task\n")
      return;
    end

    if (_op_type == WR_SYNC || _op_type == WR_ASYNC) begin
      if (_pin_name_o.size() != _wr_data.size()) begin
        `uvm_error("GPIO_PKG", "\nNumber of specified pin names is different than number of specified values\n")
        return;
      end
    end

    if (!(_seq.randomize() with {
      op_type           == _op_type;
      pin_name_o.size() == _pin_name_o.size();
      foreach(_pin_name_o[i])
        pin_name_o[i]   == _pin_name_o[i];
      gpio_out.size()   == _wr_data.size();
      foreach(_wr_data[i])
        gpio_out[i]     == _wr_data[i];
      if (_op_type == WR_SYNC || _op_type == WR_ASYNC)
        delay             == 0;
      else
        delay             == _delay;
    })) `uvm_error("GPIO_PKG", "\nRandomization failed\n");

    if (_print_info) begin
      `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Set OP:\n",
                               "-------------------------------------------------\n",
                               "OP Type     : %s\n",
                               "Pin Name    : %s\n",
                               "Pin Num     : %s\n",
                               "Value       : %s\n"}
                               , _op_type.name(), printPinEnumO(_pin_name_o, 0), printPinEnumO(_pin_name_o, 1), printPinVal(_wr_data)
      ), UVM_LOW);
    end

    _seq.start(_sqcr);

  endtask : setPin

  //----------------------------------------------------------------------------

  // keep DUT input signals asserted to specified values for some duration, after an initial delay
  task automatic setPinWindow(
    input  bit                _print_info = 1'b1,
    input  uvm_sequencer_base _sqcr,
    input  op_type_t          _op_type,
    input  gpio_output_t      _pin_name_o    [],
    input  logic              _wr_data_start [],
    input  logic              _wr_data_end   [],
    input  bit [31:0]         _delay    = 0,
    input  bit [31:0]         _duration = 0
  );

    if (_sqcr == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent handle is NULL\n")
      return;
    end

    if (_op_type != WR_WIN_SYNC && _op_type != WR_WIN_SYNC) begin
      `uvm_error("GPIO_PKG", "\nWrong OP for this setPinWindow task\n")
      return;
    end

    if (_pin_name_o.size() != _wr_data_start.size() || _pin_name_o.size() != _wr_data_end.size()) begin
      `uvm_error("GPIO_PKG", "\nNumber of specified pin names is different from number of specified values\n")
      return;
    end

    if (_op_type == WR_WIN_ASYNC) begin
      if (_duration == 0) begin
        _duration = 1; // minimum duration for asynchronous window write is 1 ns
      end
    end

    setPin(
      ._print_info(1'b0),
      ._sqcr      (_sqcr),
      ._op_type   (_op_type),
      ._pin_name_o(_pin_name_o),
      ._wr_data   (_wr_data_start),
      ._delay     (_delay)             // only affects synchronous writes
    );

    setPin(
      ._print_info(1'b0),
      ._sqcr      (_sqcr),
      ._op_type   (_op_type),
      ._pin_name_o(_pin_name_o),
      ._wr_data   (_wr_data_end),
      ._delay     (_delay + _duration) // only affects synchronous writes
    );

  endtask : setPinWindow


  //----------------------------------------------------------------------------

  // read specified DUT pin values
  task automatic getPin(
    input  bit                _print_info = 1'b1,
    input  uvm_sequencer_base _sqcr,
    input  op_type_t          _op_type,
    input  gpio_input_t       _pin_name_i [] = {},
    input  gpio_output_t      _pin_name_o [] = {},
    output logic              _rd_data    []
  );

    GpioGetPinSequence _seq;

    if (_sqcr == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent handle is NULL\n")
      return;
    end

    if (_pin_name_i.size() == 0 && _pin_name_o.size() == 0) begin
      `uvm_error("GPIO_PKG", "\nNo input or output pins specified\n")
      return;
    end

    if (_op_type == RD_SYNC || _op_type == RD_ASYNC) begin
      _seq = GpioGetPinSequence::type_id::create("get_pin_seq");
    end else begin
      `uvm_error("GPIO_PKG", "\nWrong OP for this getPin task\n")
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
      delay             == 0;
    })) `uvm_error("GPIO_PKG", "\nRandomization failed\n");

    _seq.start(_sqcr);

    _rd_data = new [_pin_name_i.size() + _pin_name_o.size()];// (_seq.rsp.gpio_in);

    foreach(_pin_name_i[i]) begin
      _rd_data[i] = _seq.rsp.gpio_in[i];
    end

    foreach(_pin_name_o[i]) begin
      _rd_data[i + _pin_name_i.size()] = _seq.rsp.gpio_out[i];
    end

    if (_print_info) begin
      `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Get OP:\n",
                               "-------------------------------------------------\n",
                               "OP Type  : %s\n",
                               "Pin Name : %s\n",
                               "Pin Num  : %s\n",
                               "Value    : %s\n"}
                               , _op_type.name(), printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                               , printPinEnumIO(_pin_name_i, _pin_name_o, 1), printPinVal(_rd_data)
      ), UVM_LOW);
    end

  endtask : getPin

  //----------------------------------------------------------------------------

  // read and compare specified DUT pin values
  task automatic getCompare(
    input  bit                _print_info = 1'b1,
    input  uvm_sequencer_base _sqcr,
    input  op_type_t          _op_type,               // same as for getPin task
    input  gpio_input_t       _pin_name_i  [] = {},
    input  gpio_output_t      _pin_name_o  [] = {},
    input  logic              _user_data_i [] = {},
    input  logic              _user_data_o [] = {}
  );

    string _status_str         = "PASS";
    logic  _rd_data         [];
    logic  _all_user_values [];
    
    if (_user_data_i.size() == 0 && _user_data_o.size() == 0) begin
       `uvm_error("GPIO_PKG", "\nNo expected pin values specified\n")
       return;
    end
    
    if (_pin_name_i.size() != _user_data_i.size() || _pin_name_o.size() != _user_data_o.size()) begin
      `uvm_error("GPIO_PKG", "\nNumber of specified pin names is different from number of specified values\n")
      return;
    end
    
    getPin(
      ._print_info(1'b0),
      ._sqcr      (_sqcr),
      ._op_type   (_op_type),
      ._pin_name_i(_pin_name_i),
      ._pin_name_o(_pin_name_o),
      ._rd_data   (_rd_data)
    );
        
    foreach(_user_data_i[i]) begin
      if (_user_data_i[i] != _rd_data[i]) begin
        _status_str = "FAIL";
        break;
      end
    end

    if (_status_str == "PASS") begin
      foreach(_user_data_o[i]) begin
        if (_rd_data[i + _user_data_i.size()] != _user_data_o[i]) begin
          _status_str = "FAIL";
          break;
        end
      end
    end
    
    if (_print_info) begin
      _all_user_values = new [_user_data_i.size() + _user_data_o.size()] (_user_data_i);
      foreach(_user_data_o[i]) begin
        _all_user_values[i + _user_data_i.size()] = _user_data_o[i];
      end
      
      if (_status_str == "PASS") begin
        `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Compare OP:\n",
                                         "-------------------------------------------------\n",
                                         "OP Type     : %s\n",
                                         "Pin Name    : %s\n",
                                         "Pin Num     : %s\n",
                                         "User Values : %s\n",
                                         "Read Values : %s\n",
                                         "Status      : %s\n"}
                                         , _op_type.name(), printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                                         , printPinEnumIO(_pin_name_i, _pin_name_o, 1), printPinVal(_all_user_values)
                                         , printPinVal(_rd_data), _status_str
        ), UVM_LOW);
      end else begin
        `uvm_error("GPIO_PKG", $sformatf({"\nGPIO Compare OP:\n",
                                         "-------------------------------------------------\n",
                                         "OP Type       : %s\n",
                                         "Pin Name(s)   : %s\n",
                                         "Pin Num(s)    : %s\n",
                                         "User Value(s) : %s\n",
                                         "Read Value(s) : %s\n",
                                         "Status        : %s\n"}
                                         , _op_type.name(), printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                                         , printPinEnumIO(_pin_name_i, _pin_name_o, 1), printPinVal(_all_user_values)
                                         , printPinVal(_rd_data), _status_str
        ));
      end
    end

  endtask : getCompare

endpackage : GpioAgentPkg

`endif
