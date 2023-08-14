///////////////////////////////
// Steven Givens
// CDA 6214
// Project
// 12/6/22
//
// Alarm Clock
///////////////////////////////

`include "Timing_Generator.v"
`include "Keypad_Scanner_Decoder.v"
`include "Keypad_Logic.v"
`include "Alarm_Clock_Logic.v"
`include "LCD_Display.v"

/******************************************************************
Main module for alarm clock, calls other modules
******************************************************************/
module alarm_clock_top(
	output [6:0] seg1,			// 1st display (left-most)
	output [6:0] seg2,			// 2nd display
	output [6:0] seg3,			// 3rd display
	output [6:0] seg4,			// 4th display (right-most)
	output 		 am_pm_LED,		// LED dot display of meridiem
	output 		 alarm,			// Alarm output noise
	output [3:0] keypad_row,	// Row values outputted to keypad

	input 		 clk_256Hz,		// 256 cycles/sec board clock 
	input 		 reset,			// Resets all components of alarm clock
	input 		 alarm_enable,	// Switch to enable alarm
	input  [3:0] keypad_column	// Column values inputted from keypad	
);
	wire 		 Clock_1sec;				// 1 second clock
	wire   [3:0] key_code;					// Code of inputted key
	wire		 key_held;					// Flag for holding key down
	wire   [3:0] set_hours, hours;			// Inputted hours, display hours
	wire   [5:0] set_mins, mins;			// Inputted minutes, display minutes
	wire 		 set_am_pm;					// Inputted meridiem
	wire   [1:0] display_state;				// Display state (current,alarm,input)
	wire   [2:0] input_count;				// Current number of digits inputted
	wire 		 load_time, load_alarm;		// Flag to load time,alarm
	wire 		 flashing;					// Flag to flash display
	wire   [5:0] set_secs;					// Default to zero, user cannot change

	// Call each module
	timing_generator C1(
		.clk_1Hz		(Clock_1sec),
		.clk_256Hz		(clk_256Hz),
		.reset			(reset)
	);

	keypad_scanner_decoder C2(
		.row			(keypad_row),
		.key_code		(key_code),
		.key_held		(key_held),
		.clk_256Hz		(clk_256Hz),
		.reset			(reset),
		.col			(keypad_column)
	);

	keypad_logic C3(
		.load_time		(load_time),
		.load_alarm		(load_alarm),
		.set_hours		(set_hours),
		.set_mins		(set_mins),
		.set_secs		(set_secs),
		.set_am_pm		(set_am_pm),
		.display_state	(display_state),	
		.input_count	(input_count),
		.Clock_1sec		(Clock_1sec),
		.reset			(reset),
		.key_code		(key_code),
		.key_held		(key_held)
	);

	alarm_clock_logic C4(
		.hours			(hours),
		.mins			(mins),
		.am_pm			(am_pm_LED),
		.flashing		(flashing),
		.alarm			(alarm),
		.Clock_1sec		(Clock_1sec),
		.reset			(reset),
		.load_time		(load_time),
		.load_alarm		(load_alarm),
		.set_hours		(set_hours),
		.set_mins		(set_mins),
		.set_secs		(6'b0),
		.set_am_pm		(set_am_pm),
		.alarm_enable	(alarm_enable),
		.display_state	(display_state)	
	);

	lcd_display C5(
		.seg1			(seg1),
		.seg2			(seg2),
		.seg3			(seg3),
		.seg4			(seg4),
		.Clock_1sec		(Clock_1sec),
		.hours			(hours),
		.mins			(mins),
		.flashing		(flashing),
		.display_state	(display_state),
		.input_count	(input_count)
	);

endmodule

/******************************************************************
Test bench for alarm clock
******************************************************************/
`timescale 1s/1ms

module SIM_alarm_clock_top;

	wire [6:0] seg1;			// 1st display (left-most)
	wire [6:0] seg2;			// 2nd display
	wire [6:0] seg3;			// 3rd display
	wire [6:0] seg4;			// 4th display (right-most)
	wire 	   am_pm_LED;		// LED dot display of meridiem
	wire 	   alarm;			// Alarm output noise
	wire [3:0] keypad_row;		// Row values outputted to keypad

	reg 	   clk_256Hz;		// 256 cycles/sec board clock 
	reg 	   reset;			// Resets all components of alarm clock
	reg 	   alarm_enable;	// Switch to enable alarm
	reg  [3:0] keypad_column;	// Column values of keypad
	
	reg  [7:0] sim_key;			// Simulated key press (row,column)
	
	alarm_clock_top C1(
		.seg1			(seg1),
		.seg2			(seg2),
		.seg3			(seg3),
		.seg4			(seg4),
		.am_pm_LED		(am_pm_LED),
		.alarm			(alarm),
		.keypad_row		(keypad_row),
		.clk_256Hz		(clk_256Hz),
		.reset			(reset),
		.alarm_enable	(alarm_enable),
		.keypad_column	(keypad_column)
	);
	
	// Board clock
	// PERIOD = 1/256 = 0.00390625 sec 
	// HALF PERIOD = 0.001953125
	initial
		#0 clk_256Hz = 0;
	always
		#0.001953125 clk_256Hz = ~clk_256Hz;

	// Change column values based on simulated key input
	// Update every half clock period
	always begin
		#0.001953125
		if (keypad_row == sim_key[7:4])
			keypad_column = sim_key[3:0];
		else
			keypad_column = 0;
	end

	// Test inputs
	initial begin

		// Alarm clock is OFF
		#0	reset = 1;
			alarm_enable = 0;
			keypad_column = 0;
			sim_key = 0;
			
		// Alarm clock is turned ON
		#1	reset = 0;

		// Allow LCD to flash for 5 seconds
		// Set time to 11:58 PM
		// Input 1 key
		#5	sim_key = 8'b1000_1000; #0.25 sim_key = 0;
		// Input time key (does nothing)
		#1	sim_key = 8'b0100_0001; #0.25 sim_key = 0;
		// Input alarm key (does nothing)
		#1	sim_key = 8'b0010_0001; #0.25 sim_key = 0;
		// Input 1 key
		#1	sim_key = 8'b1000_1000; #0.25 sim_key = 0;
		// Input 5 key
		#1	sim_key = 8'b0100_0100; #0.25 sim_key = 0;
		// Input 8 key
		#1	sim_key = 8'b0010_0100; #0.25 sim_key = 0;
		// Input meridiem key (AM to PM)
		#1	sim_key = 8'b1000_0001; #0.25 sim_key = 0;
		// Input time key
		#1	sim_key = 8'b0100_0001; #0.25 sim_key = 0;

		// Set alarm time to 11:59 PM
		// Input 1 key		
		#5	sim_key = 8'b1000_1000; #0.25 sim_key = 0;
		// Input 1 key
		#1	sim_key = 8'b1000_1000; #0.25 sim_key = 0;
		// Input 5 key
		#1	sim_key = 8'b0100_0100; #0.25 sim_key = 0;
		// Input 9 key
		#1	sim_key = 8'b0010_0010; #0.25 sim_key = 0;
		// Input meridiem key (AM to PM)
		#1	sim_key = 8'b1000_0001; #0.25 sim_key = 0;
		// Input alarm key
		#1	sim_key = 8'b0010_0001; #0.25 sim_key = 0;	// 11:58:10

		// Turn alarm ON
		#1	alarm_enable = 1;	// 11:58:11

		// Show alarm time for 5 seconds
		#1	sim_key = 8'b0010_0001; #5 sim_key = 0;	// 11:58:17

		// Input 4 key		
		#5	sim_key = 8'b0100_1000; #0.25 sim_key = 0; // 11:58:22
		
		// Wait for screen to return to current time after 10 seconds
		// Wait for alarm to trigger
		// Turn off alarm 5 seconds after triggering
		#43	alarm_enable = 0;	// 11:59:05

		// Set alarm time to 12:00 AM
		// Input 1 key		
		#5	sim_key = 8'b1000_1000; #0.25 sim_key = 0;
		// Input 2 key
		#1	sim_key = 8'b1000_0100; #0.25 sim_key = 0;
		// Input 0 key
		#1	sim_key = 8'b0001_0100; #0.25 sim_key = 0;
		// Input 0 key
		#1	sim_key = 8'b0001_0100; #0.25 sim_key = 0;
		// Input alarm key
		#1	sim_key = 8'b0010_0001; #0.25 sim_key = 0;	// 11:59:14	

		// Wait for 12:00 AM to show hour and meridiem change
		// Alarm will no trigger because disabled
		// Turn ON alarm 5 seconds after 12:00 AM
		#51	alarm_enable = 1;	// 12:00:05
		// Alarm will immediately trigger
		// Wait another 55 seconds for alarm to turn off by itself
		// Reset Alarm Clock 5 seconds after alarm turns off
		#60 reset = 1;	// 12:00:05	

		// Alarm clock is turned ON
		#1	reset = 0;

		// Input meridiem key (does nothing)
		#1	sim_key = 8'b1000_0001; #0.25 sim_key = 0;

		// Show alarm time for 5 seconds (show default 00:00 without flashing)
		#1	sim_key = 8'b0010_0001; #5 sim_key = 0;

		// Set time to 6:30 AM
		// Input 6 key
		#70	sim_key = 8'b1000_1000; #0.25 sim_key = 0;
		// Input 3 key
		#1	sim_key = 8'b1000_0010; #0.25 sim_key = 0;
		// Input 0 key
		#1	sim_key = 8'b0001_0100; #0.25 sim_key = 0;
		// Input time key
		#1	sim_key = 8'b0100_0001; #0.25 sim_key = 0;

	end

endmodule
