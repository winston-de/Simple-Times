using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time.Gregorian;
module Main {
	//The universal watchface width and height values
	var width;
	var height;

	const RELATIVE_TICK_STROKE = 0.01;
	const RELATIVE_HOUR_TICK_LENGTH = 0.08;
	const RELATIVE_MIN_TICK_LENGTH = 0.04;
	const RELATIVE_HOUR_TICK_STROKE = 0.04;
	const RELATIVE_MIN_TICK_STROKE = 0.04;
	const RELATIVE_MIN_CIRCLE_TICK_SIZE = 0.01;
	const RELATIVE_HOUR_CIRCLE_TICK_SIZE = 0.02;
	const RELATIVE_HOUR_TRIANGLE_TICK_SIZE = 0.04;
	const RELATIVE_MIN_TRIANGLE_TICK_SIZE = 0.02;

	const RELATIVE_HOUR_HAND_LENGTH = 0.2;
	const RELATIVE_MIN_HAND_LENGTH = 0.4;
	const RELATIVE_SEC_HAND_LENGTH = 0.4;

	const RELATIVE_HOUR_HAND_LENGTH_EXTENDED = 0.23;
	const RELATIVE_MIN_HAND_LENGTH_EXTENDED = 0.46;
	const RELATIVE_SEC_HAND_LENGTH_EXTENDED = 0.46;

	const RELATIVE_HOUR_HAND_STROKE = 0.013;
	const RELATIVE_MIN_HAND_STROKE = 0.013;
	const RELATIVE_SEC_HAND_STROKE = 0.01;

	const RELATIVE_PADDING = 0.03;
	const RELATIVE_PADDING2 = 0.01;

	const RELATIVE_CENTER_RADIUS = 0.025;
	const BOX_PADDING = 2;
	const TEXT_PADDING = [1, 2];

	const DOW_SIZE_SMALL = [36, 19];
	const DOW_SIZE_MEDIUM = [44, 22];
	const DOW_SIZE_LARGE = [54, 29];

	const DATE_SIZE_SMALL = [24, 19];
	const DATE_SIZE_MEDIUM = [28, 22];
	const DATE_SIZE_LARGE = [36, 29];

	const TIME_SIZE_SMALL = [48, 19];
	const TIME_SIZE_MEDIUM = [57, 22];
	const TIME_SIZE_LARGE = [72, 29];

	const FLOORS_SIZE_SMALL = [40, 19];
	const FLOORS_SIZE_MEDIUM = [47, 22];
	const FLOORS_SIZE_LARGE = [60, 29];

	const BATTERY_SIZE_SMALL = [32, 19];
	const BATTERY_SIZE_MEDIUM = [38, 22];
	const BATTERY_SIZE_LARGE = [48, 29];

	const STATUS_BOX_SIZE_SMALL = [94, 19];
	const STATUS_BOX_SIZE_MEDIUM = [111, 22];
	const STATUS_BOX_SIZE_LARGE = [141, 29];

	const SCREENSAVER_SPEED_MULT = [1.2, 1.1];
	const SCREENSAVER_BOUNDS = [100, 100];
	const TOTAL_COLORS = 14;
	const COLORS = [
		Graphics.COLOR_BLACK, 
		Graphics.COLOR_WHITE, 
		Graphics.COLOR_LT_GRAY, 
		Graphics.COLOR_DK_GRAY,
		Graphics.COLOR_BLUE,
		0x02084f,
		Graphics.COLOR_RED,
		0x730000,
		Graphics.COLOR_GREEN,
		0x004f15,
		0xAA00FF,
		Graphics.COLOR_PINK,
		Graphics.COLOR_ORANGE,
		Graphics.COLOR_YELLOW
	];
	
	class SimpleAnalogView extends WatchUi.WatchFace {
		var offScreenBuffer;
		var clip;

		var lowPower = false;
		var needsProtection = false;
		var lowMemDevice = false;
		var partialUpdates = false;

		var dow_size;
		var date_size;
		var time_size;
		var floors_size;
		var battery_size;
		var status_box_size;

		function initialize() {
			WatchFace.initialize();
		}

		// Load your resources here
		function onLayout(dc) {
			// constants = new Constants();
			
			width = dc.getWidth();
			height = dc.getHeight();

			//Due to the maximum memory usage being to low for devices with displays of 260px, buffered bitmaps and partial updates must be disabled
			if((width >= 220 && System.getSystemStats().totalMemory < 97000) || !(Graphics has :BufferedBitmap) || !(dc has :clearClip)) {
				lowMemDevice = true;
			}

			if(System.getDeviceSettings() has :requiresBurnInProtection && System.getDeviceSettings().requiresBurnInProtection) {
				needsProtection = true;
			}

			//Only use a buffered bitmap if the device has the mnemory capability
			//Also, turn off partial updates if the device can't use buffered bitmaps
			if(!lowMemDevice && !needsProtection) {
				resetBufferedBitmap();
				partialUpdates = true;
			} else {
				partialUpdates = false;
			}

			updateBoxSizes();

			updateValues();
		}

		// Update the view
		function onUpdate(dc) {
			if(needsProtection && lowPower && partialUpdates) {
				dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
				dc.clear();
				updateValues();
				drawScreenSaver(dc);
			} else if(needsProtection && lowPower) {
				updateValues();
				dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
				dc.clear();
			} else {		

				updateValues();

				if(!partialUpdates || needsProtection) {
					drawBackground(dc);
				} else {
					dc.clearClip();
					drawBackground(offScreenBuffer.getDc());
					dc.drawBitmap(0, 0, offScreenBuffer);
				}

				if(Application.getApp().getProperty("ShowSecondHand")) {
					drawSecondHand(dc);
				}

				dc.setColor(COLORS[Application.getApp().getProperty("BoxColor")], Graphics.COLOR_TRANSPARENT);
				dc.fillCircle(width/2-1, height/2-1, RELATIVE_CENTER_RADIUS*width);
			}
		}

		//partial updates
		function onPartialUpdate(dc) {
			if(partialUpdates) {
				drawSecondHand(dc);
			}
		}
		
		//use this to update values controlled by settings
		function updateValues() {

			var always_on = Application.getApp().getProperty("AlwaysOn");

			if(!lowMemDevice && !partialUpdates && !needsProtection && (always_on && Application.getApp().getProperty("ShowSecondHand"))) {
				partialUpdates = true;
				resetBufferedBitmap();
			} else if(!needsProtection && !lowMemDevice && (!always_on || !Application.getApp().getProperty("ShowSecondHand"))) {
				partialUpdates = false;
				clearBufferedBitmap();
			}

			if(needsProtection && always_on) {
				partialUpdates = true;
			} else if(needsProtection && !always_on) {
				partialUpdates = false;
			}
		}

		function drawBackground(dc) {
			dc.setColor(COLORS[Application.getApp().getProperty("Background")], COLORS[Application.getApp().getProperty("Background")]);
			dc.clear();
			drawTicks(dc);
			drawNumbers(dc);
			drawBox(dc);
			drawDateBox(dc);

			if(Application.getApp().getProperty("ShowStatusBar")) {
				drawStatusBox(dc, width/2, centerOnLeft(status_box_size[1], Application.getApp().getProperty("NumberStyle"), Application.getApp().getProperty("TickStyle"), width));
			}
			
			drawHands(dc);		
		}

		//Draws the correct ticks for the user's settings
		function drawTicks(dc) {
			var draw_numbers = false;
			var tick_style = Application.getApp().getProperty("TickStyle");
			var show_min_ticks = Application.getApp().getProperty("ShowMinTicks");

			if(Application.getApp().getProperty("NumberStyle") > 0) {
				draw_numbers = true;
			}

			dc.setColor(Application.getApp().getProperty("ForegroundColor"), Graphics.COLOR_TRANSPARENT);
			if(tick_style == 1) {
				if(show_min_ticks) {
					drawDashTicks(dc, RELATIVE_HOUR_TICK_LENGTH*width, RELATIVE_HOUR_TICK_STROKE*width, 12, draw_numbers, true);
					drawDashTicks(dc, RELATIVE_MIN_TICK_LENGTH*width, RELATIVE_MIN_TICK_STROKE*width, 60, draw_numbers, false);
				} else {
					drawDashTicks(dc, RELATIVE_MIN_TICK_LENGTH*width, RELATIVE_MIN_TICK_STROKE*width, 12, draw_numbers, true);
				}
			} else if(tick_style == 2) {
				if(show_min_ticks) {
					drawTicksCircle(dc, RELATIVE_HOUR_CIRCLE_TICK_SIZE*width, 1, 12, draw_numbers, true);
					drawTicksCircle(dc, RELATIVE_MIN_CIRCLE_TICK_SIZE*width, 1, 60, draw_numbers, false);
				} else {
					drawTicksCircle(dc, RELATIVE_MIN_CIRCLE_TICK_SIZE*width, 1, 12, draw_numbers, true);
				}
			} else if(tick_style == 3) {
				if(show_min_ticks) {
					drawTicksTriangle(dc, RELATIVE_HOUR_TRIANGLE_TICK_SIZE*width, 1, 12, draw_numbers, true);
					drawTicksTriangle(dc, RELATIVE_MIN_TRIANGLE_TICK_SIZE*width, 1, 60, draw_numbers, false);
				} else {
					drawTicksTriangle(dc, RELATIVE_MIN_TRIANGLE_TICK_SIZE*width, 1, 12, draw_numbers, true);
				}
			}
		}

		//Draws the correct numbers for the user's settings
		function drawNumbers(dc) {
			var number_style = Application.getApp().getProperty("NumberStyle");
			if(number_style == 1) {
				drawRomanNumerals(dc);
			} else if(number_style == 2) {
				drawPlainNumbers(dc);
			} else if(number_style == 3) {
				drawCenturyNumbers(dc);
			}
		}
		
		//Draws the correct hour and minute hands for the user's settings
		function drawHands(dc) {
			var clockTime = System.getClockTime();
			var hours = clockTime.hour;
			var minutes = clockTime.min;
			var seconds = clockTime.sec;

			var hour_hand_length = RELATIVE_HOUR_HAND_LENGTH;
			var min_hand_length = RELATIVE_MIN_HAND_LENGTH;

			var hand_style = Application.getApp().getProperty("HandStyle");

			if(Application.getApp().getProperty("TickStyle") != 0) {
				hour_hand_length = RELATIVE_HOUR_HAND_LENGTH_EXTENDED;
				min_hand_length = RELATIVE_MIN_HAND_LENGTH_EXTENDED;
			}

			dc.setColor(COLORS[Application.getApp().getProperty("HourMinHandColor")], Graphics.COLOR_TRANSPARENT);

			if(hand_style == 0) {
				drawLineHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.25, RELATIVE_HOUR_HAND_STROKE*width);
				drawLineHand(dc, 60, minutes, 0, 0, min_hand_length*width, RELATIVE_MIN_HAND_STROKE*width);
			} else if(hand_style == 1) {
				drawCircleHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.25, RELATIVE_HOUR_HAND_STROKE*width);
				drawCircleHand(dc, 60, minutes, 0, 0, min_hand_length*width, RELATIVE_MIN_HAND_STROKE*width);
			} else if(hand_style == 2) {
				drawLongArrowHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.75, RELATIVE_HOUR_HAND_STROKE*width);
				drawLongArrowHand(dc, 60, minutes, 0, 0, min_hand_length*width, RELATIVE_MIN_HAND_STROKE*width);
			} else if(hand_style == 3) {
				drawArrowHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.25, RELATIVE_HOUR_HAND_STROKE*width);
				drawArrowHand(dc, 60, minutes, 0, 0, min_hand_length*width, RELATIVE_MIN_HAND_STROKE*width);
			}
		}

		//Draws the correct information box for the user's settings
		function drawBox(dc) {
			var RBD = Application.getApp().getProperty("RightBoxDisplay1");

			if(RBD == 1) {
				drawTimeBox(dc, getBoxLocX(time_size[0]), 
					width/2 - (time_size[1])/2);
			}

			if(RBD == 2) {
				drawStepBox(dc, getBoxLocX(time_size[0]), 
					width/2 - (time_size[1])/2);
			}

			if(RBD == 3) {
				drawFloorsBox(dc, getBoxLocX(floors_size[0]), 
					width/2 - (floors_size[1])/2);
			}

			if(RBD == 4) {
				drawCaloriesBox(dc, getBoxLocX(time_size[0]), 
					width/2 - (time_size[1])/2);
			}

			if(RBD == 5) {
				drawDistanceBox(dc, getBoxLocX(time_size[0]), 
					width/2 - (time_size[1])/2);
			}

			if(RBD == 6) {
				drawBatteryBox(dc,  getBoxLocX(battery_size[0]), 
					width/2 - (battery_size[1])/2);
			}
		}

		//Draws the date according to the user's settings
		function drawDateBox(dc) {
			if(Application.getApp().getProperty("DateOnRight")) {
				drawDate(dc, centerOnRight(dow_size[0] + 4 + date_size[0], Application.getApp().getProperty("NumberStyle"), Application.getApp().getProperty("TickStyle"), width), width/2 - dow_size[1]/2);	
				// drawDate(dc, centerOnRight(dow_size[0] + 4 + date_size[0]), width/2 - dow_size[1]/2);
			} else {
				drawDate(dc, centerOnLeft(dow_size[0] + 4 + date_size[0], Application.getApp().getProperty("NumberStyle"), Application.getApp().getProperty("TickStyle"), width), width/2 - dow_size[1]/2);	
			}
		}

		function getBoxLocX(boxWidth) {
			if(!Application.getApp().getProperty("DateOnRight")) {
				return centerOnRight(boxWidth, Application.getApp().getProperty("NumberStyle"), Application.getApp().getProperty("TickStyle"), width);
				// return centerOnRight(width);
			}
			return centerOnLeft(boxWidth, Application.getApp().getProperty("NumberStyle"), Application.getApp().getProperty("TickStyle"), width);
		}

		function drawDashTicks(dc, length, stroke, num, draw_numbers, hour_ticks) {
			dc.setPenWidth(width * RELATIVE_TICK_STROKE);
			var tickAngle = 360/num;
			var center = width/2;
			
			for(var i = 0; i < num; i++) {
				var diff = 2;
				var cond1 = (!(i < diff || i > 60-diff) 
						&& !(i > 15-diff && i < 15+diff) 
						&& !(i > 30-diff && i < 30+diff) 
						&& !(i > 45-diff && i < 45+diff));

				if(GetShowNumsAt(Application.getApp().getProperty("NumberStyle"))) {
					cond1 = true;
				}

				if(Application.getApp().getProperty("NumberStyle") == 1) {
					cond1 = (!(i < diff || i > 60-diff) 
						&& !(i > 5-diff && i < 5+diff) 
						&& !(i > 10-diff && i < 10+diff) 
						&& !(i > 15-diff && i < 15+diff)
						&& !(i > 20-diff && i < 20+diff) 
						&& !(i > 25-diff && i < 25+diff) 
						&& !(i > 30-diff && i < 30+diff) 
						&& !(i > 35-diff && i < 35+diff) 
						&& !(i > 40-diff && i < 40+diff)
						&& !(i > 45-diff && i < 45+diff)
						&& !(i > 50-diff && i < 50+diff)
						&& !(i > 55-diff && i < 55+diff));
				}

				var cond2 = draw_numbers && hour_ticks && !(i == 0 || i == 3 || i == 6 || i == 9);

				if(GetShowNumsAt(Application.getApp().getProperty("NumberStyle"))) {
					cond2 = false;
				}
			
				if((draw_numbers && !hour_ticks && cond1) || cond2 || !draw_numbers) {
					var angle = Math.toRadians(tickAngle * i);
					var x1 = center + Math.round(Math.cos(angle) * (center-length));
					var y1 = center + Math.round(Math.sin(angle) * (center-length));
					//2x^2 = 20
					//x=10^0.5
					var x2 = center + Math.round(Math.cos(angle) * (center));
					var y2 = center + Math.round(Math.sin(angle) * (center));
					
					dc.drawLine(x1, y1, x2, y2);
				}
			}
		}

		function drawTicksCircle(dc, size, stroke, num, draw_numbers, hour_ticks) {
			dc.setPenWidth(width * RELATIVE_TICK_STROKE);
			var tickAngle = 360/num;
			var center = width/2;
			for(var i = 0; i < num; i++) {
				var diff = 2;
				var cond1 = (!(i < diff || i > 60-diff) 
						&& !(i > 15-diff && i < 15+diff) 
						&& !(i > 30-diff && i < 30+diff) 
						&& !(i > 45-diff && i < 45+diff));
				
				if(GetShowNumsAt(Application.getApp().getProperty("NumberStyle"))) {
					cond1 = true;
				}
				var cond2 = draw_numbers && hour_ticks && !(i == 0 || i == 3 || i == 6 || i == 9);

				if(GetShowNumsAt(Application.getApp().getProperty("NumberStyle"))) {
					cond2 = false;
				}

				if((draw_numbers && !hour_ticks && cond1) || cond2 || !draw_numbers) {
					var angle = Math.toRadians(tickAngle * i);
					var x1 = center + Math.round(Math.cos(angle) * (center - size - 1)) - 1;
					var y1 = center + Math.round(Math.sin(angle) * (center - size - 1)) - 1;    		
					dc.fillEllipse(x1, y1, size, size);
				}
			}
		}

		function drawTicksTriangle(dc, length, stroke, num, draw_numbers, hour_ticks) {
			dc.setPenWidth(width * RELATIVE_TICK_STROKE);
			var tickAngle = 360/num;
			var center = width/2;
			for(var i = 0; i < num; i++) {
				var diff = 2;
				var cond1 = (!(i < diff || i > 60-diff) 
						&& !(i > 15-diff && i < 15+diff) 
						&& !(i > 30-diff && i < 30+diff) 
						&& !(i > 45-diff && i < 45+diff));
				if(GetShowNumsAt(Application.getApp().getProperty("NumberStyle"))) {
					cond1 = true;
				}
				var cond2 = draw_numbers && hour_ticks && !(i == 0 || i == 3 || i == 6 || i == 9);

				if(GetShowNumsAt(Application.getApp().getProperty("NumberStyle"))) {
					cond2 = false;
				}

				if((draw_numbers && !hour_ticks && cond1) || cond2 || !draw_numbers) {
					var angle = Math.toRadians(tickAngle * i);
					var offset = Math.toRadians(2);
					var x1 = center + Math.round(Math.cos(angle) * (center-length));
					var y1 = center + Math.round(Math.sin(angle) * (center-length));
					//2x^2 = 20
					//x=10^0.5
					var x2 = center + Math.round(Math.cos(angle - offset) * (center));
					var y2 = center + Math.round(Math.sin(angle - offset) * (center));

					var x3 = center + Math.round(Math.cos(angle + offset) * (center));
					var y3 = center + Math.round(Math.sin(angle + offset) * (center));
					
					dc.fillPolygon([[x1, y1], [x2, y2], [x3, y3]]);
				}
			}
		}

		function drawRomanNumerals(dc) {
			
			var pad = 0.07 * width;
			
			if(Application.getApp().getProperty("TickStyle") == 1 || Application.getApp().getProperty("TickStyle") == 0 || !Application.getApp().getProperty("ShowMinTicks")) {
				pad = 0.05 * width;
			}

			drawNumberAngle(dc, 300, pad, "I");
			drawNumberAngle(dc, 330, pad, "II");
			drawNumberAngle(dc, 360, pad, "III");
			drawNumberAngle(dc, 30, pad, "IV");
			drawNumberAngle(dc, 60, pad, "V");
			drawNumberAngle(dc, 90, pad, "VI");
			drawNumberAngle(dc, 120, pad, "VII");
			drawNumberAngle(dc, 150, pad, "VIII");
			drawNumberAngle(dc, 180, pad, "IX");
			drawNumberAngle(dc, 210, pad, "X");
			drawNumberAngle(dc, 240, pad, "XI");
			drawNumberAngle(dc, 270, pad, "XII");
		}

		function drawPlainNumbers(dc) {
			
			var pad = 0.04*width;

			drawNumberAngle(dc, 270, pad, "12");
			drawNumberAngle(dc, 0, pad, "3");
			drawNumberAngle(dc, 90, pad + 2, "6");
			drawNumberAngle(dc, 180, pad, "9");
		}

		function drawCenturyNumbers(dc) {
			
			var pad = 0.06*width;

			if(Application.getApp().getProperty("TickStyle") != 0 && Application.getApp().getProperty("ShowMinTicks")) {
				pad = 0.09*width;
			}

			if(Application.getApp().getProperty("TickStyle") == 2 && Application.getApp().getProperty("ShowMinTicks")) {
				pad = 0.08*width;
			}

			drawNumberAngle(dc, 300, pad, "1");
			drawNumberAngle(dc, 330, pad, "2");
			drawNumberAngle(dc, 360, pad, "3");
			drawNumberAngle(dc, 30, pad, "4");
			drawNumberAngle(dc, 60, pad, "5");
			drawNumberAngle(dc, 90, pad, "6");
			drawNumberAngle(dc, 120, pad, "7");
			drawNumberAngle(dc, 150, pad, "8");
			drawNumberAngle(dc, 180, pad, "9");
			drawNumberAngle(dc, 210, pad, "10");
			drawNumberAngle(dc, 240, pad, "11");
			drawNumberAngle(dc, 270, pad, "12");

			
		}

		function drawLineHand(dc, num, time, offsetNum, offsetTime, length, stroke) {
			var angle = Math.toRadians((360/num) * time) - Math.PI/2;
			var center = width/2;
			

			if(offsetNum != 0) {
				var section = 360.00/num/offsetNum;
				angle += Math.toRadians(section * offsetTime);
			}
				
			dc.setPenWidth(stroke);
			var divider = 3;

			var x2 = center + Math.round((Math.cos(angle) * length));
			var y2 = center + Math.round((Math.sin(angle) * length));
			
			dc.drawLine(center, center, x2, y2);
			
		}

		function drawCircleHand(dc, num, time, offsetNum, offsetTime, length, stroke) {
			var angle = Math.toRadians((360/num) * time) - Math.PI/2;
			var center = width/2;
			
			if(offsetNum != 0) {
				var section = 360.00/num/offsetNum;
				angle += Math.toRadians(section * offsetTime);
			}
			
			dc.setPenWidth(stroke);
			var length1_multiplier = 0.70;
			var length_from_end = 0.11 * width;
			var radius = width * 0.03;

			var x = center + ((Math.cos(angle) * (length - length_from_end)));
			var y = center + ((Math.sin(angle) * (length - length_from_end)));

			var x2 = center + ((Math.cos(angle) * length));
			var y2 = center + ((Math.sin(angle) * length));

			var offsetx = ((Math.cos(angle) * radius));
			var offsety = ((Math.sin(angle) * radius));
			
			// dc.drawLine(center, center, x, y);
			dc.drawLine(center, center, x, y);
			dc.drawLine(x + offsetx*2, y + offsety*2, x2, y2);
			dc.drawEllipse(x + offsetx, y + offsety, radius, radius);
		}

		function drawLongArrowHand(dc, num, time, offsetNum, offsetTime, length, stroke) {
			var angle = Math.toRadians((360/num) * time) - Math.PI/2;
			var center = width/2;
			

			if(offsetNum != 0) {
				var section = 360.00/num/offsetNum;
				angle += Math.toRadians(section * offsetTime);
			}
			
			dc.setPenWidth(stroke);
			var x = center + Math.round((Math.cos(angle) * length));
			var y = center + Math.round((Math.sin(angle) * length));

			var x2 = center + Math.round((Math.cos(angle - Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));
			var y2 = center + Math.round((Math.sin(angle - Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));

			var x3 = center + Math.round((Math.cos(angle + Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));
			var y3 = center + Math.round((Math.sin(angle + Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));

			dc.fillPolygon([[x, y], [x2, y2], [x3, y3]]);

		}

		function drawArrowHand(dc, num, time, offsetNum, offsetTime, length, stroke) {
			var angle = Math.toRadians((360/num) * time) - Math.PI/2;
			var center = width/2;
			
			var end_multiplier = 0.08;


			if(offsetNum != 0) {
				var section = 360.00/num/offsetNum;
				angle += Math.toRadians(section * offsetTime);
			}
			
			dc.setPenWidth(stroke);

			var x = center + Math.round((Math.cos(angle)) * (length - end_multiplier*width) + 
				(Math.cos(angle - Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS*width*.7)));
			var y = center + Math.round((Math.sin(angle) * (length - end_multiplier*width)) + 
				(Math.sin(angle - Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS*width*.7)));

			var x2 = center + Math.round((Math.cos(angle) * length));
			var y2 = center + Math.round((Math.sin(angle) * length));

			var x3 = center + Math.round((Math.cos(angle) * (length - end_multiplier*width)) + 
				(Math.cos(angle + Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS*width*.7)));
			var y3 = center + Math.round((Math.sin(angle) * (length - end_multiplier*width)) + 
				(Math.sin(angle + Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS*width*.7)));

			var x4 = center + Math.round((Math.cos(angle + Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));
			var y4 = center + Math.round((Math.sin(angle + Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));

			var x5 = center + Math.round((Math.cos(angle - Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));
			var y5 = center + Math.round((Math.sin(angle - Math.toRadians(90)) * (RELATIVE_CENTER_RADIUS/2) * width));

			dc.fillPolygon([[x, y], [x2, y2], [x3, y3], [x4, y4], [x5, y5]]);
		}

		function drawSecondHand(dc) {
			var clockTime = System.getClockTime();
			var hours = clockTime.hour;
			var minutes = clockTime.min;
			var seconds = clockTime.sec;
			var sec_hand_length = RELATIVE_SEC_HAND_LENGTH;

			if(Application.getApp().getProperty("TickStyle") != 0) {
				sec_hand_length = RELATIVE_SEC_HAND_LENGTH_EXTENDED;
			}

			dc.setColor(COLORS[Application.getApp().getProperty("SecondHandColor")], Graphics.COLOR_TRANSPARENT);
			if(partialUpdates && !needsProtection) {
				drawSecondHandClip(dc, 60, seconds, sec_hand_length * width, RELATIVE_SEC_HAND_STROKE*width);
			} else if(!lowPower) {
				drawLineHand(dc, 60, seconds, 0, 0, sec_hand_length * width, RELATIVE_SEC_HAND_STROKE*width);
			}
		}
		
		function drawSecondHandClip(dc, num, time, length, stroke) {
			dc.drawBitmap(0, 0, offScreenBuffer);

			var angle = Math.toRadians((360/num) * time) - Math.PI/2;
			var center = width/2;
			dc.setPenWidth(stroke);
			
			var cosval = Math.round(Math.cos(angle) * length);
			var sinval = Math.round(Math.sin(angle) * length);
			
			var x = center + cosval;
			var y = center + sinval;
			
			var width2 = (center-x).abs();
			var height2 = (center-y).abs();
			var padding = width * RELATIVE_PADDING;
			var padding2 = width * RELATIVE_PADDING2;
			
			if(cosval < 0 && sinval > 0) {
				dc.setClip(center-width2-padding2, center-padding, width2+padding+padding2, height2+padding+padding2);
			}
			
			if(cosval < 0 && sinval < 0) {
				dc.setClip(center-width2-padding2, center-height2-padding2, width2+padding+padding2, height2+padding+padding2);
			}
			
			if(cosval > 0 && sinval < 0) {
				dc.setClip(center-padding, center-height2-padding2, width2+padding+padding2, height2+padding+padding2);
			}
			
			if(cosval > 0 && sinval > 0) {
				dc.setClip(center-padding, center-padding, width2+padding+padding2, height2+padding+padding2);
			}

			dc.setColor(COLORS[Application.getApp().getProperty("SecondHandColor")], Graphics.COLOR_TRANSPARENT);
			dc.drawLine(center, center, x, y);    

			dc.setColor(COLORS[Application.getApp().getProperty("BoxColor")], Graphics.COLOR_TRANSPARENT);
			dc.fillCircle(width/2-1, height/2-1, RELATIVE_CENTER_RADIUS*width);	
		}

		function drawStatusBox(dc, x, y) {
			var status_string = "";
			var settings = System.getDeviceSettings();
			var status = System.getSystemStats();

			if(settings.phoneConnected) {
				status_string += "K";
			}

			if(settings.alarmCount > 0) {
				status_string += "H";
			}

			if (settings has :doNotDisturb) {
				if(settings.doNotDisturb) {
					status_string += "I";
				}
			}

			if(settings.notificationCount > 0) {
				status_string += "J";
			}

			if(status has :charging && status.charging) {
				status_string += "A";
			} else if(status.battery > 86) {
				status_string += "G";
			} else if(status.battery > 72) {
				status_string += "F";
			} else if(status.battery > 56) {
				status_string += "E";
			} else if(status.battery > 40) {
				status_string += "D";
			} else if(status.battery > 24) {
				status_string += "C";
			} else {
				status_string += "B";
			}

			dc.setPenWidth(2);
			dc.setColor(COLORS[Application.getApp().getProperty("BoxColor")], Graphics.COLOR_WHITE);
			
			var boxText = new WatchUi.Text({
				:text=>status_string,
				:color=>COLORS[Application.getApp().getProperty("TextColor")],
				:font=>WatchUi.loadResource(Rez.Fonts.IconFont),
				:locX =>x + TEXT_PADDING[0],
				:locY=>y,
				:justification=>Graphics.TEXT_JUSTIFY_CENTER
			});

			boxText.draw(dc);
		}

		function drawDate(dc, x, y) {
			
			
			var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
			var dowString = getDateString(info.day_of_week);
			var day_string = info.day.toString();

			if(day_string.length() < 2) {
				day_string = " " + day_string;
			}

			if(dowString.equals("Thurs")) {
				dowString = "Thur";
			}
			
			drawTextBox(dc, dowString, x, y, dow_size[0], dow_size[1]);
			drawTextBox(dc, day_string, x + dow_size[0] + 4, y, date_size[0], date_size[1]);
		}
		
		function drawTimeBox(dc, x, y) {
			
			var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
			var clockTime = System.getClockTime();
			var hours = clockTime.hour.format("%02d").toNumber();
			var hourString = hours;

			if(!Application.getApp().getProperty("Use24HourFormat") && hours > 12) {
				hours -= 12;
				hourString = hours;
			}

			if(hours < 10) {
				hourString = " " + hourString;
			}

			drawTextBox(dc, hourString + ":" + clockTime.min.format("%02d"), x, y, time_size[0], time_size[1]);
		}
		
		function drawStepBox(dc, x, y) {
			
			var steps = ActivityMonitor.getInfo().steps;
			var stepString;
			if(steps > 99999) {
				stepString = "99+k";
			} else {
				stepString = (steps.toDouble()/1000).format("%.1f") + "k";
			}

			if(!Application.getApp().getProperty("ShowBoxes")) {
				stepString = " " + stepString;
			}
			// System.out.println(steps);

			drawTextBox(dc, stepString, x, y, time_size[0], time_size[1]);
		}

		function drawFloorsBox(dc, x, y) {
			
			var floors;
			var floorString;

			if(ActivityMonitor.getInfo() has :floorsClimbed) {
				floors = ActivityMonitor.getInfo().floorsClimbed;

				if(floors > 999) {
					floorString = "999+";
				} else {
					floorString = floors.toString();
				}
			} else {
				floorString = "NA";
			}

			
			if(!Application.getApp().getProperty("ShowBoxes")) {
					floorString = " " + floorString;
			}

			drawTextBox(dc, floorString, x, y, floors_size[0], floors_size[1]);
		}

		function drawCaloriesBox(dc, x, y) {
			
			var calories;
			calories = ActivityMonitor.getInfo().calories;

			var calorieString;
			if(calories > 99999) {
				calorieString = "99+k";
			} else {
				calorieString = (calories.toDouble()/1000).format("%0.1f") + "k";
			}

			if(!Application.getApp().getProperty("ShowBoxes")) {
				calorieString = " " + calorieString;
			}

			// System.out.println(steps);

			drawTextBox(dc, calorieString, x, y, time_size[0], time_size[1]);
		}

		function drawDistanceBox(dc, x, y) {
			var distanceMetric = System.getDeviceSettings().distanceUnits;
			var isDistanceMetric = distanceMetric == System.UNIT_METRIC;
		
			var distance;
			distance = ActivityMonitor.getInfo().distance/1000000;
			System.println(distance);
			if(!isDistanceMetric) {
				distance *= .621371;
			} 
			var distanceString;
			if(distance > 999) {
				distanceString = "999+";
			} else {
				distanceString = (distance).format("%.1f");
			}

			
			if(!Application.getApp().getProperty("ShowBoxes")) {
				distanceString = " " + distanceString;
			}

			drawTextBox(dc, distanceString, x, y, time_size[0], time_size[1]);
		}

		function drawBatteryBox(dc, x, y) {
			
			var battery = System.getSystemStats().battery;

			var batteryString = battery.format("%.0f");

			if(!Application.getApp().getProperty("ShowBoxes")) {
				batteryString = " " + batteryString;
			}

			drawTextBox(dc, batteryString, x, y, battery_size[0], battery_size[1]);
		}

		function drawTextBox(dc, text, x, y, boxWidth, boxHeight) {
			dc.setPenWidth(2);
			dc.setColor(COLORS[Application.getApp().getProperty("BoxColor")], Graphics.COLOR_WHITE);
			if(Application.getApp().getProperty("ShowBoxes")) {
				dc.drawRoundedRectangle(x, y, boxWidth, boxHeight, BOX_PADDING);
			}
			
			var boxText = new WatchUi.Text({
				:text=>text,
				:color=>COLORS[Application.getApp().getProperty("TextColor")],
				:font=> WatchUi.loadResource(Rez.Fonts.MainFont),
				:locX =>x + TEXT_PADDING[0],
				:locY=>y,
				:justification=>Graphics.TEXT_JUSTIFY_LEFT
			});

			boxText.draw(dc);
		}

		//Draws a text box with the time at a random point on the screen
		//Used for AMOLED devices to prevent burn-in
		function drawScreenSaver(dc) {
				var clockTime = System.getClockTime();
				var timeString = clockTime.hour + ":" + clockTime.min.format("%02d");
				var hour = clockTime.hour;
				var ssloc = SCREENSAVER_BOUNDS;
				var speed_mult = SCREENSAVER_SPEED_MULT;
				

				if((Application.getApp().getProperty("Use24HourFormat") == 2 || (Application.getApp().getProperty("Use24HourFormat") == 3 && !System.getDeviceSettings().is24Hour)) && hour > 12) {
					hour -= 12;
					timeString = hour + ":" + clockTime.min.format("%02d");
				}

				if(hour < 10) {
					timeString = "  " + timeString;
				}

				var pad = 150;
				ssloc[0] += status_box_size[0] * speed_mult[0];
				ssloc[1] += (status_box_size[1] + time_size[1]) * speed_mult[1];

				if(ssloc[0] <= pad) {
					ssloc[0] = pad;
					speed_mult[0] *= -1;
				} else if(ssloc[0] >= width-pad) {
					ssloc[0] = width-pad;
					speed_mult[0] *= -1;
				}

				if(ssloc[1] <= pad) {
					ssloc[1] = pad;
					speed_mult[1] *= -1;
				} else if(ssloc[1] >= width-pad) {
					ssloc[1] = width-pad;
					speed_mult[1] *= -1;
				}


				drawStatusBox(dc, ssloc[0], ssloc[1]);
				drawTextBox(dc, timeString, ssloc[0] - (time_size[0]/2), ssloc[1] - time_size[1], time_size[0], time_size[1]);
		}

		function drawNumber(dc, text, x, y) {

			var boxText = new WatchUi.Text({
				:text=>text,
				:color=> COLORS[Application.getApp().getProperty("ForegroundColor")],
				:font=>getNumberFont(width, Application.getApp().getProperty("NumberStyle")),
				:locX =>x,
				:locY=>y,
				:justification=>Graphics.TEXT_JUSTIFY_CENTER
			});

			boxText.draw(dc);
		}

		function drawNumberAngle(dc, angle, pad, num_text) {
			// updateNumberFontHeight();
			var number_font_height = GetNumberFontHeight(width, Application.getApp().getProperty("NumberStyle"));
			
			drawNumber(dc, num_text, width/2 + Math.round(Math.cos(Math.toRadians(angle)) * (width/2 - pad)), 
				width/2 + Math.round(Math.sin(Math.toRadians(angle)) * (width/2 - pad)) - number_font_height/2);
		}

		function updateBoxSizes() {
			if(width >= 390) {
				dow_size = DOW_SIZE_LARGE;
				date_size = DATE_SIZE_LARGE;
				time_size = TIME_SIZE_LARGE;
				floors_size = FLOORS_SIZE_LARGE;
				battery_size = BATTERY_SIZE_LARGE;
				status_box_size = STATUS_BOX_SIZE_LARGE;
			} else if (width >= 240){
				dow_size = DOW_SIZE_MEDIUM;
				date_size = DATE_SIZE_MEDIUM;
				time_size = TIME_SIZE_MEDIUM;
				floors_size = FLOORS_SIZE_MEDIUM;
				battery_size = BATTERY_SIZE_MEDIUM;
				status_box_size = STATUS_BOX_SIZE_MEDIUM;
			} else {
				dow_size = DOW_SIZE_SMALL;
				date_size = DATE_SIZE_SMALL;
				time_size = TIME_SIZE_SMALL;
				floors_size = FLOORS_SIZE_SMALL;
				battery_size = BATTERY_SIZE_SMALL;
				status_box_size = STATUS_BOX_SIZE_SMALL;
			}
		}

		function resetBufferedBitmap() {
			offScreenBuffer = new Graphics.BufferedBitmap({
				:width=>width,
				:height=>height,
			});
		}

		function clearBufferedBitmap() {
			offScreenBuffer = null;
		}

		// Called when this View is brought to the foreground. Restore
		// the state of this View and prepare it to be shown. This includes
		// loading resources into memory.
		function onShow() {
		}

		// Called when this View is removed from the screen. Save the
		// state of this View here. This includes freeing resources from
		// memory.
		function onHide() {
		}

		// The user has just looked at their watch. Timers and animations may be started here.
		function onExitSleep() {
			lowPower = false;
		}

		// Terminate any active timers and prepare for slow updates.
		function onEnterSleep() {
			lowPower = true;
		}
	
	}

	//Helpers go here
	public function getDateString(day) {
		return "Test";
	}

	public function getNumberFont(width, number_style) {
		if(number_style == 1) {
			return WatchUi.loadResource(Rez.Fonts.RomanFont);
		} else if(number_style == 2) {
			return WatchUi.loadResource(Rez.Fonts.CambriaFont);
		} else if(number_style == 3) {
			return WatchUi.loadResource(Rez.Fonts.CenturyFont);
		}
	}

	//These functions center an object between the end of the hour tick and the edge of the center circle
	public function centerOnLeft(size, number_style, tick_style, width) {
		if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)){
			return .1 * width + ((((.1 * width) - (width/2 - (RELATIVE_CENTER_RADIUS * width)))/2).abs() - size/2);
		}

		if(number_style == 3 && tick_style > 0) {
			return .15 * width + ((((.15 * width) - (width/2 - (RELATIVE_CENTER_RADIUS * width)))/2).abs() - size/2);
		}

		return (((width/2 - (RELATIVE_CENTER_RADIUS * width))/2).abs() - size/2);		
	}

	public function centerOnRight(size, number_style, tick_style, width) {

		if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)) {
			return width - .1 * width - ((((width - .1 * width) - (width/2 + (RELATIVE_CENTER_RADIUS * width)))/2).abs() + size/2);
		}

		if(number_style == 3 && tick_style > 0) {
			return width - .15 * width - ((((width - .15 * width) - (width/2 + (RELATIVE_CENTER_RADIUS * width)))/2).abs() + size/2);
		}
		
		return width - ((((width) - (width/2 + (RELATIVE_CENTER_RADIUS * width)))/2).abs() + size/2);
	}

	public function GetNumberFontHeight(width, number_style) {
		if(number_style == 1) {
			if(width >= 390) {
				return 39;
			} else if(width >= 240) {
				return 26;
			} else {
				return 22;
		}
		} else if(number_style == 2) {
			if(width >= 390) {
				return 54;
			} else if(width >= 240) {
				return 36;
			} else {
				return 30;
			}
		} else if(number_style == 3) {
			if(width >= 390) {
				return 51;
			} else if(width >= 240) {
				return 34;
			} else {
				return 28;
			}
		} else {
			return 0;
		}
	}

	public function GetShowNumsAt(number_style) {
		if(number_style == 1) {
			return true;
		} else if(number_style == 2) {
			return false;
		}
		return true;
	}
}