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
    return self.sources.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CustomCell *view = [[CustomCell alloc] init];
    view.title.stringValue = self.sources[row];
    
    return view;
}

@end
