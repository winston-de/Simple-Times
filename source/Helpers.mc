using Toybox.System;
using Toybox.WatchUi;

class Helpers {
	
	public static function getDateString(day) {
		return "Test";
	}

	public static function getMainFont(width) {
		if(width >= 390) {
			return WatchUi.loadResource(Rez.Fonts.BigFont);
		} else if (width >= 240){
			return WatchUi.loadResource(Rez.Fonts.MediumFont);
		} else {
			return WatchUi.loadResource(Rez.Fonts.MainFont);
		}
	}

	public static function getIconFont(width) {
		if(width >= 390) {
			return WatchUi.loadResource(Rez.Fonts.BigIconFont);
		} else if (width >= 240){
			return WatchUi.loadResource(Rez.Fonts.IconFont2);
		} else {
			return WatchUi.loadResource(Rez.Fonts.IconFont);
		}
	}

	public static function getNumberFont(width, number_style) {
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

	//These functions center an object between the end of the hour tick and the edge of the center circle
	function centerOnLeft(size, number_style, tick_style, width) {
		if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)){
			return .1 * width + ((((.1 * width) - (width/2 - (Constants.relative_center_radius * width)))/2).abs() - size/2);
		}

		if(number_style == 3 && tick_style > 0) {
			return .15 * width + ((((.15 * width) - (width/2 - (Constants.relative_center_radius * width)))/2).abs() - size/2);
		}

		return (((width/2 - (Constants.relative_center_radius * width))/2).abs() - size/2);		
	}

	function centerOnRight(size, number_style, tick_style, width) {

		if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)) {
			return width - .1 * width - ((((width - .1 * width) - (width/2 + (Constants.relative_center_radius * width)))/2).abs() + size/2);
		}

		if(number_style == 3 && tick_style > 0) {
			return width - .15 * width - ((((width - .15 * width) - (width/2 + (Constants.relative_center_radius * width)))/2).abs() + size/2);
		}

		return width - ((((width) - (width/2 + (Constants.relative_center_radius * width)))/2).abs() + size/2);
	}
}