// spi_tb
// jay cordaro
//
// Testbench for spi.sv module

`timescale 1ns / 100ps

module spi_tb();

logic clk;
logic reset_n;

logic SCLK;
logic SSB;
logic MOSI;
logic MISO;
logic [7:0] tx_d;
logic [6:0] addr;
logic addr_dv;
logic [7:0] rx_d;
logic rxdv;
logic [7:0] check_data;

spi_slave #(
  .pktsz   ( 16 ),
  .header  ( 8 ),
  .payload ( 8 ),
  .addrsz  ( 7 )
  ) 
  spi_slave_inst  (
  .clk     	(clk),
  .reset_n 	(reset_n),
  .SCLK	   	(SCLK),
  .SSB		(SSB),
  .MOSI		(MOSI),
  .MISO		(MISO),
  .tx_d		(tx_d),
  .txdv		(txdv),
  .addr 	(addr),
  .addr_dv	(addr_dv),
  .rx_d		(rx_d),
  //.rxer		(rxer)
  .rxdv		(rxdv)
			);
		

  	always #10 clk = ~clk;  

task do_spi_read;
	input [7:0] from_host;
	input [7:0] data_to_host;
	int i;
	
	begin
	#1 SSB =1'b1;
       MOSI = 1'b0;
	#5 SCLK = 1'b0;
	   check_data = 0;
	#40 SSB = 1'b0;
	tx_d=data_to_host;
		for (i=0;i<8;i++)
		begin
		    if (i==0)
			    MOSI = 1'b0;
			#55 SCLK = 1'b0;
			MOSI = from_host[7-i];
			#55 SCLK = 1'b1;
		end
		for (i=0;i<=7;i++)
		begin
			#55 SCLK = 1'b0;
			#55 SCLK = 1'b1;
			check_data = {check_data[6:0], MISO};
		end
		
	if (check_data != data_to_host)
		$display("ERROR: expected %b, got %b", data_to_host, check_data);
	else
		$display("Success: expected %b, got %b", data_to_host, check_data);
	MOSI=1'b0;
	//	check_data = {check_data[6:0], MISO};
	#50 SCLK=1'b0;
		MOSI=1'b0;
	#50 SCLK=1'b0;
	#50 SSB=1'b1;
	#50 SSB=1'b1;
	end
endtask

task do_spi_write;
	input [15:0] from_host;

	int i;
	
	begin
	#1 SSB =1'b1;
       MOSI = 1'b0;
	#5 SCLK = 1'b0;
	   check_data = 0;
	#40 SSB = 1'b0;

		for (i=0;i<8;i++)
		begin
		    if (i==0)
			    MOSI = 1'b0;
			#55 SCLK = 1'b0;
			MOSI = from_host[15-i];
			check_data = {check_data[6:0], MOSI};
			#55 SCLK = 1'b1;
		end
		
		if (addr != check_data[7:1])
			$display("ERROR: expected %b, got %b", check_data[7:1], addr);
		else
			$display("Success: expected %b, got %b", check_data[7:1], addr);
		check_data = 0;
		for (i=8;i<=15;i++)
		begin
			#55 SCLK = 1'b0;
			#55 SCLK = 1'b1;
			MOSI = from_host[15-i];
			check_data = {check_data[6:0], MOSI};
			#55 SCLK = 1'b1;
			
		end
	
	MOSI=1'b0;
	//	check_data = {check_data[6:0], MISO};
	#50 SCLK=1'b0;
		
	if (rx_d != from_host[7:0])
				$display("ERROR: expected %b, got %b", from_host[7:0], rx_d);
		else
			$display("Success: expected %b, got %b", from_host[7:0], rx_d);
		MOSI=1'b0;
	#50 SCLK=1'b0;
	#50 SSB=1'b1;
	#50 SSB=1'b1;
	end
endtask


	
  initial begin   // 
  
  
 // create 50MHz clock
    $dumpfile("clk_tb.vcd");
	$display($time, " << Starting the Simulation >>");
    $dumpvars;
	#3 clk = 1'b0;
	
	#4 reset_n = 0;
	#10 MOSI=1'b0;
	#40 reset_n = 1;
	$display($time, " << spi_read >>");
	do_spi_read(8'b1010_1010, 8'b1000_0001);

	MOSI= 1'b1;
	#50
	$display($time, " << spi_read >>");
	do_spi_read(8'b1100_0011, 8'b0011_1100);  // check if 
	MOSI= 1'b1;
	#50
	$display($time, " << spi_read >>");
	do_spi_read(8'b1100_1100, 8'b1100_1100);
	MOSI= 1'b1;
	
	#50
	$display($time, " << spi_write >>");
	do_spi_write(16'b0100_1100_1100_1100);
	MOSI= 1'b1;
	
	#50
	$display($time, " << spi_write >>");
	do_spi_write(16'b0111_0001_1100_0111);
	MOSI= 1'b1;

	end
endmodule