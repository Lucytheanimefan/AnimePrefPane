//
//  Anime.h
//  Anime
//
//  Created by Lucy Zhang on 8/19/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface Anime : NSPreferencePane

@property (weak) IBOutlet NSOutlineView *sourceList;

- (void)mainViewDidLoad;

@end
