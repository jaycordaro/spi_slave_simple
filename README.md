# spi_slave_simple
Simple System Verilog implementation of SPI Slave

## Configuration
  The MSB is the Read/Write bit.  
    Write = 0, Read = 1
  
  This is followed by an address field, followed by a data field.  
  MISO is only active during the data field.
  
  Ther packetsize, header, and payload size are parameteters.  Defaults
  
  	parameter int pktsz = 16,  //  size of SPI packet
	parameter int header = 8,  // size of header
	parameter int payload = 8, // size of payload
	parameter int addrsz = 7   // size of SPI Address Space

## Validation 
  
  this design was tested on an Intel MAX 10 FPGA 10M50 Evaluation Kit Board
