#Swift Radio

Swift Radio is an open source radio station app with robust and professional features. This is a fully realized Radio App built entirely in Swift 2.

![alt text](http://matthewfecher.com/wp-content/uploads/2015/09/screen-1.jpg "Swift Radio")

##Video
View this [**GETTING STARTED VIDEO**](https://youtu.be/m7jiajCHFvc).
It's short & sweet to give you a quick overview.  
Give it a quick watch.

##Features

- LastFM API Integration to automatically download Album Art
- Loads and parses metadata (Track & Artist information)
- Current Artist & Track displayed on Stations page
- Displays Artist, Track, & Album Art on Lock Screen
- Ability to update playlist from server or locally. (Update stations anytime without resubmitting to app store!)
- Custom views optimized for iPhone 4s, 5, 6 and 6+ for backwards compatibility
- Compiles with Xcode 7 & Swift 2.0
- Background audio performance
- Supports local or hosted station images
- "About" page with ability to send email & visit website
- Uses industry standard SwiftyJSON library for easy JSON manipulation
- Pull to Refresh Stations

##Important Notes

- LastFM is working on their API signups. So, you may have trouble signing up for a LastFM key today, hopefully they fix that soon. More info in FAQ below.  
- Volume slider does not work in Simulator, only in device. This appears to be an Xcode issue.  
- The App works better in devices than it does in the Simulator.
- Radio stations in demo are for demonstration purposes only. 
- For a production product, you may want to swap out the MPMoviePlayerController for a more robust streaming library/SDK (with stream stitching, interruption handling, etc).
- Uses Meng To's [Spring](https://github.com/MengTo/Spring) library for animation, making it easy experiment with different UI/UX animations
- SwiftyJSON & Spring are included in the repo to get you up & running quickly. It's on the roadmap to utilize CocoaPods in the future. 

##Credits
*Created by [Matthew Fecher](http://matthewfecher.com), Twitter: [@goFecher](http://twitter.com/goFecher)*  
*Thanks to Basel Farag, from [Denver Swift Heads](http://www.meetup.com/Denver-Swift-Heads/) for the code review.*  

##Requirements

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 7

##Setup

The "SwiftRadio-Settings.swift" file contains some project settings to get you started. Please enter your own LastFM Key.  
Watch this [Getting Started Video](https://youtu.be/m7jiajCHFvc) to get up & running quickly.

##Integration

Includes full Xcode Project to jumpstart development.

##Stations 

Includes an example "stations.json" file. You may upload the JSON file to a server, so that you can update the stations in the app without resubmitting to the app store. The following fields are supported in the app:

- **name**: The name of the station as you want it displayed (e.g. "Sub Pop Radio")

- **streamURL**: The url of the actual stream

- **imageURL**: Station image url. Station images in demo are 350x206. Image can be local or hosted. Leave out the "http" to use a local image (You can use either: "station-subpop" or "http://myurl.com/images/station-subpop.jpg")

- **desc**: Short 2 or 3 word description of the station as you want it displayed (e.g. "Outlaw Country")

- **longDesc**: Long description of the station to be used on the "info screen". This is optional.

##Contributions

Contributions are very welcome. Please create a separate branch (e.g. features/3dtouch). Please do not commit on master.

##FAQ

Q: Do I have to pay you anything if I make an app with this code?  
A: Nope. This is completely open source, you can do whatever you want with it. It's usually cool to thank the project if you use the code. Go build stuff. Enjoy.

Q: The LastFM site isn't working properly? I can't create an API key.  
A: Official word from LastFM "the team are working to add support as soon as possible". 

Q: How do I disable LastFM?  
A: Simply comment out the method call to "queryAlbumArt()" in the NowPlayingViewController (approx. line #520).

Q: Is there another API to get album/track information besides LastFM?  
A: Rovi has a pretty sweet [music API](http://prod-doc.rovicorp.com/mashery/index.php/Data/APIs/Rovi-Music). The [Echo Nest](http://developer.echonest.com/) has all kinds of APIs that are fun to play with. 

Q: My radio station isn't playing?  
A: Paste your stream URL into a browser to see if it will play there. The stream may be offline or have a weak connection.

Q: The song names aren't appearing for my station?  
A: Check with your stream provider to make sure they are sending Metadata properly. If a station sends data in a unique way, you can modify the way the app parses the metadata in the "metadataUpdated" method in the NowPlayingViewController.

Q: Sometimes the station desc does not disappear when the album art loads?  
A: We are working on that, thank you for your patience.

##Streaming Libraries

- You can use this Swift code as a front-end for a more robust streaming backend.
- In addition to the MPMoviePlayer, I've briefly tested it with the following two streaming libraries (and it works rather nicely): [RadioKit](http://stormyprods.com/products/radiokit.php) & [Radio](https://github.com/hamedh/Radio) 
- If you test it with a library, let me know!
