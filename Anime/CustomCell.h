//
//  CustomCell.h
//  Anime
//
//  Created by Lucy Zhang on 8/20/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CustomCell : NSTableCellView

@property (nonatomic, weak) IBOutlet NSImageView *iconImage;

@property (nonatomic, weak) IBOutlet NSTextField *title;

@property (nonatomic, weak) IBOutlet NSTextField *subtitle;



@end
