//
//  CustomCell.h
//  Anime
//
//  Created by Lucy Zhang on 8/20/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CustomCell : NSTableCellView

@property (assign) IBOutlet NSImageView *iconImage;

@property (assign) IBOutlet NSTextField *sourceTitle;

@property (assign) IBOutlet NSTextField *subtitle;




@end
