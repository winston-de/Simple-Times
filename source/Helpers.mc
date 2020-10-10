using Toybox.System;
using Toybox.WatchUi;

module Main {
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
		public static function centerOnLeft(size, number_style, tick_style, width) {
			if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)){
				return .1 * width + ((((.1 * width) - (width/2 - (RELATIVE_CENTER_RADIUS * width)))/2).abs() - size/2);
			}

			if(number_style == 3 && tick_style > 0) {
				return .15 * width + ((((.15 * width) - (width/2 - (RELATIVE_CENTER_RADIUS * width)))/2).abs() - size/2);
			}

			return (((width/2 - (RELATIVE_CENTER_RADIUS * width))/2).abs() - size/2);		
		}

		public static function centerOnRight(size, number_style, tick_style, width) {

			if(number_style == 1 || number_style == 2 || (number_style == 3 && tick_style == 0)) {
				return width - .1 * width - ((((width - .1 * width) - (width/2 + (RELATIVE_CENTER_RADIUS * width)))/2).abs() + size/2);
			}

			if(number_style == 3 && tick_style > 0) {
				return width - .15 * width - ((((width - .15 * width) - (width/2 + (RELATIVE_CENTER_RADIUS * width)))/2).abs() + size/2);
			}
			
			return width - ((((width) - (width/2 + (RELATIVE_CENTER_RADIUS * width)))/2).abs() + size/2);
		}
		
		public static function GetNumberFontHeight(width, number_style) {
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

		public static function GetShowNumsAt(number_style) {
			if(number_style == 1) {
				return true;
			} else if(number_style == 2) {
				return false;
			} else if(number_style == 3) {
				return true;
			}
		}
	}
}