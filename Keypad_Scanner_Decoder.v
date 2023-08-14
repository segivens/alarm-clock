
/******************************************************************
Scans and decodes values from keypad
Keypad columns are connected to pull down resister
******************************************************************/
module keypad_scanner_decoder(
	output reg [3:0] row,		// Row values outputted to keypad 
	output reg [3:0] key_code,	// Code of inputted key
	output reg		 key_held,	// Flag for holding key down

	input 		 	 clk_256Hz,	// 256 cycles/sec board clock 
	input 		 	 reset,		// Resets registers to zero
	input  	   [3:0] col		// Column values inputted from keypad
);

	always@(posedge clk_256Hz, posedge reset) begin

		// Set to zero when reset
		if (reset) begin
			row <= 4'b0001;	
			key_code <= 4'b1111;
			key_held <= 0;	
		end
		else begin
			// If column key press is detected at row, decode key value
			if (col != 4'b0000) begin
        		key_held <= 1;	// Key is being held down
				case({row,col})
					8'b1000_1000: key_code <= 4'b0001;	// "1" key
					8'b1000_0100: key_code <= 4'b0010; 	// "2" key
					8'b1000_0010: key_code <= 4'b0011; 	// "3" key
					8'b1000_0001: key_code <= 4'b1010; 	// "AM/PM" key

					8'b0100_1000: key_code <= 4'b0100;	// "4" key
					8'b0100_0100: key_code <= 4'b0101; 	// "5" key
					8'b0100_0010: key_code <= 4'b0110; 	// "6" key
					8'b0100_0001: key_code <= 4'b1011; 	// "Set Time" key

					8'b0010_1000: key_code <= 4'b0111; 	// "7" key
					8'b0010_0100: key_code <= 4'b1000; 	// "8" key
					8'b0010_0010: key_code <= 4'b1001; 	// "9" key
					8'b0010_0001: key_code <= 4'b1100; 	// "Set Alarm" key

					8'b0001_1000: key_code <= 4'b1111; 	// Unused key
					8'b0001_0100: key_code <= 4'b0000; 	// "0" key
					8'b0001_0010: key_code <= 4'b1111; 	// Unused key
					8'b0001_0001: key_code <= 4'b1111; 	// Unused key
					default:	  key_code <= 4'b1111; 	// Unused key
				endcase
      		end 
			// scan each row
			else begin
        		key_held <= 0;
        		case (row)
          			4'b1000: row <= 4'b0100;
          			4'b0100: row <= 4'b0010;
          			4'b0010: row <= 4'b0001;
          			4'b0001: row <= 4'b1000;
          			default: row <= 4'b1000;
        		endcase
			end
		end
	end
endmodule