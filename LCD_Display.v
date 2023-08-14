
/******************************************************************
Outputs all seven segment displays
Flashing logic
******************************************************************/
module lcd_display(
	output [6:0] seg1,			// 1st display (left-most)
	output [6:0] seg2,			// 2nd display
	output [6:0] seg3,			// 3rd display
	output [6:0] seg4,			// 4th display (right-most)

	input 		 Clock_1sec,	// 1 second clock
	input  [3:0] hours,			// Hours to be displayed, d00-12
	input  [5:0] mins,			// Minutes to be displayed, d00-59
	input 		 flashing,		// Flag to flash display
	input  [1:0] display_state,	// Display state (current,alarm,input)
	input  [2:0] input_count	// Current number of digits inputted
);
	wire   [3:0] hours_tens, hours_ones;	// Tens and ones place of display hours
	wire   [3:0] mins_tens, mins_ones;		// Tens and ones place of display minutes
	reg    [3:0] reset = 0;					// Display OFF when one

	//---------------------------------------------------------------
	// Flash display when required
	always@(posedge Clock_1sec, display_state, input_count, flashing) begin
		if (flashing && display_state == 2'b00)
			reset <= ~reset;
		else begin
			case(input_count)
				3'd0: reset <= 4'b0000;
				3'd1: reset <= 4'b1110;
				3'd2: reset <= 4'b1100;
				3'd3: reset <= 4'b1000;
				3'd4: reset <= 4'b0000;
			endcase
		end
	end

	//---------------------------------------------------------------
	// Split hours/mins into two seperate digits
	split_digits C1(hours_tens, hours_ones, {2'b00,hours});
	split_digits C2(mins_tens, mins_ones, mins);

	// Get seven segment display values
	seven_segment C3(seg1,hours_tens,reset[3]);
	seven_segment C4(seg2,hours_ones,reset[2]);
	seven_segment C5(seg3,mins_tens,reset[1]);
	seven_segment C6(seg4,mins_ones,reset[0]);

endmodule

/******************************************************************
Seven segment display decoder
Outputs decoded value given number 0-9
******************************************************************/
module seven_segment(
	output reg [6:0] out,	// Decoded segment values

	input 	   [3:0] in,	// 1-digit number 0-9 to be displayed
	input 			 reset	// All segments OFF when high
);

	always@(*) begin
		if (reset)
			out = 0;
		else begin
			case(in)
				4'd0: out = 7'b1111110;
				4'd1: out = 7'b0110000;
				4'd2: out = 7'b1101101;
				4'd3: out = 7'b1111001;
				4'd4: out = 7'b0110011;
				4'd5: out = 7'b1011011;
				4'd6: out = 7'b1011111;
				4'd7: out = 7'b1110000;
				4'd8: out = 7'b1111111;
				4'd9: out = 7'b1111011;
			endcase
		end
	end

endmodule

/******************************************************************
Splits a 2-digit number 00-59 into two seperate digits
i.e., 45 yields 4 and 5
******************************************************************/
module split_digits(
	output [3:0] tens,	// Tens place, d0-9
	output [3:0] ones,	// Ones places, d0-9

	input  [5:0] num	// 2-digit number d00-59
);

    assign tens = (num >= 50) ? 5
                : (num >= 40) ? 4
                : (num >= 30) ? 3 
                : (num >= 20) ? 2 
                : (num >= 10) ? 1 
                /* default */ : 0;

    assign ones = (num >= 50) ? (num - 50)
                : (num >= 40) ? (num - 40)
                : (num >= 30) ? (num - 30) 
                : (num >= 20) ? (num - 20) 
                : (num >= 10) ? (num - 10) 
                /* default */ : num; 

endmodule
