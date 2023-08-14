
/******************************************************************
Outputs inputted time and LCD states based on user keypad input
******************************************************************/
module keypad_logic(
	output reg 		 load_time = 0,		// Flag to load user inputted time
	output reg 		 load_alarm = 0,	// Flag to load user inputted alarm time
	output reg [3:0] set_hours = 0,		// User inputted hours
	output reg [5:0] set_mins = 0,		// User inputted minutes
	output 	   [5:0] set_secs,			// User inputted seconds (default = 0)
	output reg 		 set_am_pm = 0,		// User inputted meridiem
	output reg [1:0] display_state = 0,	// Display state (current,alarm,input)
	output reg [2:0] input_count = 0,	// Current number of digits inputted

	input 			 Clock_1sec,		// 1 second clock 
	input 			 reset,				// Resets output to zero
	input 	   [3:0] key_code,			// Code of inputted key
	input 			 key_held			// Flag for holding key down
);
	parameter
		AM_PM_KEY = 4'b1010,	// Address of meridiem toggle key
		ALARM_KEY = 4'b1100,	// Address of alarm key
		TIME_KEY = 4'b1011;		// Address of time key
			
	reg [15:0] time_input = 0000_0000_0000_0000;	// Inputted time, 4 individual digits d0-9
	reg [3:0] input_timer = 0;						// Time until input state ends

	assign set_secs = 0;

	//---------------------------------------------------------------
	// When reset, default outputs to zero
	always@(posedge reset) begin
		load_time = 0;
		load_alarm = 0;
		set_hours = 0;
		set_mins = 0;
		set_am_pm = 0;
		display_state = 0;
		input_count = 0;
	end

	//---------------------------------------------------------------
	// Reset loads, no longer display alarm time 
	always@(negedge key_held) begin

		// Reset meridiem back to AM after loadings
		if (load_time || load_alarm)
			set_am_pm <= 0;
		
		// Reset loads and input meridiem immediately after loading
		load_time <= 0;
		load_alarm <= 0;

		// Return to current time if alarm key isn't pressed
		if (key_code == ALARM_KEY && input_count == 0)
			display_state <= 2'b00;

	end

	//---------------------------------------------------------------
	// Input key functions
	always@(posedge key_held) begin

		// Display alarm time (only when user isn't inputting)
		if (key_code == ALARM_KEY && input_count == 0)
			display_state = 2'b01;
		// Toggle AM,PM
		else if (key_code == AM_PM_KEY && input_count > 0)
			set_am_pm = ~set_am_pm;
		// Input time digits
		else if (key_code >= 4'b0000 && key_code <= 4'b1001) begin

			// Maximum input count = 4
			if (input_count < 4)
				input_count = input_count + 1;

			display_state = 2'b10;	// Display changes to show inputted digits
			input_timer = 0;		// Timer resets each time a digit key is pressed

			time_input = {time_input[11:0], key_code};				// New digit input is shifted left into register
			set_hours = 10*time_input[15:12] + time_input[11:8];	// Last 8 bits converted to hours
			set_mins = 10*time_input[7:4] + time_input[3:0];		// First 8 bits converted to minutes

		end
		// Load time,alarm (minimum input count = 3)
		else if ((key_code == ALARM_KEY || key_code == TIME_KEY) && input_count >= 3) begin
			
			display_state = 2'b00;	// Display returns to current time
			input_count = 0;		// Count reset
			input_timer = 0;		// Timer reset
			time_input = 0;			// Register of inputted time reset

			// Time,alarm is loaded only if inputted time is valid
			if ((set_hours >= 1 && set_hours <= 12) && set_mins <= 59) begin
				case(key_code)
					TIME_KEY: load_time = 1;	// Load time if time key pressed
					ALARM_KEY: load_alarm = 1;	// Load alarm if alarm key pressed
				endcase
			end

		end
		
	end //always

	//---------------------------------------------------------------
	// Input timer
	always@(posedge Clock_1sec) begin

		// Count up when user is inputting
		if (input_count > 0)
			input_timer = input_timer + 1;

		// After 10 sec of no input, return to current time
		if (input_timer >= 10) begin
			display_state <= 2'b00;	// Display returns to current time
			input_count <= 0;		// Count reset
			input_timer <= 0;		// Timer reset
			time_input <= 0;		// Register of inputted time reset
		end

	end

endmodule
