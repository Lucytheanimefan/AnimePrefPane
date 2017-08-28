//
//  Anime.m
//  Anime
//
//  Created by Lucy Zhang on 8/19/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "Anime.h"
#import "AnimeRequester.h"
#import "Constants.h"
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

@interface Anime()

@property (nonatomic, assign, readwrite) NSDictionary *CRUserInfo;
@property (nonatomic, assign, readwrite) NSString *currentSource;
@property (nonatomic) NSArray *sources;
@property (nonatomic) NSArray <NSDictionary *> *malEntries;

@end


@implementation Anime
{
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
    
    
    [_usernameField setTarget:self];
    [_usernameField setAction:@selector(setUsername:)];
    
    malUsername = (NSString *)([[NSUserDefaults standardUserDefaults] objectForKey:@"malUsername"]);
    crUsername = (NSString *)([[NSUserDefaults standardUserDefaults] objectForKey:@"crUsername"]);
    
    _usernameField.stringValue = malUsername;
    
    NSString *malRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"malLastRefresh"] ;
    if (malRefreshDate)
    {
        _lastRefreshDateLabel.stringValue = malRefreshDate;
    }
    
    // Select the first source (MAL)
    [_sourceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
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

- (NSString *)currentSource
{
    NSInteger row = [_sourceTable selectedRow];
    if (!row || row < 0)
    {
        row = 0;
    }
    //NSLog(@"Row: %ld", (long)row);
    _currentSource = self.sources[row];
    return _currentSource;
}

-(NSArray<NSDictionary *> *)malEntries
{
    if (!_malEntries)
    {
        _malEntries = [[NSUserDefaults standardUserDefaults] objectForKey:@"malEntries"];
    }
    return _malEntries;
}

- (NSDictionary *)CRUserInfo
{
    NSDictionary *info = [[NSUserDefaults standardUserDefaults]objectForKey:@"crUserInfo"];
    NSLog(@"Info: %@", info);
    NSLog(@"CRUserInfo: %@", _CRUserInfo);
    if (!_CRUserInfo && info)
    {
        _CRUserInfo = info;
    }
    return _CRUserInfo;
}

- (IBAction)triggerNotification:(NSButton *)sender {

    // Temporary, switch to XPC once you get that working
    NSDictionary *userInfo = @{@"shouldScan":@(sender.state == NSOnState)};
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MALAgentCenter object:nil userInfo:userInfo deliverImmediately:YES];
}

- (IBAction)refresh:(NSButton *)sender {
    if ([self.currentSource isEqualToString:MAL])
    {
        [[AnimeRequester sharedInstance] makeGETRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",malUsername] withCompletion:^(NSDictionary * json) {
            
            //_malEntries = (NSArray *)json;
            [[NSUserDefaults standardUserDefaults] setObject:(NSArray *)json forKey:@"malEntries"];
            
            [self _reloadTable];
            [self _updateLastRefreshForKey:@"malLastRefresh"];
        }];
    }
    else if ([self.currentSource isEqualToString:CrunchyRoll])
    {
        [[AnimeRequester sharedInstance] makeGETRequest:@"crunchyroll" withParameters:[NSString stringWithFormat:@"username=%@",crUsername] withCompletion:^(NSDictionary * json) {

            [[NSUserDefaults standardUserDefaults]setObject:json forKey:@"crUserInfo"];
            [self _reloadTable];
            [self _updateLastRefreshForKey:@"crLastRefresh"];
        }];

    }
    else
    {
        NSLog(@"Nothing to refresh");
    }
}

- (void) _updateLastRefreshForKey:(NSString *)key
{
    NSString *lastRefresh = [[NSDate date] description];
    [[NSUserDefaults standardUserDefaults]setObject:lastRefresh forKey:key];
    _lastRefreshDateLabel.stringValue = [[NSDate date] description];
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
        
        NSURL *imageURL = [[NSBundle mainBundle] URLForImageResource:self.sources[row]];
        view.iconImage.image = [[NSImage alloc] initWithContentsOfURL:imageURL];
        
        [view.sourceTitle setStringValue:self.sources[row]];
        
        return view;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //BOOL timeToRefresh = !malEntries || false;//true; // TODO
    if ([self.currentSource isEqualToString:MAL])
    {
        _usernameField.stringValue = malUsername;
        //        if (timeToRefresh)
        //        {
        //            [[AnimeRequester sharedInstance] makeGETRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",malUsername] withCompletion:^(NSDictionary * json) {
        //                malEntries = (NSArray *)json;
        //                [[NSUserDefaults standardUserDefaults] setObject:malEntries forKey:@"malEntries"];
        //
        //                [self _reloadTable];
        //            }];
        //        }
        //        else
        //        {

        [self _reloadTable];
        //}
    }
    else if ([self.currentSource isEqualToString:CrunchyRoll])
    {
        _usernameField.stringValue = crUsername;
        [self _reloadTable];
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
    if ([self.currentSource isEqualToString:MAL])
    {
        return ([item isKindOfClass:[NSDictionary class]]);
    }
    else if ([self.currentSource isEqualToString:CrunchyRoll])
    {
        return NO;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    AnimeEntry *entry = [[AnimeEntry alloc] init];
    if ([self.currentSource isEqualToString:MAL])
    {
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
            return self.malEntries[index];
        }
        
        return entry;
    }
    else if ([self.currentSource isEqualToString:CrunchyRoll])
    {
        // should just be the dictionary key - value pair
        entry.title = self.CRUserInfo.allKeys[index];
        entry.value = self.CRUserInfo.allValues[index];
        return entry;
    }
    return nil;
}

#pragma mark - NSOutlineView Data Source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // MAL entry
    if ([self.currentSource isEqualToString:MAL])
    {
        if ([item isKindOfClass:[NSDictionary class]])
        {
            return 6;
        }
        else
        {
            return self.malEntries.count;
        }
    }
    else if ([self.currentSource isEqualToString:CrunchyRoll])
    {
        return self.CRUserInfo.allKeys.count;
    }
    
    return 0;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item
{
    NSTableCellView *cellView;
    if ([self.currentSource isEqualToString:MAL])
    {
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
    }
    else if ([self.currentSource isEqualToString:CrunchyRoll])
    {
        if ([tableColumn.identifier isEqualToString:@"AnimeEntryColumn"])
        {
            cellView = [outlineView makeViewWithIdentifier:@"AnimeEntry" owner:nil];
            cellView.textField.stringValue = ((AnimeEntry *)item).title;
        }
        else if ([tableColumn.identifier isEqualToString:@"AnimeValueColumn"])
        {
            cellView = [outlineView makeViewWithIdentifier:@"AnimeValue" owner:nil];
            cellView.textField.stringValue = ((AnimeEntry *)item).value;

        }
    }
    return cellView;
}

@end


