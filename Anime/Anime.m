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
        _sources = @[@"Crunchyroll", @"Funimation"];
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
    NSView *view = [tableView makeViewWithIdentifier:@"CustomCell" owner:nil];

    ((CustomCell *)view).sourceTitle.stringValue = self.sources[row];
    NSLog(@"Source: %@", self.sources[row]);
    ((CustomCell *)view).subtitle.placeholderString = @"TEST";

    NSLog(@"title: %@, subtitle: %@", ((CustomCell *)view).sourceTitle.stringValue, ((CustomCell *)view).subtitle.stringValue);
    
    NSLog(@"Placeholders: %@", ((CustomCell *)view).sourceTitle.placeholderString);

    return view;
}

@end
