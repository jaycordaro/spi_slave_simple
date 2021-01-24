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
		input  logic [payload-1:0] tx_d, 	// data to transmit to the master on MISO
		input  logic tx_en,				    // tx enable, when 
		output logic [addrsz-1:0] addr,  	// address to slave from master on MOSI
		output logic addr_dv,
		output logic [payload-1:0] rx_d, 	// data rx from master on MOSI
		output logic rxdv,           		// rx data valid
		output logic rw_out				    /* read/write out (1st bit of transaction): 
											0 == send data from master to the slave
											1 == request data from slave */
		);            

logic [2:0] sync_sclk;
logic [2:0] sync_ss;
logic [1:0] sync_mosi;
logic [1:0] sync_tx_en;
logic [3:0] bitcnt;
logic rw;

logic mosi;
logic sclk;
logic ssb;

assign mosi = MOSI;
assign sclk = SCLK;
assign ssb = SSB;

always_ff @ (posedge clk or negedge reset_n)
    begin
        if (~reset_n)
            begin
                sync_sclk <= 3'b000;
                sync_ss   <= 3'b111;
                sync_mosi <= 2'b00;
				sync_tx_en<= 2'b00;
            end
        else
            begin
                sync_sclk <= {sync_sclk[1:0], sclk};
                sync_ss   <= {sync_ss[1:0], ssb};
                sync_mosi <= {sync_mosi[0], mosi};
				sync_tx_en<= {sync_tx_en[0], tx_en};
            end
    end

logic sync_sclk_re; 
logic sync_sclk_fe;
logic tx_en_re;
logic spi_start; 
logic spi_end; 
logic spi_active;
logic d_i;
logic [7:0] d_o;

assign sync_sclk_fe = (sync_sclk[2:1]==2'b10) ? 1'b1 : 1'b0;  	// falling edge
assign sync_sclk_re = (sync_sclk[2:1]==2'b01) ? 1'b1 : 1'b0;  	// rising edge

assign spi_start = (sync_ss[2:1]==2'b10) ? 1'b1 : 1'b0;         // ss -- active low 
assign spi_end   =   (sync_ss[2:1]==2'b01) ? 1'b1 : 1'b0;       // transaction ends 
assign spi_active = ~sync_ss[1];

assign tx_en_re = (sync_tx_en==2'b01) ? 1'b1 : 1'b0;			// tx_en rising edge
  
assign d_i = sync_mosi[1];

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n)
		bitcnt <= 4'b0000;
	else if (spi_start)
		bitcnt <= 4'b0000;
	else if (spi_active && sync_sclk_re)
		bitcnt <= bitcnt + 1;
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n)
		rw <= 1'b0;
	else if (spi_start || spi_end)
		rw <= 1'b0;
	else if (spi_active && sync_sclk_re && bitcnt == 1'b0)
		rw <= d_i;
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n )
		addr <= 7'b000_0000;
	else if (spi_start)
		addr <= 7'b000_0000;
	else if (spi_active && sync_sclk_re && bitcnt > 0 && bitcnt <= 7)
		addr <= {addr[5:0], d_i };
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n)
		begin
			d_o <= 8'b0000_0000;
		end
	else if (tx_en_re)
		begin 
			d_o <= tx_d;
		end
	else if (spi_active && sync_sclk_fe && tx_en)
		begin
			d_o <= {d_o[6:0], 1'b0};
		end
	else if (~tx_en)
			d_o <= 8'b0000_0000;
end

assign MISO = (bitcnt > header - 1  && rw) ? d_o[7] : 1'b0;
	
always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n)
		rx_d <= 8'b0000_0000;
	else if (spi_start)
		rx_d <= 8'b0000_0000;
	else if (spi_active && sync_sclk_re && bitcnt > header - 1 && ~rw)
		rx_d <= {rx_d[6:0], d_i};
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n )
		addr_dv <= 1'b0;
	else if (spi_start || spi_end)
		addr_dv <= 1'b0;
	else if (bitcnt > header - 1)
		addr_dv <= 1'b1;
end

always_ff @(posedge clk, negedge reset_n)
begin
	if (~reset_n )
		rxdv <= 1'b0;
	else if (spi_start || spi_end)
		rxdv <= 1'b0;
	else if (bitcnt == pktsz -1 && sync_sclk_re  && ~rw)
		rxdv <= 1'b1;
end

assign txdv = (bitcnt == pktsz -1 && rw == 1) ? 1'b1 : 1'b0;

assign rw_out = rw;

endmodule : spi_slave
