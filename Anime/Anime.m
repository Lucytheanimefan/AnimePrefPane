//
//  Anime.m
//  Anime
//
//  Created by Lucy Zhang on 8/19/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "Anime.h"
#import "CustomCell.h"
#import <os/log.h>


#define MAL @"MyAnimeList"

@implementation Anime

@synthesize sources = _sources;


- (void)mainViewDidLoad
{
    _sourceTable.dataSource = self;
    _sourceTable.delegate = self;
}

- (NSArray *) sources
{
    if (!_sources)
    {
        _sources = @[@"MyAnimeList",@"Crunchyroll", @"Funimation"];
    }
    return _sources;
}

#pragma mark - NSTableViewDataSoruce

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSLog(@"%lu", (unsigned long)self.sources.count);
    return self.sources.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"Source"])
    {
        CustomCell *view = [tableView makeViewWithIdentifier:@"CustomCell" owner:nil];
        
         view.iconImage.image = [[NSImage alloc]initWithContentsOfFile:@"transparentapple.png"];
        
        [view.sourceTitle setStringValue:self.sources[row]];
        [view.subtitle setStringValue:@"Test subtitle"];

        return view;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [_sourceTable selectedRow];
    NSString *source = self.sources[row];
    if ([source isEqualToString:MAL])
    {
        [_textView setString:@"Test MAL view"];
    }
}

@end
