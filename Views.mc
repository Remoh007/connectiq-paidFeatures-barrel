import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Graphics;

module PaidFeatures {
        class BasicInfoMenuDelegate extends WatchUi.MenuInputDelegate {
        public function initialize() {
            WatchUi.MenuInputDelegate.initialize();
        }

        public function onMenuItem(item as Symbol) as Void {
            if (item == :deviceID) {
                WatchUi.pushView(new BasicInfoView(PaidFeatures.uniqueDeviceIdentifier()), null, WatchUi.SLIDE_LEFT);
            } else if (item == :currentCode) {
                WatchUi.pushView(new BasicInfoView(PaidFeatures.getCurrentUnlockCode()), null, WatchUi.SLIDE_LEFT);
            } else if (item == :email) {
                WatchUi.pushView(new BasicInfoView(PaidFeatures.getEmail()), null, WatchUi.SLIDE_LEFT);
            }
        }
    }

    class BasicInfoView extends WatchUi.View {
        private var mText = "";

        public function initialize(text as String) {
            WatchUi.View.initialize();
            mText = text;
        }

        public function onUpdate(dc) {
            if (mText.hashCode() == "".hashCode()) {
                mText = "-";
            }
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, selectCorrectFont(dc), mText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        private function selectCorrectFont(dc) as Graphics.FontType {
            var fontSelection = [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
            for (var i=0; i<fontSelection.size(); i++) {
                var textWidth = dc.getTextWidthInPixels(mText, fontSelection[i]);
                if (textWidth < dc.getWidth()) {
                    return fontSelection[i];
                }
            }
            return fontSelection[fontSelection.size()-1];
        }
    }

    class InfoView extends WatchUi.Menu2 {
        public function initialize() {
            WatchUi.Menu2.initialize({:title=> WatchUi.loadResource(Rez.Strings.PaidFeatureInfoViewTitle)});
            var code = PaidFeatures.getCurrentUnlockCode();
            var email = PaidFeatures.getEmail();

            addItem(new MenuItem(WatchUi.loadResource(
                Rez.Strings.PaidFeatureDeviceID), 
                PaidFeatures.uniqueDeviceIdentifier(), 
                "deviceID", null));

            addItem(new MenuItem(WatchUi.loadResource(
                Rez.Strings.PaidFeatureCurrentCode), 
                code.hashCode() == "".hashCode() ? "-": code, 
                "currentCode", null));

            addItem(new MenuItem(WatchUi.loadResource(
                Rez.Strings.PaidFeatureEmail_title), 
                email.hashCode() == "".hashCode() ? "-": email,
                "email", null));

        }
    }

    class InfoViewDelegate extends WatchUi.Menu2InputDelegate {
        public function initialize() {
            WatchUi.Menu2InputDelegate.initialize();
        }
    }
}