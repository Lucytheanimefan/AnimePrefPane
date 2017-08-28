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
#import "MALConnection.h"

#import <Foundation/Foundation.h>
#import <os/log.h>


#define MAL @"MyAnimeList"
#define CrunchyRoll @"Crunchyroll"


@interface AnimeEntry : NSObject

@property (assign, readwrite) NSString *title;
@property (assign, readwrite) NSString *value;

@end

@implementation AnimeEntry

@end


@implementation Anime
{
    NSArray <NSDictionary *> *malEntries;
    NSString *malUsername;
    NSString *crUsername;
}

@synthesize sources = _sources;


- (void)mainViewDidLoad
{
    _sourceTable.dataSource = self;
    _sourceTable.delegate = self;
    _outlineView.dataSource = self;
    _outlineView.delegate = self;
    
    malEntries = [[NSUserDefaults standardUserDefaults] objectForKey:@"malEntries"];
    
    [_usernameField setTarget:self];
    [_usernameField setAction:@selector(setUsername:)];
    
    malUsername = (NSString *)([[NSUserDefaults standardUserDefaults] objectForKey:@"malUsername"]);
    crUsername = (NSString *)([[NSUserDefaults standardUserDefaults] objectForKey:@"crUsername"]);
    
    _usernameField.stringValue = malUsername;
    
}

- (void)setUsername:(id)sender
{
    NSInteger row = [_sourceTable selectedRow];
    NSString *source = self.sources[row];
    
    if ([_usernameField.stringValue length] > 0)
    {
        if ([source isEqualToString:MAL])
        {
            malUsername = _usernameField.stringValue;
            [[NSUserDefaults standardUserDefaults] setObject:malUsername forKey:@"malUsername"];
        }
        else if ([source isEqualToString:CrunchyRoll])
        {
            crUsername = _usernameField.stringValue;
            [[NSUserDefaults standardUserDefaults] setObject:crUsername forKey:@"crUsername"];
        }
    }
}

- (NSArray *) sources
{
    if (!_sources)
    {
        _sources = @[@"MyAnimeList",@"Crunchyroll", @"Funimation"];
    }
    return _sources;
}

- (IBAction)triggerNotification:(NSButton *)sender {
    
    // Temporary, switch to XPC once you get that working
    NSDictionary *userInfo = @{@"shouldScan": @(sender.state == 1)};
    [[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"MyAnimeListAgent" object:nil userInfo:userInfo deliverImmediately:YES];
}


#pragma mark - NSTableViewDataSource

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
        
        // TODO: pick images
        NSURL *imageURL = [[NSBundle mainBundle] URLForImageResource:self.sources[row]];
        view.iconImage.image = [[NSImage alloc] initWithContentsOfURL:imageURL];
        
        [view.sourceTitle setStringValue:self.sources[row]];
        //[view.subtitle setStringValue:@"Test subtitle"];
        
        return view;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [_sourceTable selectedRow];
    NSString *source = self.sources[row];
    BOOL timeToRefresh = !malEntries || false;//true; // TODO
    if ([source isEqualToString:MAL])
    {
        _usernameField.stringValue = malUsername;
        if (timeToRefresh)
        {
            [[AnimeRequester sharedInstance] makeGETRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",malUsername] withCompletion:^(NSDictionary * json) {
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
    else if ([source isEqualToString:CrunchyRoll])
    {
        _usernameField.stringValue = crUsername;
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
    return ([item isKindOfClass:[NSDictionary class]]);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    AnimeEntry *entry = [[AnimeEntry alloc] init];
    
    if ([item isKindOfClass:[NSDictionary class]])
    {
        switch (index) {
            case kIdentifier:
                entry.value = [NSString stringWithFormat:@"%@", item[@"anime_id"]];
                entry.title = @"Anime Id";
                break;
            case kAiringStatus:
            {
                NSLog(@"Airing status type: %@", [item[@"airing_status"] className]);
                NSInteger airingStatus = [item[@"airing_status"] integerValue];
                switch (airingStatus) {
                    case 1:
                        entry.value = @"Airing";
                        break;
                    case 2:
                        entry.value = @"Aired";
                        break;
                    case 3:
                        entry.value = @"Not aired";
                        break;
                    default:
                        break;
                }

                entry.title = @"Airing Status";
                break;
            }
            case kEpisodes:

                entry.value = [NSString stringWithFormat:@"%@", item[@"total_episodes"]];
                entry.title = @"Total Episodes";
                break;
            case kScore:

                entry.value = [NSString stringWithFormat:@"%@",item[@"user_score"]];
                entry.title = @"Score";
                break;
            case kStatus:
            {
                NSInteger userStatus = [item[@"user_status"] integerValue];
                switch (userStatus) {
                    case 1:
                        entry.value = @"Watching";
                        break;
                    case 2:
                        entry.value = @"Completed";
                        break;
                    case 3:
                        entry.value = @"On hold";
                        break;
                    case 4:
                        entry.value = @"Dropped";
                        break;
                    case 6:
                        entry.value = @"Plan to watch";
                        break;
                    default:
                        break;
                }

                entry.title = @"User Status";
                break;
            }
            case kWatchedEps:
                entry.value = [NSString stringWithFormat:@"%@", item[@"watched_episodes"]];
                entry.title = @"Watched episodes";
                break;
            default:
                NSLog(@"Item for none: %@, index: %ld", item, (long)index);
                entry.value = @"None";
                entry.title = @"None";
                break;
        }
    }
    else
    {
        return malEntries[index];
    }
    
    return entry;
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
    if ([tableColumn.identifier isEqualToString:@"AnimeEntryColumn"])
    {
        cellView = [outlineView makeViewWithIdentifier:@"AnimeEntry" owner:nil];
        if ([item isKindOfClass:[NSDictionary class]])
        {
            cellView.textField.stringValue = item[@"title"];
        }
        else if ([item isKindOfClass:[AnimeEntry class]])
        {
            cellView.textField.stringValue = ((AnimeEntry *)item).title;
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"AnimeValueColumn"])
    {
        cellView = [outlineView makeViewWithIdentifier:@"AnimeValue" owner:nil];
        if ([item isKindOfClass:[AnimeEntry class]])
        {
            cellView.textField.stringValue = ((AnimeEntry *)item).value;
        }
        else
        {
            cellView.textField.stringValue = @"";
        }
    }
    return cellView;
}

@end


