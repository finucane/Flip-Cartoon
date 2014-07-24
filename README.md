Flip Cartoon is an app that I wrote just as sample code, for prospective employers to look at.

The idea is not original (a simple animation app) but it was interesting enough to write for fun. It's a 2-D graphics program, which is a good excuse to write object-oriented code. The graphics data is all stored as vectors in Core Data. There's a feature that generates a .mov file (which is a good excuse to use some low level AVFoundation calls). And there's a feature that sends the .mov file to email or facebook etc, which is a good excuse to use the iOS APIs sharing (Activity Sheets).

It uses iAds. Also it has some In-App Purchases which enable features. There's a tiny bit of concurrency. When the cartoon is rendered into a .mov file, that's done off the main thread. There's no explicit networking because the email and facebook features are all done by high-level iOS calls. I wrote the app in 3 weeks after not having done any iOS work in over a year. In retrospect the main design flaw is that all of the Core Data is done on the main thread.

For the most part I avoided using the property / class extension idiom because it's actually fewer lines of code to use the built in language features for doing object oriented programming (instance variables and the private keyword), especially since you get the dot notation syntax for free anyway, when you write accessors by hand.

iOS Frameworks:

Core Data
Core Graphics
iAds
In-App Purchases
Activity Sheets
AVAsset
NSUndoManager
Architecture

