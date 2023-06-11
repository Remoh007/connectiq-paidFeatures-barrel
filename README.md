# ConnectIQ PaidFeatures Barrel
PaidFeatures is a Monkey C Barrel assisting you in managing unlockable features in a connectIQ project

| API     | Purpose                                                        |
| ------- | -------------------------------------------------------------- |
| Manager | Entry point to manage all Features and their locked status     |
| Feature | Defines a feature with it's specific unlock Code               |
| Code    | Defines an unlock Code and handles the concret unlocking       |

You can define three types of Features.

| CODE_TYPE | Purpose                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------ |
| GLOBAL    | The Code to unlock this Feature is working on any device for every user                          |
| DEVICE    | The Code is bound to a device. The Device Code needs to be provided to generate a Code           |
| EMAIL     | The Code is bound to an email address. The email address needs to be provided to generate a Code |

## Adding PaidFeatures to Your Project
See general instructions for [including Monkey Barrels](https://developer.garmin.com/connect-iq/core-topics/shareable-libraries/#shareablelibraries).

Use the barrel file provided from this repository and also copy the _paid_features.xml files from resources to your resources folder.  
The xml file is needed to enable the Settings, so the user can input codes to unlock features.

## Usage
Once PaidFeatures has been added to your project, import it into your code with an `import` statement in your AppBase file:

```
import PaidFeatures;
```

Create a new Manager object as a public variable.  
Add Features and their Codes in the onStart method.  
Let the manager unlock features in the onStart method and in the onSettingsChanged method.  

```
class PaidFeaturesExampleApp extends Application.AppBase {
    public var featureManager = new PaidFeatures.Manager();
    
    function onStart(state as Dictionary?) as Void {
        var codeForNewFeature = new PaidFeatures.Code("ITEM3", PaidFeatures.CODE_TYPE.GLOBAL);
        var newFeature = new PaidFeatures.Feature("Hidden Feature", codeForNewFeature);
        featureManager.addFeature(newFeature);
        featureManager.unlockFeatures();
    }

    function onSettingsChanged() as Void {
        featureManager.unlockFeatures();
    }
}
```

In your normal code, you then can check if the feature is unlocked and do your stuff.

```
if (Application.getApp().featureManager.isUnlocked("Hidden Feature")) {
    // Do your stuff
}
```

If you have implemented everything as described here. To check for a feature, you can use this shortcut:
```
if (PaidFeatures.isUnlocked("Hidden Feature")) {
    // Do your stuff
}
```
To provide the user the ability looking at the Informations needed use the provided Views.
```
if (WatchUi has :Menu2) {
    System.println("Show a modern Menu2");
    WatchUi.pushView(new @PaidFeatures.InfoView(), new @PaidFeatures.InfoViewDelegate(), WatchUi.SLIDE_LEFT);
} else {
    System.println("Show a basic Menu");
    WatchUi.pushView(new @PaidFeatures.Rez.Menus.BasicInfoMenu(), new PaidFeatures.BasicInfoMenuDelegate(), WatchUi.SLIDE_LEFT);
}
```

## Creating Unlock Codes
Always make sure that the code phrase used for a Feature will not be publically known!  
For GLOBAL Codes the phrase itself is the unlock code.
For DEVICE Codes, the user needs to provide you with the uniqueDeviceIdentifier which can be retrieved with `Paidfeatures.uniqueDeviceIdentifier()`  
FOR EMAIL Codes, the user needs to provide you with the email he has set in the settings.
  
After the user sent you his uniqueDeviceIdentifier or email address, you can use the  
```
Code.generateDeviceCode({
    :uniqueIdentifier => "HisIdentifier", 
    :publicCode => "ThePhraseYouUsedWhenCreatingTheCode"
    });
```
or 
```
Code.generateEmailCode({
    :email => "UsersEmailAddress@test.com",
    :publicCode => "ThePhraseYouUsedWhenCreatingTheCode"
    });
``` 
You can also write your own python or js code to create the codes. Just take a look at the source code in the PaidFeatures.mc file.  
  
Now, you can send the user the generated Code, so he can unlock the Feature via the Settings.
## Example
Look at this [basic example](https://github.com/Remoh007/connectiq-paidFeatures-example) to see how you can use the Barrel.
There it is used to show/hide Menu items, providing users more or less features in the App.

## Documentation
Please take a look at the comments in the PaidFeatures.mc file. Hopefully everything should be clear.  
To create a Code, the first param is the codePhrase (for GLOBAL codes this is the unlock code).  
The second param is the Type of the Code.  
  
To create a Feature, the first param is a String providing the name, you will later use to check the status for the Feature.  
The second param is the a Code object.

