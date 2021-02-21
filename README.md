# spi_slave_simple
Simple System Verilog implementation of SPI Slave

## Configuration
  The MSB is the Read/Write bit.  
    Write = 0, Read = 1
  
  This is followed by an address field, followed by a data field.  
  MISO is only active during the data field.
  
  The packetsize, header, and payload size are parameteters which can be changed.  Defaults:
  
  	parameter int pktsz = 16,  //  size of SPI packet
	parameter int header = 8,  // size of header
	parameter int payload = 8, // size of payload
	parameter int addrsz = 7   // size of SPI Address Space


Interface Ports
-------------

### spi_slave.sv
<table>
    <tr>
      <td>Name</td> 
      <td>Type</td>
      <td>Width</td>
      <td>Description</td>
    </tr>
  <tr>
    <td>clk</td>
    <td>Input</td>
    <td>1</td>
    <td>System Clock.  SCLK is oversampled.  clk must be > 4x SCLK.</td>
  </tr>
    <tr>
    <td>reset_n</td>
    <td>Input</td>
    <td>1</td>
    <td>asynchronous reset (active low)</td>
  </tr>
     <tr>
    <td>SCLK</td>
    <td>Input</td>
    <td>1</td>
    <td>Serial Clock Input for SPI</td>
  </tr>
    <tr>
    <td>SSB</td>
    <td>Input</td>
    <td>1</td>
    <td>SPI Select</td>
  </tr>
      <tr>
    <td>MOSI</td>
    <td>Input</td>
    <td>1</td>
    <td>Master Out Slave In</td>
  </tr>
        <tr>
    <td>MISO</td>
    <td>Output</td>
    <td>1</td>
    <td>Master In Slave Out</td>
  </tr>
	<tr>
		<td>tx_d</td>
		<td>Input</td>
		<td>1 </td>
		<td>Data to transmit to host on MISO</td>
	</tr>
	<tr>
		<td>tx_en</td>
		<td>Input</td>
		<td>1</td>
		<td></td>
	</tr>
	<tr>
		<td>addr</td>
		<td>Output</td>
		<td>addrsz</td>
		<td>register/memory for controller to access.  Parameter.  Default is 7 bits</td>
	</tr>
	<tr>
		<td>addr_dv</td>
		<td>Output</td>
		<td>1</td>
		<td>Signals when address is valid</td>
	</tr>
	<tr>
		<td>rx_d</td>
		<td>Output</td>
		<td>payload</td>
		<td>Data bits received from host during payload part of SPI frame.  Parameter, 8 bits default.</td>
	</tr>
	<tr>
		<td>rx_dv</td>
		<td>Output</td>
		<td>1</td>
		<td>Signals when rx_d is valid.</td>
	</tr>
	<tr>
		<td>rw_out</td>
		<td>Output</td>
		<td>1</td>
		<td><pre>Read/Write Out.  Signals whether frame is a read transaction or write transaction.  
	RW== 0 means send data from Host (master) to Controller (slave).
	RW== 1 means request data from controller</pre></td>
	</tr>
</table>

## Verification and Test

Simulation -- testbench checked using ModelSim - INTEL FPGA STARTER EDITION 2020.1
Revision: 2020.02

## Validation 
  
  this design was tested on an Intel MAX 10 FPGA 10M50 Evaluation Kit Board with a Raspberry Pi acting as SPI Host. See validation directory. 
