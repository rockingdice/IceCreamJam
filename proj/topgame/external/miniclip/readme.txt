Please find attached the McUtils library that gives you the Rate It popup implementation and our Newsfeed functionality.

MCUtils depends on the following libraries:
UIKit.framework
SystemConfiguration.framework
StoreKit.framework
Foundation.framework
AdSupport.framework - weak reference
Make sure they are in the dependencies of you project.

-----
The Rate Popup is our own custom implementation that does not require any art.
If you check the Rate.h you will see that you need to call [Rate startWithDelegate: andAppId:] as soon as possible.

When you want the rate popup to be shown, you can call [Rate showRatePopup].
If it returns true, then the popup will be visible.
if it returns false, then one of the internal tests failed and you should proceed with the execution.
You can use other methods in the delegate to customize your behavior. It should be relatively straightforward.
Call this method after the player has a positive experience (after every win, level success, level up, etc…) to make sure you have as many 5 star reviews as possible.
 
All the following tests are made internally so that you don't need to do them:
- maximum of views per version
- minimum time in session
- at most once per session
- if player has rated, will not show until there is an update
- will not show in the first session

As for text, you can use:
title: Love Jelly Mania?
msg: Please rate it on the App Store./ Please rate it on Google Play.
Buttons: Not yet/Rate it!

-----
The MCPostman is the service we use to show promotional messages to the user.  For now, please implement only the urgent messages section.
 
Add the header files and the lib in the zip provided to the project.
Add the following key to the info.plist
"MCDeveloperKey" with value "FBNEwdfwYwFge24"
Only the com.naughtycat.jellymania bundle id is supported.

To startup the MCPostman
Please make sure you have the "-all_load" and "-ObjC" linker flags set.
As soon as possible, make the following calls (do not change the order).
#ifdef DEBUG
[MCPostman setSandbox:YES] // YES for DEBUG builds and NO for AppStore builds
#else
[MCPostman setSandbox:NO]
#endif
[MCPostman setLaunchOptions:] // the dictionary that is provided in [ application: didFinishLaunchingWithOptions:]
[MCPostman setShowBadge:YES];
[MCPostman shouldLog:YES]; // will log a lot of debug information into the console. Useful during implementation
[MCPostman startWithDelegate:]; // should not be nil
MCPostmanDelegate
- no mandatory implementation

To show urgent messages
- when the user presses a button, before sending the player to the next menu, call [MCPostman showUrgentBoard] .
- if it returns false, you are free to proceed into the next menu
- if it returns true, then a news item will be shown and the game should stop and wait until boardDidDisappear is called in the delegate. This is when the urgent message closes.
- After the board disappears, we should force a click on the button that the player clicked originally so that the user does not have to click it again.

To show non-urgent messages
if([MCPostman nrOfMessages] > 0) {
// show button that will allow user to see the news items
// when the user presses that button, call [MCPostman showBoard] and wait until boardDidDisappear is called in the delegate
}

Chartboost iOS:

App ID: 534268b589b0bb1786071338
App Signature: 415f5d325036c2142e7a4c54167a09f757993d42

Chartboost Android
App ID: 534269e21873da14ffb9e3dc
App Signature: 2e1d7086a0bb535f9800a0a9265b160381a6e287

The AD-X SDK and documentation are attached to this email.
Client ID: miniclip35678jo
URL Referrer ID: ADX1734

Flurry iOS:
App Key: HHWXWQTSZZZX8CVT55T4
Flurry Android:
App Key: H9QRD7RKXWQF9K84FCVC


