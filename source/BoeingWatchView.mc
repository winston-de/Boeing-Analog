using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time.Gregorian;

class BoeingWatchView extends WatchUi.WatchFace {
	// var boeingLogo;
	// var plane_front;
	var lowPower = false;
	var offScreenBuffer;
    var is24;
	var isDistanceMetric;
    var clip;
	var partialUpdates = true;
	var showTicks;
	var mainFont;
	var needsProtection = false;
	var lowMemDevice = false;
	var RBD = 0;
	var version;
	var showBoxes;
	
    //relative to width percentage
	var relative_tick_stroke = .01;
    var relative_hour_tick_length = .08;
    var relative_min_tick_length = .04;
    var relative_hour_tick_stroke = .04;
    var relative_min_tick_stroke = .04;
    
    var relative_hour_hand_length = .20;
    var relative_min_hand_length = .40;
    var relative_sec_hand_length = .42;
    var relative_hour_hand_stroke = .013;
    var relative_min_hand_stroke = .013;
    var relative_sec_hand_stroke = .01;

	var relative_padding = .03;
    var relative_padding2 = .01;
    
    var relative_center_radius = .025;
    
    var relative_plane_y = .542;
    var relative_logo_y = .167;

	var text_padding = [1, 2];
	var box_padding = 2;
	var dow_size = [44, 19];
	var date_size = [24, 19];
	var time_size = [48, 19];
	var floors_size = [40, 19];
	var battery_size = [32, 19];

	
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
		partialUpdates = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
		
		//Due to the maximum memory usage being to low for devices with displays of 260px, buffered bitmaps and partial updates must be disabled
		if(System.getSystemStats().totalMemory <= 95000 && dc.getWidth() > 240) {
			lowMemDevice = true;
			partialUpdates = false;
		}

		//To prevent a crash, only check for burn in protection if the device has that flag
		if( System.getDeviceSettings() has :requiresBurnInProtection && System.getDeviceSettings().requiresBurnInProtection) {
				needsProtection = true;
				partialUpdates = false;
		}

		System.println(System.getDeviceSettings() has :requiresBurnInProtection);

		//Only use a buffered bitmap if the device has the memory capability
		//Also, turn off partial updates if the device can't use buffered bitmaps
		if(!lowMemDevice && !needsProtection) {
			offScreenBuffer = new Graphics.BufferedBitmap({
					:width=>dc.getWidth(),
					:height=>dc.getHeight(),
			});
		} else {
			partialUpdates = false;
		}

		if(dc.getHeight() >= 390) {
			//increase the size of resources so they are visible on the Venu
			mainFont = WatchUi.loadResource(Rez.Fonts.BigFont);
			dow_size = [44 * 1.5, 19* 1.5];
			date_size = [24* 1.5, 19* 1.5];
			time_size = [48* 1.5, 19* 1.5];
			floors_size = [48* 1.5, 19* 1.5];
			battery_size = [32*1.5, 19*1.5];
		} else {
			mainFont = WatchUi.loadResource(Rez.Fonts.MainFont);
		}
		updateValues();

    }

    // Update the view
    function onUpdate(dc) { 
		if(needsProtection && lowPower) {
			dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
			dc.clear();
			updateValues();
			drawScreenSaver(dc);
		} else {
			var clockTime = System.getClockTime();
			var hours = clockTime.hour;
			var minutes = clockTime.min;
			var seconds = clockTime.sec;
			var width = dc.getWidth();

			updateValues();
			dc.clearClip();

			if(partialUpdates) {
				drawBackground(offScreenBuffer.getDc());
				dc.drawBitmap(0, 0, offScreenBuffer);
			} else {
				drawBackground(dc);
			}
				

			if( (partialUpdates && !lowPower) || partialUpdates && lowPower) {
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
				drawSecondHandClip(dc, 60, seconds, relative_sec_hand_length*width, relative_sec_hand_stroke*width);
			} else if(lowMemDevice && !lowPower) {
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
				drawHand(dc, 60, seconds, relative_sec_hand_length*width, relative_sec_hand_stroke*width);
			}

			dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
			dc.fillCircle(dc.getWidth()/2-1, dc.getHeight()/2-1, 6);
		}
    }
    
    //partial updates
    function onPartialUpdate(dc) {
		if(partialUpdates) {
			var clockTime = System.getClockTime();
			var hours = clockTime.hour;
			var minutes = clockTime.min;
			var seconds = clockTime.sec;        
			var width = dc.getWidth();
			
			
			dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
			drawSecondHandClip(dc, 60, seconds, relative_sec_hand_length*width, relative_sec_hand_stroke*width);
			
			dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
			dc.fillCircle(width/2-1, dc.getHeight()/2-1, relative_center_radius*width);
		}
    }
    
	//use this to update values controlled by settings
	function updateValues() {
		var UMF = Application.getApp().getProperty("Use24HourFormat");
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

		showTicks = Application.getApp().getProperty("ShowTicks");
		RBD = Application.getApp().getProperty("RightBoxDisplay1");
		showBoxes = Application.getApp().getProperty("ShowBoxes");

		if(!lowMemDevice && !needsProtection && Application.getApp().getProperty("AlwaysOn")) {
			partialUpdates = true;
		} else {
			partialUpdates = false;
		}
		
		if(!showTicks) {
			relative_sec_hand_length = .46;
			relative_hour_hand_length = .23;
			relative_min_hand_length = .46;
		} else {
			relative_hour_hand_length = .20;
   			relative_min_hand_length = .40;
			relative_sec_hand_length = .42;
		}

	}

	function drawBackground(dc) {
		var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        var seconds = clockTime.sec;
        var width = dc.getWidth();
        var height = dc.getHeight();
        
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    	dc.clear();
		//The plane and logo bitmaps are loaded and drawn seperatley to decrease peak memory usage
		drawPlane(dc);
		drawLogo(dc);
    	
		if(showTicks) {
    		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    		drawTicks(dc, relative_hour_tick_length*width, relative_hour_tick_stroke*width, 12);
    		drawTicks(dc, relative_min_tick_length*width, relative_min_tick_stroke*width, 60);
		}

    	drawDate(dc, centerOnLeft(dc, dow_size[0] + 4 + date_size[0]), width/2 - dow_size[1]/2);	
		drawBox(dc);
    	
    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    	drawHandOffset(dc, 12.00, 60.00, hours, minutes, relative_hour_hand_length*width, relative_hour_hand_stroke*width);
    	
    	drawHand(dc, 60, minutes, relative_min_hand_length*width, relative_min_hand_stroke*width);
	}

	//These functions center an object between the end of the hour tick and the edge of the center circle
	function centerOnLeft(dc, size) {
		var width = dc.getWidth();
		return relative_hour_tick_length * width + ((((relative_hour_tick_length * width) - (width/2 - (relative_center_radius * width)))/2).abs() - size/2);
	}

	function centerOnRight(dc, size) {
		var width = dc.getWidth();
		return width - relative_hour_tick_length * width - ((((width - relative_hour_tick_length * width) - (width/2 + (relative_center_radius * width)))/2).abs() + size/2);
	}

	function drawPlane(dc) {
		var plane;
		var width = dc.getWidth();
		if(dc.getHeight() >= 390) {
			plane = new WatchUi.Bitmap({:rezId=>Rez.Drawables.LargePlane});

		} else {
			plane = new WatchUi.Bitmap({:rezId=>Rez.Drawables.Plane});
		}

		plane.setLocation(dc.getWidth()/2 - plane.width/2, dc.getHeight()*relative_plane_y);
		plane.draw(dc);
	}

	function drawLogo(dc) {
		var logo;
		var width = dc.getWidth();
		if(dc.getHeight() >= 390) {
			logo = new WatchUi.Bitmap({:rezId=>Rez.Drawables.LargeLogo});

		} else {
			logo = new WatchUi.Bitmap({:rezId=>Rez.Drawables.Logo});
		}
		
		logo.setLocation(dc.getWidth()/2 - logo.width/2, dc.getHeight()*relative_logo_y);
		logo.draw(dc);
	}
	
	function drawBox(dc) {
		var width = dc.getWidth();
		if(RBD == 1) {
			var x = centerOnRight(dc, time_size[0]);
    		var y = dc.getWidth()/2 - (time_size[1])/2;
			drawTimeBox(dc, x, y);
		}

		if(RBD == 2) {
			var x = centerOnRight(dc, time_size[0]);
    		var y = dc.getWidth()/2 - (time_size[1])/2;
			drawStepBox(dc, x, y);
		}

		if(RBD == 3) {
			var x = centerOnRight(dc, floors_size[0]);
    		var y = dc.getWidth()/2 - (floors_size[1])/2;
			drawFloorsBox(dc, x, y);
		}

		if(RBD == 4) {
			var x = centerOnRight(dc, time_size[0]);
    		var y = dc.getWidth()/2 - (time_size[1])/2;
			drawCaloriesBox(dc, x, y);
		}

		if(RBD == 5) {
			var x = centerOnRight(dc, time_size[0]);
    		var y = dc.getWidth()/2 - (time_size[1])/2;
			drawDistanceBox(dc, x, y);
		}

		if(RBD == 6) {
			var x = centerOnRight(dc, battery_size[0]);
    		var y = dc.getWidth()/2 - (battery_size[1])/2;
			drawBatteryBox(dc, x, y);
		}
	}
    
    function drawTicks(dc, length, stroke, num) {
		dc.setPenWidth(dc.getWidth() * relative_tick_stroke);
    	var tickAngle = 360/num;
    	var center = dc.getWidth()/2;
    	for(var i = 0; i < num; i++) {
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

    function drawHand(dc, num, time, length, stroke) {
    	var angle = Math.toRadians((360/num) * time) - Math.PI/2;
    	
    	var center = dc.getWidth()/2;
    	
    	dc.setPenWidth(stroke);
    	
    	var x = center + Math.round((Math.cos(angle) * length));
    	var y = center + Math.round((Math.sin(angle) * length));
    	
    	dc.drawLine(center, center, x, y);
    	
    }
    
    function drawSecondHandClip(dc, num, time, length, stroke) {
		dc.drawBitmap(0, 0, offScreenBuffer);

    	var angle = Math.toRadians((360/num) * time) - Math.PI/2;
    	var center = dc.getWidth()/2;
    	dc.setPenWidth(stroke);
    	
    	var cosval = Math.round(Math.cos(angle) * length);
    	var sinval = Math.round(Math.sin(angle) * length);
    	
    	var x = center + cosval;
    	var y = center + sinval;
    	var width = dc.getWidth();
    	var height = dc.getHeight();
    	var width2 = (center-x).abs();
    	var height2 = (center-y).abs();
    	var padding = width * relative_padding;
    	var padding2 = width * relative_padding2;
    	
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
    	

    	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    	dc.drawLine(center, center, x, y);
    	
    }
    
	//Draws a hand with an offset for a seperate time set (eg. hour hand)
    function drawHandOffset(dc, num, offsetNum, time, offsetTime, length, stroke) {
    	var angle = Math.toRadians((360/num) * time ) - Math.PI/2;
    	var section = 360.00/num/offsetNum;
    	
    	angle += Math.toRadians(section * offsetTime);
    	
    	var center = dc.getWidth()/2;
    	
    	dc.setPenWidth(stroke);
    	
    	var x = center + Math.round(Math.cos(angle) * length);
    	var y = center + Math.round(Math.sin(angle) * length);
    	
    	dc.drawLine(center, center, x, y);
    }

	function drawDate(dc, x, y) {
		var width = dc.getWidth();
		var height = dc.getHeight();
    	var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
		var dowString = info.day_of_week;
		
		drawTextBox(dc, dowString, x, y, dow_size[0], dow_size[1]);
		drawTextBox(dc, info.day.toString(), x + dow_size[0] + 4, y, date_size[0], date_size[1]);
    }
    
    function drawTimeBox(dc, x, y) {
		var width = dc.getWidth();
    	var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
    	var clockTime = System.getClockTime();
		var hours = clockTime.hour.format("%02d").toNumber();
		var hourString = hours;

		if(!is24 && hours > 12) {
			hours -= 12;
			hourString = hours;
		}

		drawTextBox(dc, hourString + ":" + clockTime.min.format("%02d"), x, y, time_size[0], time_size[1]);
    }
	
	function drawStepBox(dc, x, y) {
		var width = dc.getWidth();
		var steps = ActivityMonitor.getInfo().steps;
		var stepString;
		if(steps > 99999) {
			stepString = "99+k";
		} else {
			stepString = (steps.toDouble()/1000).format("%.1f") + "k";
		}
		// System.out.println(steps);

		drawTextBox(dc, stepString, x, y, time_size[0], time_size[1]);
	}

	function drawFloorsBox(dc, x, y) {
		var width = dc.getWidth();
		var floors;
		floors = ActivityMonitor.getInfo().floorsClimbed;

		var floorString;

		if(floors > 999) {
			floorString = "999+";
		} else {
			floorString = floors.toString();
		}

		// System.out.println(steps);

		drawTextBox(dc, floorString, x, y, floors_size[0], floors_size[1]);
	}

	function drawCaloriesBox(dc, x, y) {
		var width = dc.getWidth();
		var calories;
		calories = ActivityMonitor.getInfo().calories;

		var calorieString;
		if(calories > 99999) {
			calorieString = "99+k";
		} else {
			calorieString = (calories.toDouble()/1000).format("%0.1f") + "k";
		}

		// System.out.println(steps);

		drawTextBox(dc, calorieString, x, y, time_size[0], time_size[1]);
	}

	function drawDistanceBox(dc, x, y) {
		var width = dc.getWidth();
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

		drawTextBox(dc, distanceString, x, y, time_size[0], time_size[1]);
	}

	function drawBatteryBox(dc, x, y) {
		var width = dc.getWidth();
		var battery = System.getSystemStats().battery;

		var batteryString = battery.format("%.0f");

		drawTextBox(dc, batteryString, x, y, battery_size[0], battery_size[1]);
	}

	function drawTextBox(dc, text, x, y, width, height) {
		dc.setPenWidth(2);
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_WHITE);
		if(showBoxes) {
   			dc.drawRoundedRectangle(x, y, width, height, box_padding);
		}
    	
    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		var boxText = new WatchUi.Text({
            :text=>text,
            :color=>Graphics.COLOR_WHITE,
            :font=>mainFont,
            :locX =>x + text_padding[0],
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
			if(!is24 && clockTime.hour > 12) {
				timeString = (clockTime.hour - 12) + ":" + clockTime.min.format("%02d");
			}

			var pad = 40;
			var maxw = (dc.getWidth() - 70 - time_size[0]).toNumber(); 
			var maxh = (dc.getWidth() - 70 - time_size[1]).toNumber();
			var x = (Math.rand()%(maxw - pad)) + pad;
			var y = (Math.rand()%(maxh - pad)) + pad;
			drawTextBox(dc, timeString, x, y, time_size[0], time_size[1]);
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

class AnalogDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
//        partialUpdatesAllowed = false;
    }
}
