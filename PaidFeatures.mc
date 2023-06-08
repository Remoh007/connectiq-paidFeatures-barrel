import Toybox.Lang;
import Toybox.Application;
import Toybox.System;

module PaidFeatures {

    //! Returns the generated unique device identifier
    public function uniqueDeviceIdentifier() as String {
        return System.getDeviceSettings().uniqueIdentifier.substring(0, 8);
    }

    //! Returns the current email from the settings
    public function getEmail() as String {
        var email = "";
        try {
            email = Application.Properties.getValue("PaidFeatureEmail");
        } catch (ex instanceof Application.Properties.InvalidKeyException) {
            email = "";
        } catch (ex instanceof Lang.UnexpectedTypeException) {
            email = "";
        }
        return email;
    }

    //! Returns the current code from the settings
    public function getCurrentUnlockCode() as String {
        var currentSettingsCode = "";
        try {
            currentSettingsCode = Application.Properties.getValue("PaidFeatureUnlockCode");
        } catch (ex instanceof Application.Properties.InvalidKeyException) {
            currentSettingsCode = "";
        } catch (ex instanceof Lang.UnexpectedTypeException) {
            currentSettingsCode = "";
        }
        return currentSettingsCode;
    }

    //! Checks if a feature is unlocked and returns true if it is unlocked
    //! Notice: the Manager needs to be defined as featureManager in the AppBase as public var
    //! @param featureName name of the feature
    public function isUnlocked(featureName as String) as Boolean {
        var manager = Application.getApp().featureManager;
        for (var i=0; i<manager.features.size(); i++) {
            var feature = (manager.features as Array<Feature>)[i];
            if (feature.name.toString().hashCode() == featureName.toString().hashCode()) {
                return feature.unlocked;
            }
        }
        return false;
    }


    //! Manages the Features and their locked status
    class Manager extends Object {
        public var features = [] as Array<Feature>;

        //! Adds a feature to the features array
        public function addFeature(feature as Feature) as Void {
            features.add(feature);
        }

        //! Removes a feature from the feature array
        public function removeFeature(feature as Feature) as Void {
            features.remove(feature);
        }


        //! Checks all codes entered by the user via the ConnectIQ App settings page
        //! and unlocks the correct features
        public function unlockFeatures() as Void {
            // Get the Array of unlockCodes from the storage
            var storedUnlockCodes = getStoredUnlockCodes();
            // Get the current code from the settings
            var currentSettingsCode = getCurrentUnlockCode();

            // Go through the list of all features and check if the currentSettingsCode or one of the stored codes matches
            for (var i=0;i<features.size(); i++) {
                // Go through the stored unlock codes
                for (var j=0; j<storedUnlockCodes.size(); j++) {
                    if ((features as Array<Feature>)[i].verify(storedUnlockCodes[j].toString())) {
                        (features as Array<Feature>)[i].unlock();
                    }
                }

                // Check the current settings code
                if ((features as Array<Feature>)[i].verify(currentSettingsCode)) {
                    (features as Array<Feature>)[i].unlock();
                    addCodeToStoredCodes(currentSettingsCode.toString());
                }
            }
        }

        //! Returns the array of unlock codes stored on the device
        private function getStoredUnlockCodes() as Array<String> {
            var codes = Storage.getValue("PaidFeatureUnlockCodes") as Array<String>;
            if ( codes == null) {
                return [];
            }
            return codes;
        }


        //! Adds the code to the storage unlockCodes but avoids duplicates
        //! @param code the code to be added
        //! Returns true for a successfully stored code and false if something went wrong
        private function addCodeToStoredCodes(code as String) as Boolean {
            // If the code is an empty string, just return here and do nothing
            if (code == "") {
                return false;
            }
            var storedUnlockCodes = getStoredUnlockCodes();

             // That code is already in the storage => just return here and do nothing
            if (storedUnlockCodes.indexOf(code) != -1) {
                return false;
            }
            // Add the code to the array
            storedUnlockCodes.add(code);
            // Save the array to the storage
            Application.Storage.setValue("PaidFeatureUnlockCodes", storedUnlockCodes);
            return true;
        }

        //! Checks if a feature is unlocked and returns true if it is unlocked
        //! @param featureName name of the feature
        public function isUnlocked(featureName as String) as Boolean {
            for (var i=0; i<features.size(); i++) {
                var feature = (features as Array<Feature>)[i];
                if (feature.name.equals(featureName)) {
                    return feature.unlocked;
                }
            }
            return false;
        }

        //! Deletes all codes from storage and settings and locks all features
        public function cleanAllCodes() as Void {
            // Set Storage to empty array
            Application.Storage.setValue("PaidFeatureUnlockCodes", []);
            // Set settings code to empty string
            Application.Properties.setValue("PaidFeatureUnlockCode", "");
            // Unlock all features
            for (var i=0; i<features.size(); i++) {
                (features as Array<Feature>)[i].lock();
            }
        }


    }

    //! Defines a Feature with it's unlocking code
    class Feature extends Object {
        public var name as String;
        public var code as Code;
        public var unlocked = false;

        //! Constructor
        //! @param featureName String to identify the Feature by its name
        //! @param unlockCode Code to unlock the feature
        public function initialize(featureName as String, unlockCode as Code) {
            name = featureName;
            code = unlockCode;
        }

        //! Uses the Code's verify method to verify a code phrase for this feature
        //! @param code the code string to check
        //! returns true if the code was valid
        public function verify(code as String) as Boolean {
            return self.code.verify(code);
        }

        //! Unlocks the feature
        public function unlock() as Void {
            unlocked = true;
        }

        //! locks the feature
        public function lock() as Void {
            unlocked = false;
        }

        //! String representation of the Feature
        public function toString() as Lang.String {
            return name.toString() + " [" + unlocked.toString() + "]";
        }

    }

    //! Defines an unlock Code
    class Code extends Object {
        private var phrase as String;
        private var type as Number;

        //! Constructor
        //! @param codePhrase secure phrase for this Code
        //! @param codeType defines how the code is tied to a device or user
        public function initialize(codePhrase as String, codeType as Number) {
            phrase = codePhrase;
            type = codeType;
        }

        //! Verifies a code phrase
        //! @param code the code string to check
        //! returns true if the code was valid
        public function verify(code as String) as Boolean {
            // Check for a CODE_TYPE.GLOBAL
            if (type == CODE_TYPE.GLOBAL) {
                // Just comparing the phrase with the code
                return code.equals(phrase);
            }

            if (type == CODE_TYPE.DEVICE) {
                // compares the generatedDeviceCode with the code
                return code.equals(generateDeviceCode({}));
            }

            if (type == CODE_TYPE.EMAIL) {
                // if there is no email set in the settings it returns always false
                if (PaidFeatures.getEmail().equals("")) {
                    return false;
                }
                // compares the generatedEmailCode with the code
                return code.equals(generateEmailCode({}));
            }
            return false;
        }

        //! Generates an unlock code for a device bounded Code
        //! options
        //! @param :uniqueIdentifier the unique identifier for the device
        //! @param :publicCode the Code phrase used when creating the Code object
        //! returns The String that needs to be entered in the settings to unlock the Feature/Code
        public function generateDeviceCode(options as {:uniqueIdentifier as String, :publicCode as String}) as String {
            var uniqueIdentifier = options.get(:uniqueIdentifier) != null ? options.get(:uniqueIdentifier) : uniqueDeviceIdentifier();
            var publicCode = options.get(:publicCode) != null ? options.get(:publicCode) : phrase;
            var hash_id = uniqueIdentifier.hashCode();
            var hash_publicCode = publicCode.hashCode();

            var value = (hash_id * hash_publicCode).abs();
            return value.toString();
        }
        //! Generates an unlock code for an email bounded Code
        //! options
        //! @param :email the email address for this user
        //! @param :publicCode the Code phrase used when creating the Code object
        //! returns The String that needs to be entered in the settings to unlock the Feature/Code
        public function generateEmailCode(options as {:email as String, :publicCode as String}) as String {
            var email = options.get(:email) != null ? options.get(:email) : getEmail();
            var publicCode = options.get(:publicCode) != null ? options.get(:publicCode) : phrase;
            var hash_email = email.hashCode();
            var hash_publicCode = publicCode.hashCode();

            var value = (hash_email * hash_publicCode).abs();
            return value.toString();
        }
    }

    //! ENUM Class for the type of Code
    class CODE_TYPE {
        const GLOBAL = 1; // Using the Code's phrase directly to unlock the feature
        const DEVICE = 2; // Using the Device's id to generate a String to unlock the feature => the code is tied to the device
        const EMAIL = 3; // Using the Email to generate a String to unlock the feature => the code is tied to this email
    }


    

}
