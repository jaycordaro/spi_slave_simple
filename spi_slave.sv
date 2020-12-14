/*  SPI Slave Interface
    Copyright 2020 Jay Cordaro

    Redistribution and use in source and binary forms, with or without modification, 
    are permitted provided that the following conditions are met:
    1. Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS" 
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
    OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/* Description: Simple SPI Slave for CPOL==0/CPHA==0 
   MSB is a Read/Write bit (1== Read, 0== Write) followed by a addrsz (default 7-bit) address field, and by a (default 8-bit) payload field.
   if RW bit is set, the interface will return a read of the register on MISO addressed by the address field.  If RW bit is not set, it will write 
   the contents of the payload field to the register addressed by the address field.
*/
module spi_slave
		#(
			parameter int pktsz = 16,  //  size of SPI packet
			parameter int header = 8,  // size of header
			parameter int payload = 8, // size of payload
			parameter int addrsz = 7   // size of SPI Address Space
		)
		(input logic clk,     // system clock
		 input logic reset_n, // system reset
		// SPI I/O
		 input logic SCLK,
		 input logic SSB,
		 input logic MOSI,
		 output logic MISO,
		// 
		 input  logic [payload-1:0] tx_d, // data to transmit to the master on MISO
		 output logic txdv,				
		 output logic [addrsz-1:0] addr,  // address to slave from master on MOSI
		 output logic addr_dv,
		 output logic [payload-1:0] rx_d, // data rx from master on MOSI
		 output logic rxdv             // rx data valid
		 //output logic rxer				// rx error 
);            

logic [2:0] sync_sclk;
logic [2:0] sync_ss;
logic [1:0] sync_mosi;
logic [3:0] bitcnt;
logic rw;

always_ff @ (posedge clk or negedge reset_n)
    begin
        if (~reset_n)
            begin
                sync_sclk <= 3'b000;
                sync_ss   <= 3'b111;
                sync_mosi <= 2'b00;
            end
        else
            begin
                sync_sclk <= {sync_sclk[1:0], SCLK};
                sync_ss   <= {sync_ss[1:0], SSB};
                sync_mosi <= {sync_mosi[0], MOSI};
            end
    end

logic sync_sclk_re; 
logic sync_sclk_fe;
logic spi_start; 
logic spi_end; 
logic spi_active;
logic d_i;
logic [7:0] d_o;

assign sync_sclk_fe = (sync_sclk[2:1]==2'b10) ? 1'b1 : 1'b0;  // falling edge
assign sync_sclk_re = (sync_sclk[2:1]==2'b01) ? 1'b1 : 1'b0;  // rising edge

assign spi_start = (sync_ss[2:1]==2'b10) ? 1'b1 : 1'b0;         // ss -- active low 
assign spi_end   =   (sync_ss[2:1]==2'b01) ? 1'b1 : 1'b0;       // transaction ends 
assign spi_active = ~sync_ss[1];
  
assign d_i = sync_mosi[1];

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n || spi_start)
		bitcnt <= 0;
	else if (spi_active && sync_sclk_re)
		bitcnt <= bitcnt + 1;
end

//assign rw = (bitcnt == 0 && spi_active && sync_sclk_re && d_i == 1) ? 1'b1 : 1'b0;

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n || spi_start || spi_end)
		rw <= 0;
	else if (spi_active && sync_sclk_re && bitcnt == 1'b0)
		rw <= d_i;
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n || spi_start)
		addr <= 0;
	else if (spi_active && sync_sclk_re && bitcnt > 0 && bitcnt <= 7)
		addr <= {addr[5:0], d_i };
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n || spi_start)
		d_o <= tx_d;
	else if (spi_active && sync_sclk_re && bitcnt > header - 1 && rw)
		begin
			d_o <= {d_o[6:0], 1'b0};
		end
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n || spi_start)
		rx_d <= 0;
	else if (spi_active && sync_sclk_re && bitcnt > header - 1 && ~rw)
		rx_d = {rx_d[6:0], d_i};
end

assign MISO = (bitcnt > header - 1  && rw) ? d_o[7] : 1'b0;

assign addr_dv = (bitcnt > header ) ? 1'b1 : 1'b0;

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n || spi_start || spi_end)
		rxdv <= 0;
	else if (bitcnt == pktsz -1 && sync_sclk_re  && ~rw)
		rxdv <= 1'b1;
end

assign txdv = (bitcnt == pktsz -1 && rw == 1) ? 1'b1 : 1'b0;

endmodule : spi_slave
