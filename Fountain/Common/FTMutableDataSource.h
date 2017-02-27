//
//  FTMutableDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 15.09.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Availability.h>
#import "FTDataSource.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@protocol FTMutableDataSource <FTDataSource>

#pragma mark Insertion
- (BOOL)canInsertItem:(id)item;
- (NSIndexPath *)insertItem:(id)item atProposedIndexPath:(NSIndexPath *)proposedIndexPath error:(NSError **)error;

#pragma mark Editing
- (BOOL)canEditItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Deletion
- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath error:(NSError **)error;

#if TARGET_OS_IOS
@optional
- (NSArray<UITableViewRowAction *> *)editActionsForRowAtIndexPath:(NSIndexPath *)indexPath;
#endif

@end
