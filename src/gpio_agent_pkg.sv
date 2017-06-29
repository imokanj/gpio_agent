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
// System section
//==============================================================================

//******************************************************************************
// Constants, classes, types, etc.
//******************************************************************************

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
  import GpioAgentUserPkg::*; // user settings

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
  `include "agent/gpio_sequencer.svh"
  `include "agent/gpio_driver.svh"
  `include "agent/gpio_monitor.svh"
  `include "agent/gpio_agent.svh"

//******************************************************************************
// Functions/Tasks
//******************************************************************************

  function automatic GpioAgentCfg configGpioAgent(
    input uvm_active_passive_enum _is_active    = UVM_PASSIVE,
    input bit                     _is_x_z_check = 1'b0
  );
    GpioAgentCfg cfg = GpioAgentCfg::type_id::create("cfg");

    cfg.is_active    = _is_active;
    cfg.is_x_z_check = _is_x_z_check;
    return cfg;
  endfunction : configGpioAgent

  //----------------------------------------------------------------------------

  class PrintEnum #(type T = gpio_input_t);
    static function automatic string printPinEnum(T a [], bit is_val);
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
    endfunction : printPinEnum
  endclass : PrintEnum

  //----------------------------------------------------------------------------

  function automatic string printPinEnumIO(
    gpio_input_t  a []  ,
    gpio_output_t b []  ,
    bit           is_val
  );
    string    str    = "";

    if (a.size() != 0) begin
      str = PrintEnum #(gpio_input_t)::printPinEnum(a, is_val);
      if (b.size() != 0) begin
        str = {str, ", "};
      end
    end

    if (b.size() != 0) begin
      str = {str, PrintEnum #(gpio_output_t)::printPinEnum(b, is_val)};
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

  function automatic void setXZCheck(
    input GpioAgent _agt         ,
    input bit       _is_x_z_check
  );

    string _status = "DISABLED";

    if (_agt == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent handle is NULL\n")
      return;
    end

    if (_is_x_z_check) begin _status = "ENABLED"; end

    _agt.cfg.is_x_z_check = _is_x_z_check;

    `uvm_info("GPIO_PKG", $sformatf({"\nGPIO setXZCheck:\n",
                             "-------------------------------------------------\n",
                             "Setting for 'X' and 'Z' checking has changed\n",
                             "GPIO Agent Path   : %s\n",
                             "'X' and 'Z' check : %s\n"}
                             , _agt.get_full_name(), _status
    ), UVM_LOW)
  endfunction : setXZCheck

  //----------------------------------------------------------------------------

  // write specified values to DUT inputs
  task automatic setPin(
    input  bit                _print_info = 1'b1,
    input  uvm_sequencer_base _sqcr             ,
    input  op_type_t          _op_type          ,
    input  gpio_output_t      _pin_name_o []    ,
    input  logic              _wr_data    []    ,
    input  bit [31:0]         _delay = 0          // ignored for WR_SYNC and WR_ASYNC
  );

    GpioSetPinSequence _seq;
    string             _delay_str;

    if (_op_type == WR_SYNC || _op_type == WR_ASYNC) begin
      if (_sqcr == null) begin
        `uvm_error("GPIO_PKG", "\nGPIO Agent sequencer handle is NULL\n")
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
      if (_pin_name_o.size() > W_OUT || _pin_name_o.size() < 1) begin
        `uvm_error("GPIO_PKG", {"\nOperation ignored.\nNumber of specified pins ",
                                "is greater than number of actual pins, or is less than one\n"})
        return;
      end

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
    })) `uvm_error("GPIO_PKG", "\nRandomization failed\n")

    if (_print_info) begin
      `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Set OP:\n",
                               "-------------------------------------------------\n",
                               "OP Type     : %s\n",
                               "Pin Name(s) : %s\n",
                               "Pin Num(s)  : %s\n",
                               "Value(s)    : %s\n"}
                               , _op_type.name()
                               , PrintEnum #(gpio_output_t)::printPinEnum(_pin_name_o, 0)
                               , PrintEnum #(gpio_output_t)::printPinEnum(_pin_name_o, 1)
                               , printPinVal(_wr_data)
      ), UVM_LOW)
    end

    _seq.start(_sqcr);

  endtask : setPin

  //----------------------------------------------------------------------------

  // keep DUT input signals asserted to specified values for some duration, after an initial delay
  task automatic setPinWindow(
    input  bit                _print_info = 1'b1,
    input  uvm_sequencer_base _sqcr             ,
    input  op_type_t          _op_type          ,
    input  gpio_output_t      _pin_name_o    [] ,
    input  logic              _wr_data_start [] ,
    input  logic              _wr_data_end   [] ,
    input  bit [31:0]         _delay    = 0     ,
    input  bit [31:0]         _duration = 1
  );

    string _dur_type;

    if (_sqcr == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent sequencer handle is NULL\n")
      return;
    end

    if (_op_type != WR_WIN_SYNC && _op_type != WR_WIN_ASYNC) begin
      `uvm_error("GPIO_PKG", "\nWrong OP for this setPinWindow task\n")
      return;
    end

    if (_pin_name_o.size() > W_OUT || _pin_name_o.size() < 1) begin
      `uvm_error("GPIO_PKG", {"\nOperation ignored.\nNumber of specified pins ",
                              "is greater than number of actual pins, or is less than one\n"})
      return;
    end

    if (_pin_name_o.size() != _wr_data_start.size() || _pin_name_o.size() != _wr_data_end.size()) begin
      `uvm_error("GPIO_PKG", "\nNumber of specified pin names is different from number of specified values\n")
      return;
    end

    // duration cannot be less than 1 clock cycle or 1 ns
    if (_duration < 1) begin
      `uvm_warning("GPIO_PKG", {"\nMinimum duration is 1 clock cycle or 1 ns",
                                "\nParameter _duration automatically set to 1\n"}
      )
      _duration = 1;
    end

    if (_print_info) begin
      if (_op_type == WR_WIN_SYNC) begin
        _dur_type = "clock(s)";
      end else begin
        _dur_type = "ns";
      end

      `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Window OP:\n",
                               "-------------------------------------------------\n",
                               "OP Type        : %s\n",
                               "Pin Name(s)    : %s\n",
                               "Pin Num(s)     : %s\n",
                               "Delay          : %0d %s\n",
                               "Start Value(s) : %s\n",
                               "Duration       : %0d %s\n",
                               "End Value(s)   : %s\n"}
                               , _op_type.name()
                               , PrintEnum #(gpio_output_t)::printPinEnum(_pin_name_o, 0)
                               , PrintEnum #(gpio_output_t)::printPinEnum(_pin_name_o, 1)
                               , _delay, _dur_type
                               , printPinVal(_wr_data_start), _duration, _dur_type
                               , printPinVal(_wr_data_end)
      ), UVM_LOW)
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
    input  bit                _print_info = 1'b1 ,
    input  uvm_sequencer_base _sqcr              ,
    input  op_type_t          _op_type           ,
    input  gpio_input_t       _pin_name_i [] = {},
    input  gpio_output_t      _pin_name_o [] = {},
    output logic              _rd_data    []
  );

    GpioGetPinSequence _seq;

    if (_sqcr == null) begin
      `uvm_error("GPIO_PKG", "\nGPIO Agent sequencer handle is NULL\n")
      return;
    end

    if (_pin_name_i.size() > W_IN) begin
      `uvm_error("GPIO_PKG", {"\nOperation ignored.Number of specified input pins ",
                              "is greater than number of actual input pins\n"})
      return;
    end

    if (_pin_name_o.size() > W_OUT) begin
      `uvm_error("GPIO_PKG", {"\nOperation ignored.Number of specified output pins ",
                              "is greater than number of actual output pins\n"})
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
    })) `uvm_error("GPIO_PKG", "\nRandomization failed\n")

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
                               "OP Type     : %s\n",
                               "Pin Name(s) : %s\n",
                               "Pin Num(s)  : %s\n",
                               "Value(s)    : %s\n"}
                               , _op_type.name()
                               , printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                               , printPinEnumIO(_pin_name_i, _pin_name_o, 1)
                               , printPinVal(_rd_data)
      ), UVM_LOW)
    end

  endtask : getPin

  //----------------------------------------------------------------------------

  // read and compare specified DUT pin values
  task automatic getCompare(
    input  bit                _print_info = 1'b1  ,
    input  uvm_sequencer_base _sqcr               ,
    input  op_type_t          _op_type            , // same as for getPin task
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

    _all_user_values = new [_user_data_i.size() + _user_data_o.size()] (_user_data_i);
    foreach(_user_data_o[i]) begin
      _all_user_values[i + _user_data_i.size()] = _user_data_o[i];
    end

    if (_status_str == "PASS") begin
      if (_print_info) begin
        `uvm_info("GPIO_PKG", $sformatf({"\nGPIO Compare OP:\n",
                                         "-------------------------------------------------\n",
                                         "OP Type       : %s\n",
                                         "Pin Name(s)   : %s\n",
                                         "Pin Num(s)    : %s\n",
                                         "User Value(s) : %s\n",
                                         "Read Value(s) : %s\n",
                                         "Status        : %s\n"}
                                         , _op_type.name()
                                         , printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                                         , printPinEnumIO(_pin_name_i, _pin_name_o, 1)
                                         , printPinVal(_all_user_values)
                                         , printPinVal(_rd_data), _status_str
        ), UVM_LOW)
      end
    end else begin
      `uvm_error("GPIO_PKG", $sformatf({"\nGPIO Compare OP:\n",
                                       "-------------------------------------------------\n",
                                       "OP Type       : %s\n",
                                       "Pin Name(s)   : %s\n",
                                       "Pin Num(s)    : %s\n",
                                       "User Value(s) : %s\n",
                                       "Read Value(s) : %s\n",
                                       "Status        : %s\n"}
                                       , _op_type.name()
                                       , printPinEnumIO(_pin_name_i, _pin_name_o, 0)
                                       , printPinEnumIO(_pin_name_i, _pin_name_o, 1)
                                       , printPinVal(_all_user_values)
                                       , printPinVal(_rd_data), _status_str
      ))
    end

  endtask : getCompare

endpackage : GpioAgentPkg

`endif
