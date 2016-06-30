//
//  FTMutableDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 15.09.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSource.h"

@protocol FTMutableDataSource <FTDataSource>

#pragma mark Insertion
- (BOOL)canInsertItem:(id)item;
- (NSIndexPath *)insertItem:(id)item atProposedIndexPath:(NSIndexPath *)proposedIndexPath error:(NSError **)error;

#pragma mark Editing
- (BOOL)canEditItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Deletion
- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath error:(NSError **)error;

@end
