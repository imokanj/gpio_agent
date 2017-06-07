/* AUTHOR      : Ivan Mokanj
 * START DATE  : 2017
 * LICENSE     : LGPLv3
 *
 * DESCRIPTION : GPIO sequencer
 */

class GpioAgentSequencer extends uvm_sequencer #(GpioItem);
  `uvm_component_utils(GpioAgentSequencer)
  
  // Methods
  function new(string name = "GpioAgentSequencer", uvm_component parent);
    super.new(name, parent);
  endfunction : new
    
  extern virtual function void handle_reset(uvm_phase phase);
  
endclass : GpioAgentSequencer

//------------------------------------------------------------------------------

  function void GpioAgentSequencer::handle_reset(uvm_phase phase);
    uvm_objection objection = phase.get_objection();
    int objection_cnt;
    
    stop_sequences();
    
    objection_cnt = objection.get_objection_count(this);
    
    if (objection_cnt > 0) begin
      objection.drop_objection(this, $sformatf("Dropping %0d objections at reset", objection_cnt), objection_cnt);
    end
    
    start_phase_sequence(phase);
  endfunction : handle_reset
