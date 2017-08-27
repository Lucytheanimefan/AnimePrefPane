//
//  Anime.m
//  Anime
//
//  Created by Lucy Zhang on 8/19/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "Anime.h"
#import "AnimeRequester.h"
#import "CustomCell.h"


#import <os/log.h>


#define MAL @"MyAnimeList"

@implementation Anime
{
    NSArray <NSDictionary *> *malEntries;
}

@synthesize sources = _sources;


- (void)mainViewDidLoad
{
    _sourceTable.dataSource = self;
    _sourceTable.delegate = self;
    _outlineView.dataSource = self;
    _outlineView.delegate = self;
    
    malEntries = [[NSUserDefaults standardUserDefaults] objectForKey:@"malEntries"];
    //NSLog(@"User defaults: %@",[[NSUserDefaults standardUserDefaults] objectForKey:@"malEntries"]);
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
    NSString *username = _usernameField.stringValue;
    if ([source isEqualToString:MAL])
    {
        [_textView setString:@"Test MAL view"];
        if (!malEntries)
        {
            [[AnimeRequester sharedInstance] makeGETRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",username] withCompletion:^(NSDictionary * json) {
                malEntries = (NSArray *)json;
                [[NSUserDefaults standardUserDefaults] setObject:malEntries forKey:@"malEntries"];
                
                [self _reloadTable];
            }];
        }
        else
        {
            NSLog(@"Not reloading MAL data");
            [self _reloadTable];
        }
    }
}

- (void) _reloadTable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_outlineView reloadData];
    });
}

#pragma mark - NSOutlineView

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    NSLog(@"Expandable item? %hhd", [item isKindOfClass:[NSDictionary class]]);
    return ([item isKindOfClass:[NSDictionary class]]);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    NSString *label;
    NSLog(@"ITEM: %@", item);
    if (/*[item isKindOfClass:[NSDictionary class]] ||*/ !item)
    {
        return malEntries[index];
    }
    else if ([item isKindOfClass:[NSDictionary class]])
    {
        // it's a dictionary, not an array, fix
        switch (index) {
            case kIdentifier:
                label = [NSString stringWithFormat:@"%@", item[@"anime_id"]];
                break;
            case kAiringStatus:
                label = [NSString stringWithFormat:@"%@", item[@"airing_status"]];
                break;
            case kEpisodes:
                label = [NSString stringWithFormat:@"%@", item[@"total_episodes"]];
                break;
            case kScore:
                label = [NSString stringWithFormat:@"%@",item[@"user_score"]];
                break;
            case kStatus:
                label = [NSString stringWithFormat:@"%@", item[@"user_status"]];
                break;
            case kWatchedEps:
                label = [NSString stringWithFormat:@"%@", item[@"watched_episodes"]];
                break;
            default:
                label = @"None";
                break;
        }
    }
    return label;
}

#pragma mark - NSOutlineView Data Source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // MAL entry
    if ([item isKindOfClass:[NSDictionary class]])
    {
        return 6;
    }
    else
    {
        return malEntries.count;
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item
{
    NSTableCellView *cellView;
    if ([item isKindOfClass:[NSDictionary class]])
    {
        cellView = [outlineView makeViewWithIdentifier:@"AnimeEntry" owner:nil];
        cellView.textField.stringValue = item[@"title"];
    }
    else
    {
        cellView = [outlineView makeViewWithIdentifier:@"AnimeEntry" owner:nil];
        cellView.textField.stringValue = item;
    }
    return cellView;
}

@end
