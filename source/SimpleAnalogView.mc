using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time.Gregorian;

class SimpleAnalogView extends WatchUi.WatchFace {
	var offScreenBuffer;
    var clip;
	var constants;

	var background_color;
	var foreground_color;
	var box_color;
	var second_hand_color;
	var hour_min_hand_color;
	var text_color;

	var RBD = 0;
	var tick_style;
	var number_style;
	var hand_style;
	var showTicks;
	var number_font_height;

	var lowPower = false;
	var needsProtection = false;
	var lowMemDevice = false;
	var partialUpdates = false;
	var is24;
	var isDistanceMetric;
	var showSecondHand;

	var showBoxes;
	var show_min_ticks;
	var show_nums_at;
	var date_on_right;
	var show_status_bar;
	
	//The universal watchface width and height values
	var width;
	var height;

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
		constants = new Constants();
		
		width = dc.getWidth();
		height = dc.getHeight();

        //Due to the maximum memory usage being to low for devices with displays of 260px, buffered bitmaps and partial updates must be disabled
		if((width >= 220 && System.getSystemStats().totalMemory < 95000) || !(Graphics has :BufferedBitmap) || !(dc has :clearClip)) {
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

			if(showSecondHand) {
				drawSecondHand(dc);
			}

			dc.setColor(box_color, Graphics.COLOR_TRANSPARENT);
			dc.fillCircle(width/2-1, height/2-1, constants.relative_center_radius*width);
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
		var app = Application.getApp();
		var UMF = app.getProperty("Use24HourFormat");
		if(UMF == 0) {
			is24 = true;
		}
		if(UMF == 1) {
			is24 = false;
		}
		if(UMF == 2) {
			is24 = System.getDeviceSettings().is24Hour;
		}

		var distanceMetric = System.getDeviceSettings().distanceUnits;
		if(distanceMetric == System.UNIT_METRIC) {
			isDistanceMetric = true;
		} else {
			isDistanceMetric = false;
		}

		// showTicks = app.getProperty("ShowTicks");
		RBD = app.getProperty("RightBoxDisplay1");
		showBoxes = app.getProperty("ShowBoxes");

		var always_on = app.getProperty("AlwaysOn");


		background_color = getColor(app.getProperty("Background"));
		foreground_color = getColor(app.getProperty("ForegroundColor"));
		box_color = getColor(app.getProperty("BoxColor"));
		second_hand_color = getColor(app.getProperty("SecondHandColor"));
		hour_min_hand_color = getColor(app.getProperty("HourMinHandColor"));
		text_color = getColor(app.getProperty("TextColor"));
		tick_style = app.getProperty("TickStyle");
		show_min_ticks = app.getProperty("ShowMinTicks");
		show_status_bar = app.getProperty("ShowStatusBar");
		date_on_right = app.getProperty("DateOnRight");
		number_style = app.getProperty("NumberStyle");
		hand_style = app.getProperty("HandStyle");
		showSecondHand = app.getProperty("ShowSecondHand");

		// if(!lowMemDevice && !partialUpdates && !needsProtection && (always_on && showSecondHand)) {
		// 	partialUpdates = true;
		// 	resetBufferedBitmap();
		// } else if((!always_on && !showSecondHand) || (always_on && !showSecondHand && !needsProtection)) {
		// 	partialUpdates = false;
		// 	clearBufferedBitmap();
		// } else if(!always_on && showSecondHand) {

		// }

		if(!lowMemDevice && !partialUpdates && !needsProtection && (always_on && showSecondHand)) {
			partialUpdates = true;
			resetBufferedBitmap();
		} else if(!needsProtection && !lowMemDevice && (!always_on || !showSecondHand)) {
			partialUpdates = false;
			clearBufferedBitmap();
		}

		if(needsProtection && always_on) {
			partialUpdates = true;
		} else if(needsProtection && !always_on) {
			partialUpdates = false;
		}

		// if(always_on && !lowMemDevice) {
		// 	partialUpdates = true;
		// } else {
		// 	partialUpdates = false;
		// }

		if(tick_style == 0) {
			showTicks = false;
		} else {
			showTicks = true;
		}
	}

	function drawBackground(dc) {
    	dc.setColor(background_color, background_color);
    	dc.clear();
		drawTicks(dc);
		drawNumbers(dc);
		drawBox(dc);
		drawDateBox(dc);

		if(show_status_bar) {
			drawStatusBox(dc, width/2, centerOnLeft(status_box_size[1]));
		}
    	
		drawHands(dc);		
	}

	//Draws the correct ticks for the user's settings
	function drawTicks(dc) {
		var draw_numbers = false;

		if(number_style > 0) {
			draw_numbers = true;
		}

		dc.setColor(foreground_color, Graphics.COLOR_TRANSPARENT);
		if(tick_style == 1) {
			if(show_min_ticks) {
				drawDashTicks(dc, constants.relative_hour_tick_length*width, constants.relative_hour_tick_stroke*width, 12, draw_numbers, true);
    			drawDashTicks(dc, constants.relative_min_tick_length*width, constants.relative_min_tick_stroke*width, 60, draw_numbers, false);
			} else {
				drawDashTicks(dc, constants.relative_min_tick_length*width, constants.relative_min_tick_stroke*width, 12, draw_numbers, true);
			}
		} else if(tick_style == 2) {
			if(show_min_ticks) {
				drawTicksCircle(dc, constants.relative_hour_circle_tick_size*width, 1, 12, draw_numbers, true);
    			drawTicksCircle(dc, constants.relative_min_circle_tick_size*width, 1, 60, draw_numbers, false);
			} else {
				drawTicksCircle(dc, constants.relative_min_circle_tick_size*width, 1, 12, draw_numbers, true);
			}
		} else if(tick_style == 3) {
			if(show_min_ticks) {
				drawTicksTriangle(dc, constants.relative_hour_triangle_tick_size*width, 1, 12, draw_numbers, true);
    			drawTicksTriangle(dc, constants.relative_min_triangle_tick_size*width, 1, 60, draw_numbers, false);
			} else {
				drawTicksTriangle(dc, constants.relative_min_triangle_tick_size*width, 1, 12, draw_numbers, true);
			}
		}
	}

	//Draws the correct numbers for the user's settings
	function drawNumbers(dc) {
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

		var hour_hand_length = constants.relative_hour_hand_length;
		var min_hand_length = constants.relative_min_hand_length;

		if(!showTicks) {
			hour_hand_length = constants.relative_hour_hand_length_extended;
			min_hand_length = constants.relative_min_hand_length_extended;
		}

		dc.setColor(hour_min_hand_color, Graphics.COLOR_TRANSPARENT);

		if(hand_style == 0) {
    		drawLineHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.25, constants.relative_hour_hand_stroke*width);
    		drawLineHand(dc, 60, minutes, 0, 0, min_hand_length*width, constants.relative_min_hand_stroke*width);
		} else if(hand_style == 1) {
			drawCircleHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.25, constants.relative_hour_hand_stroke*width);
    		drawCircleHand(dc, 60, minutes, 0, 0, min_hand_length*width, constants.relative_min_hand_stroke*width);
		} else if(hand_style == 2) {
			drawLongArrowHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.75, constants.relative_hour_hand_stroke*width);
    		drawLongArrowHand(dc, 60, minutes, 0, 0, min_hand_length*width, constants.relative_min_hand_stroke*width);
		} else if(hand_style == 3) {
			drawArrowHand(dc, 12.00, hours, 60,  minutes, hour_hand_length*width*1.25, constants.relative_hour_hand_stroke*width);
    		drawArrowHand(dc, 60, minutes, 0, 0, min_hand_length*width, constants.relative_min_hand_stroke*width);
		}
	}

	//Draws the correct information box for the user's settings
	function drawBox(dc) {
		
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
		if(date_on_right) {
    		drawDate(dc, centerOnRight(dow_size[0] + 4 + date_size[0]), width/2 - dow_size[1]/2);	
		} else {
			drawDate(dc, centerOnLeft( dow_size[0] + 4 + date_size[0]), width/2 - dow_size[1]/2);	
		}
	}


	//These functions center an object between the end of the hour tick and the edge of the center circle
	function centerOnLeft(size) {
		

		// if(tick_style == 1) {
		// 	return constants.relative_hour_tick_length * width + ((((constants.relative_hour_tick_length * width) - (width/2 - (constants.relative_center_radius * width)))/2).abs() - size/2);
		// }

		// if(number_style == 1) {
		// 	return .1 * width + ((((.1 * width) - (width/2 - (constants.relative_center_radius * width)))/2).abs() - size/2);
		// }

		if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)){
			return .1 * width + ((((.1 * width) - (width/2 - (constants.relative_center_radius * width)))/2).abs() - size/2);
		}

		if(number_style == 3 && tick_style > 0) {
			return .15 * width + ((((.15 * width) - (width/2 - (constants.relative_center_radius * width)))/2).abs() - size/2);
		}

		return (((width/2 - (constants.relative_center_radius * width))/2).abs() - size/2);		
	}

	function centerOnRight(size) {

		if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)) {
			return width - .1 * width - ((((width - .1 * width) - (width/2 + (constants.relative_center_radius * width)))/2).abs() + size/2);
		}

		if(number_style == 3 && tick_style > 0) {
			return width - .15 * width - ((((width - .15 * width) - (width/2 + (constants.relative_center_radius * width)))/2).abs() + size/2);
		}

		// if(showTicks) {
		// 	return width - constants.relative_hour_tick_length * width - ((((width - constants.relative_hour_tick_length * width) - (width/2 + (constants.relative_center_radius * width)))/2).abs() + size/2);
		// }

		return width - ((((width) - (width/2 + (constants.relative_center_radius * width)))/2).abs() + size/2);
	}

	//takes a number from settings and converts it to the assosciated color
	function getColor(num) {
		if(num == 0) {
			return Graphics.COLOR_BLACK;
		}

		if(num == 1) {
			return Graphics.COLOR_WHITE;
		}

		if(num == 2) {
			return Graphics.COLOR_LT_GRAY;
		}

		if(num == 3) {
			return Graphics.COLOR_DK_GRAY;
		}

		if(num == 4) {
			return Graphics.COLOR_BLUE;
		}

		if(num == 5) {
			return 0x02084f;
		}

		if(num == 6) {
			return Graphics.COLOR_RED;
		}

		if(num == 7) {
			return 0x730000;
		}

		if(num == 8) {
			return Graphics.COLOR_GREEN;
		}

		if(num == 9) {
			return 0x004f15;
		}

		if(num == 10) {
			return 0xAA00FF;
		}

		if(num == 11) {
			return Graphics.COLOR_PINK;
		}

		if(num == 12) {
			return Graphics.COLOR_ORANGE;
		}

		if(num == 13) {
			return Graphics.COLOR_YELLOW;
		}

		return null;
	}

	function getBoxLocX(width) {
		if(!date_on_right) {
			return centerOnRight(width);
		}
		return centerOnLeft(width);
	}

    function drawDashTicks(dc, length, stroke, num, draw_numbers, hour_ticks) {
		dc.setPenWidth(width * constants.relative_tick_stroke);
    	var tickAngle = 360/num;
    	var center = width/2;
		
    	for(var i = 0; i < num; i++) {
			var diff = 2;
			var cond1 = (!(i < diff || i > 60-diff) 
					&& !(i > 15-diff && i < 15+diff) 
					&& !(i > 30-diff && i < 30+diff) 
					&& !(i > 45-diff && i < 45+diff));

			if(show_nums_at) {
				cond1 = true;
			}

			if(number_style == 1) {
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

			if(show_nums_at) {
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
		dc.setPenWidth(width * constants.relative_tick_stroke);
    	var tickAngle = 360/num;
    	var center = width/2;
    	for(var i = 0; i < num; i++) {
			var diff = 2;
			var cond1 = (!(i < diff || i > 60-diff) 
					&& !(i > 15-diff && i < 15+diff) 
					&& !(i > 30-diff && i < 30+diff) 
					&& !(i > 45-diff && i < 45+diff));
			
			if(show_nums_at) {
				cond1 = true;
			}
			var cond2 = draw_numbers && hour_ticks && !(i == 0 || i == 3 || i == 6 || i == 9);

			if(show_nums_at) {
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
		dc.setPenWidth(width * constants.relative_tick_stroke);
    	var tickAngle = 360/num;
    	var center = width/2;
    	for(var i = 0; i < num; i++) {
			var diff = 2;
			var cond1 = (!(i < diff || i > 60-diff) 
					&& !(i > 15-diff && i < 15+diff) 
					&& !(i > 30-diff && i < 30+diff) 
					&& !(i > 45-diff && i < 45+diff));
			if(show_nums_at) {
				cond1 = true;
			}
			var cond2 = draw_numbers && hour_ticks && !(i == 0 || i == 3 || i == 6 || i == 9);

			if(show_nums_at) {
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
		
		if(tick_style == 1 || tick_style == 0 || !show_min_ticks) {
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

		if(tick_style != 0 && show_min_ticks) {
			pad = 0.09*width;
		}

		if(tick_style == 2 && show_min_ticks) {
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

		var x2 = center + Math.round((Math.cos(angle - Math.toRadians(90)) * (constants.relative_center_radius/2) * width));
		var y2 = center + Math.round((Math.sin(angle - Math.toRadians(90)) * (constants.relative_center_radius/2) * width));

		var x3 = center + Math.round((Math.cos(angle + Math.toRadians(90)) * (constants.relative_center_radius/2) * width));
		var y3 = center + Math.round((Math.sin(angle + Math.toRadians(90)) * (constants.relative_center_radius/2) * width));

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
			(Math.cos(angle - Math.toRadians(90)) * (constants.relative_center_radius*width*.7)));
		var y = center + Math.round((Math.sin(angle) * (length - end_multiplier*width)) + 
			(Math.sin(angle - Math.toRadians(90)) * (constants.relative_center_radius*width*.7)));

		var x2 = center + Math.round((Math.cos(angle) * length));
		var y2 = center + Math.round((Math.sin(angle) * length));

		var x3 = center + Math.round((Math.cos(angle) * (length - end_multiplier*width)) + 
			(Math.cos(angle + Math.toRadians(90)) * (constants.relative_center_radius*width*.7)));
		var y3 = center + Math.round((Math.sin(angle) * (length - end_multiplier*width)) + 
			(Math.sin(angle + Math.toRadians(90)) * (constants.relative_center_radius*width*.7)));

		var x4 = center + Math.round((Math.cos(angle + Math.toRadians(90)) * (constants.relative_center_radius/2) * width));
		var y4 = center + Math.round((Math.sin(angle + Math.toRadians(90)) * (constants.relative_center_radius/2) * width));

		var x5 = center + Math.round((Math.cos(angle - Math.toRadians(90)) * (constants.relative_center_radius/2) * width));
		var y5 = center + Math.round((Math.sin(angle - Math.toRadians(90)) * (constants.relative_center_radius/2) * width));

		dc.fillPolygon([[x, y], [x2, y2], [x3, y3], [x4, y4], [x5, y5]]);
	}

	function drawSecondHand(dc) {
		var clockTime = System.getClockTime();
		var hours = clockTime.hour;
		var minutes = clockTime.min;
		var seconds = clockTime.sec;
		var sec_hand_length = constants.relative_sec_hand_length;

		if(!showTicks) {
			sec_hand_length = constants.relative_sec_hand_length_extended;
		}

		dc.setColor(second_hand_color, Graphics.COLOR_TRANSPARENT);
		if(partialUpdates && !needsProtection) {
			drawSecondHandClip(dc, 60, seconds, sec_hand_length * width, constants.relative_sec_hand_stroke*width);
		} else if(!lowPower) {
			drawLineHand(dc, 60, seconds, 0, 0, sec_hand_length * width, constants.relative_sec_hand_stroke*width);
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
    	var padding = width * constants.relative_padding;
    	var padding2 = width * constants.relative_padding2;
    	
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

    	dc.setColor(second_hand_color, Graphics.COLOR_TRANSPARENT);
    	dc.drawLine(center, center, x, y);    

		dc.setColor(box_color, Graphics.COLOR_TRANSPARENT);
		dc.fillCircle(width/2-1, height/2-1, constants.relative_center_radius*width);	
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
    	dc.setColor(box_color, Graphics.COLOR_WHITE);
    	
		var boxText = new WatchUi.Text({
            :text=>status_string,
            :color=>text_color,
            :font=>getIconFont(),
            :locX =>x + constants.text_padding[0],
            :locY=>y,
			:justification=>Graphics.TEXT_JUSTIFY_CENTER
        });

		boxText.draw(dc);
    }

	function drawDate(dc, x, y) {
		
		
    	var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
		var dowString = info.day_of_week;
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

		if(!is24 && hours > 12) {
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

		if(!showBoxes) {
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

		
		if(!showBoxes) {
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

		if(!showBoxes) {
			calorieString = " " + calorieString;
		}

		// System.out.println(steps);

		drawTextBox(dc, calorieString, x, y, time_size[0], time_size[1]);
	}

	function drawDistanceBox(dc, x, y) {
		
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

		
		if(!showBoxes) {
			distanceString = " " + distanceString;
		}

		drawTextBox(dc, distanceString, x, y, time_size[0], time_size[1]);
	}

	function drawBatteryBox(dc, x, y) {
		
		var battery = System.getSystemStats().battery;

		var batteryString = battery.format("%.0f");

		if(!showBoxes) {
			batteryString = " " + batteryString;
		}

		drawTextBox(dc, batteryString, x, y, battery_size[0], battery_size[1]);
	}

	function drawTextBox(dc, text, x, y, width, height) {
		dc.setPenWidth(2);
    	dc.setColor(box_color, Graphics.COLOR_WHITE);
		if(showBoxes) {
   			dc.drawRoundedRectangle(x, y, width, height, constants.box_padding);
		}
    	
		var boxText = new WatchUi.Text({
            :text=>text,
            :color=>text_color,
            :font=>getMainFont(),
            :locX =>x + constants.text_padding[0],
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
			var ssloc = constants.screensaver_bounds;
			var speed_mult = constants.screensaver_speed_mult;
			

			if(!is24 && hour > 12) {
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
            :color=>foreground_color,
            :font=>getNumberFont(),
            :locX =>x,
            :locY=>y,
			:justification=>Graphics.TEXT_JUSTIFY_CENTER
        });

		boxText.draw(dc);
	}

	function drawNumberAngle(dc, angle, pad, num_text) {
		updateNumberFontHeight();
		
		drawNumber(dc, num_text, width/2 + Math.round(Math.cos(Math.toRadians(angle)) * (width/2 - pad)), 
			width/2 + Math.round(Math.sin(Math.toRadians(angle)) * (width/2 - pad)) - number_font_height/2);
	}

	function getNumberFont() {
		var number_font = WatchUi.loadResource(Rez.Fonts.CambriaFontMedium);

		if(number_style == 1) {
			if(width >= 390) {
				return WatchUi.loadResource(Rez.Fonts.RomanFontLarge);
			} else if(width >= 240) {
				return WatchUi.loadResource(Rez.Fonts.RomanFontMedium);
			} else {
				return WatchUi.loadResource(Rez.Fonts.RomanFontSmall);
			}
		} else if(number_style == 2) {
			if(width >= 390) {
				return WatchUi.loadResource(Rez.Fonts.CambriaFontLarge);
			} else if(width >= 240) {
				return WatchUi.loadResource(Rez.Fonts.CambriaFontMedium);
			} else {
				return WatchUi.loadResource(Rez.Fonts.CambriaFontSmall);
			}
		} else if(number_style == 3) {
			show_nums_at = true;
			if(width >= 390) {
				return WatchUi.loadResource(Rez.Fonts.CenturyFontLarge);
			} else if(width >= 240) {
				return WatchUi.loadResource(Rez.Fonts.CenturyFontMedium);
			} else {
				return WatchUi.loadResource(Rez.Fonts.CenturyFontSmall);
			}
		}

		return number_font;
	}

	function updateNumberFontHeight() {
		if(number_style == 1) {
			show_nums_at = true;
			if(width >= 390) {
				number_font_height = 39;
			} else if(width >= 240) {
				number_font_height = 26;
			} else {
				number_font_height = 22;
			}
		} else if(number_style == 2) {
			show_nums_at = false;
			if(width >= 390) {
				number_font_height = 54;
			} else if(width >= 240) {
				number_font_height = 36;
			} else {
				number_font_height = 30;
			}
		} else if(number_style == 3) {
			show_nums_at = true;
			if(width >= 390) {
				number_font_height = 51;
			} else if(width >= 240) {
				number_font_height = 34;
			} else {
				number_font_height = 28;
			}
		} else {
			number_font_height = 0;
		}
	}

	function getIconFont() {
		if(width >= 390) {
			return WatchUi.loadResource(Rez.Fonts.BigIconFont);
		} else if (width >= 240){
			return WatchUi.loadResource(Rez.Fonts.IconFont2);
		} else {
			return WatchUi.loadResource(Rez.Fonts.IconFont);
		}
	}

	function getMainFont() {
		if(width >= 390) {
			return WatchUi.loadResource(Rez.Fonts.BigFont);
		} else if (width >= 240){
			return WatchUi.loadResource(Rez.Fonts.MediumFont);
		} else {
			return WatchUi.loadResource(Rez.Fonts.MainFont);
		}
	}

	function updateBoxSizes() {
		if(width >= 390) {
			dow_size = constants.dow_size_large;
			date_size = constants.date_size_large;
			time_size = constants.time_size_large;
			floors_size = constants.floors_size_large;
			battery_size = constants.battery_size_large;
			status_box_size = constants.status_box_size_large;
		} else if (width >= 240){
			dow_size = constants.dow_size_medium;
			date_size = constants.date_size_medium;
			time_size = constants.time_size_medium;
			floors_size = constants.floors_size_medium;
			battery_size = constants.battery_size_medium;
			status_box_size = constants.status_box_size_medium;
		} else {
			dow_size = constants.dow_size_small;
			date_size = constants.date_size_small;
			time_size = constants.time_size_small;
			floors_size = constants.floors_size_small;
			battery_size = constants.battery_size_small;
			status_box_size = constants.status_box_size_small;
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
