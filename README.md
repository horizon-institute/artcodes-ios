Artcodes iOS
=================

Artcodes marks a paradigm shift in visual recognition, offering difference to discerning brands. We design visually beautiful images and encode them, resulting in the same interactivity as that of the QR code but with a more visually engaging and playful experience. Images can be the identical with unique codes or the opposite visually unique with identical codes. This interplay offers a new opportunity for visual interaction within, product, packaging, service and interaction design.

------------------------------------
Adding Artcodes to your project
====================================

#### Get it via [CocoaPods](http://cocoapods.org/)

In your project's **Podfile** add the artcodes pod:

```ruby
pod 'artcodes'
```

#### or download source code

1. Download the aestheticodes-ios repository as a [zip file](https://github.com/horizon-institute/aestheticodes-ios/archive/master.zip) or clone it
2. Copy the aestheticodes-ios/core sub-folder into your Xcode project
3. Download [OpenCV](http://opencv.org/downloads.html) framework and add it to your project
4. Download [JSONModel](https://github.com/icanzilb/JSONModel) and add it to your project

------------------------------------
Basic usage
====================================

Implement ArtcodeDelegate to handle a discovered marker. Marker codes are returned formatted like 1:1:3:3:4

```objective-c
#import "ArtcodeViewController.h"

-(void)markerFound:(NSString*)marker
{
    // Handle returned marker here
}
```

To create Artcode reader

```objective-c
#import "ArtcodeViewController.h"

// Create and configure experience settings
Experience* experience = [[Experience alloc] init];
experience.minRegions = 5;
experience.maxRegions = 5;
experience.checksumModulo = 3;

// Create ArtcodeViewController
ArtcodeViewController* viewController = [[ArtcodeViewController alloc] initWithExperience:experience delegate:delegate];

// Use viewController as appropriate. eg.
[self.navigationController pushViewController:viewController animated:true];
```
