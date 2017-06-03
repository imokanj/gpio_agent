<h1><span style="font-size: 18pt;">UVM General Purpose I/O Agent</span></h1>
<hr />
<p><span style="font-size: 12pt;">This repository contains an implementation of a GPIO agent, written in UVM 1.1d and SystemVerilog-2012.</span><br /><span style="font-size: 12pt;">Also, a complete user guide with the agent description, instructions and usage, is provided.</span><br /><br /><span style="font-size: 12pt;">The main features of the GPIO agent are:</span></p>
<ul>
<li><span style="font-size: 12pt;">driving individual DUT input pins</span></li>
<li><span style="font-size: 12pt;">reading values from DUT pins connected to the GPIO interface</span></li>
<li><span style="font-size: 12pt;">reading pin values and comparing them to user specified expected values</span></li>
<li><span style="font-size: 12pt;">monitoring the interface for unknown or high impedance &nbsp;logic values</span></li>
<li><span style="font-size: 12pt;">creating simple arbitrary protocols using the GPIO API (such as SPI, I2C, etc)</span></li>
</ul>

![sha3_tb.png](https://s30.postimg.org/bv43kvqu9/this.png)

<p class="western"><em><span style="font-size: 10pt;">Figure &ndash; GPIO agent example use case</span></em><br /><br /><span style="font-size: 12pt;">For additional information please refer to the GPIO agent user manual.</span></p>
