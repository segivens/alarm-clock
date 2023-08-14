
/******************************************************************
Keeps track of time
Stores alarm time
Compares current time to alarm time to trigger alarm
Outputs time to be displayed on LCD
******************************************************************/
module alarm_clock_logic(
	output [3:0] hours,			// Hours to be displayed, d00-12
	output [5:0] mins,			// Minutes to be displayed, d00-12
	output       am_pm,			// Meridiem to be displayed, AM=0 PM=1
	output reg   flashing,		// Flag to flash display
	output reg   alarm,			// Flag to trigger alarm

	input 		 Clock_1sec,	// 1 second clock
	input 		 reset, 		// Resets all clock values to zero
	input 		 load_time,		// Flag to load user inputted time
	input 		 load_alarm,	// Flag to load user inputted alarm time
	input  [3:0] set_hours,		// User inputted hours
	input  [5:0] set_mins,		// User inputted minutes
	input  [5:0] set_secs,		// User inputted seconds
	input 		 set_am_pm,		// User inputted meridiem
	input 		 alarm_enable,	// Flag to enable alarm
	input  [1:0] display_state	// Display state (current,alarm,input)
);
	reg    [3:0] alarm_hours = 0;	// Stored alarm hours, d00-12
	reg    [5:0] alarm_mins = 0;	// Stored alarm minutes, d00-59
	reg 	     alarm_am_pm = 0;	// Stored alarm meridiem

	reg    [3:0] current_hours = 0;	// Currently tracked hours, d00-12
	reg    [5:0] current_mins = 0;	// Currently tracked minutes, d00-59
	reg    [5:0] current_secs = 0;	// Currently tracked seconds, d00-59
	reg 		 current_am_pm = 0;	// Currently tracked meridiem

	//---------------------------------------------------------------
	// Reset, set, update
	always@(posedge Clock_1sec, posedge reset, posedge load_time) begin

		// Reset current time and alarm time
		if (reset) begin
			current_secs <= 0; 
			current_mins <= 0; 
			current_hours <= 0;
			current_am_pm <= 0;
			alarm_mins <= 0; 
			alarm_hours <= 0;
			alarm_am_pm <= 0;
			alarm <= 0;
			flashing <= 1;
		end 
		// Set current time
		else if (load_time) begin
			current_secs <= set_secs;
			current_mins <= set_mins;
			current_hours <= set_hours;
			current_am_pm <= set_am_pm;
			flashing <= 0;
		end
		// Update current time
		else begin
			current_secs = current_secs + 1;

			if (current_secs >= 60) begin
				current_secs = 0;
				current_mins = current_mins + 1;

				if (current_mins >= 60) begin
					current_mins = 0;
					current_hours = current_hours + 1;

					if (current_hours == 12)
						current_am_pm = ~current_am_pm;

					if (current_hours >= 13)
						current_hours = 1;

				end
			end
		end

	end

	//---------------------------------------------------------------
	// Trigger alarm or disable alarm
	always@(posedge Clock_1sec, alarm_enable) begin

		if (alarm_enable && flashing == 0 && {current_hours,current_mins,current_am_pm} == {alarm_hours,alarm_mins,alarm_am_pm})
			alarm <= 1;
		else
			alarm <= 0;

	end

	//---------------------------------------------------------------
	// Load alarm time when necessary 
	always@(posedge load_alarm) begin
		alarm_mins <= set_mins; 
		alarm_hours <= set_hours;
		alarm_am_pm <= set_am_pm;
	end

	//---------------------------------------------------------------
	// Decide which time to be displayed
	mux_3x1_4bit C1(
		hours, 
		current_hours, 
		alarm_hours, 
		set_hours, 
		display_state
	);
	mux_3x1_6bit C2(
		mins,  
		current_mins,         
		alarm_mins,
		set_mins, 
		display_state
	);
	mux_3x1 C3(
		am_pm, 
		current_am_pm, 
		alarm_am_pm, 
		set_am_pm, 
		display_state
	);

endmodule

/******************************************************************
3x1 MUX (1-bit) to choose which time value to display (meridiem)

00 : Current time
01 : Alarm time
10 : Input time
******************************************************************/
module mux_3x1(
	output		Y,		// 1 output
	input 		A,B,C,	// 3 inputs
	input [1:0] sel		// Select
);

	assign Y = (sel == 2'b00) ? A	// Current time
          	 : (sel == 2'b01) ? B	// Alarm time
             : (sel == 2'b10) ? C	// Input time
             /* default */ 	  : A;

endmodule

/******************************************************************
3x1 MUX (4-bit) to choose which time value to display (hours)
******************************************************************/
module mux_3x1_4bit(
	output [3:0] Y,		// 1 output
	input  [3:0] A,B,C,	// 3 inputs
	input  [1:0] sel	// Select
);

	mux_3x1 C1(Y[0],A[0],B[0],C[0],sel);
	mux_3x1 C2(Y[1],A[1],B[1],C[1],sel);
	mux_3x1 C3(Y[2],A[2],B[2],C[2],sel);
	mux_3x1 C4(Y[3],A[3],B[3],C[3],sel);
	
endmodule

/******************************************************************
3x1 MUX (6-bit) to choose which time value to display (minutes)
******************************************************************/
module mux_3x1_6bit(
	output [5:0] Y,		// 1 output
	input  [5:0] A,B,C,	// 3 inputs
	input  [1:0] sel	// Select
);

	mux_3x1 C1(Y[0],A[0],B[0],C[0],sel);
	mux_3x1 C2(Y[1],A[1],B[1],C[1],sel);
	mux_3x1 C3(Y[2],A[2],B[2],C[2],sel);
	mux_3x1 C4(Y[3],A[3],B[3],C[3],sel);
	mux_3x1 C5(Y[4],A[4],B[4],C[4],sel);
	mux_3x1 C6(Y[5],A[5],B[5],C[5],sel);
	
endmodule