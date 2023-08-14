
/******************************************************************
Outputs a 1 second clock from the 256Hz board clock
******************************************************************/
module timing_generator(
	output reg clk_1Hz,		// 1 second clock
	input 	   clk_256Hz,	// 256 cycles/sec board clock 
	input 	   reset		// Resets board clock and counter
);
	reg [7:0]  counter = 0;	// Counts to 128 (half frequency of board clock)

	// Counts up to half cycle of board clock, toggles output clock
	always@(posedge clk_256Hz, posedge reset) begin

		// Reset clock and counter to zero
		if (reset) begin
			clk_1Hz <= 0;
			counter <= 0;
		end
		// Count up each positive edge
		else begin
			counter = counter + 1;
			// Half cycle
			if (counter == 128) begin
				counter = 0;
				clk_1Hz = ~clk_1Hz;	// Toggle
			end	
		end
	end

endmodule

module SIM_timing_generator;

	wire clk_1Hz;		// 1 second clock
	reg clk_256Hz;	// 256 cycles/sec board clock 
	reg reset;		// Resets board clock and counter


	timing_generator C1(clk_1Hz,clk_256Hz,reset);

	initial
		#0 clk_256Hz = 0;
	always
		#0.001953125 clk_256Hz = ~clk_256Hz;

	initial begin

		#0 reset = 1;
		#1 reset = 0;

	end

endmodule