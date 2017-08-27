//
//  Anime.h
//  Anime
//
//  Created by Lucy Zhang on 8/19/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

typedef enum {
    kIdentifier = 0,
    kTitle,
    kAiringStatus,
    kEpisodes,
    kScore,
    kStatus,
    kWatchedEps
} MALKey;

@interface Anime : NSPreferencePane<NSTableViewDelegate, NSTableViewDataSource, NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (nonatomic) NSArray *sources;
@property (weak) IBOutlet NSTableView *sourceTable;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *usernameField;
@property (weak) IBOutlet NSOutlineView *outlineView;

- (void)mainViewDidLoad;

@end
