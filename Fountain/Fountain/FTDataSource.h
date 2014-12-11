//
//  FTDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTDataSourceObserver <NSObject>
@optional

#pragma mark Reload
- (void)reload;

#pragma mark Perform Batch Update
- (void)performBatchUpdate:(void (^)(void))update;

#pragma mark Manage Sections
- (void)insertSections:(NSIndexSet *)sections;
- (void)deleteSections:(NSIndexSet *)sections;
- (void)reloadSections:(NSIndexSet *)sections;
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection;

#pragma mark Manage Items
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

@end

#pragma mark -

@protocol FTDataSource <NSObject>

#pragma mark Getting Item and Section Metrics
- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

#pragma mark Getting Items and Index Paths
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)indexPathsOfItem:(id)item;

#pragma mark Getting Section Item
- (id)itemForSection:(NSInteger)section;
- (NSIndexSet *)sectionsForItem:(id)item;

#pragma mark Reload
- (void)reloadWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

#pragma mark Observer
- (void)addObserver:(id<FTDataSourceObserver>)observer;
- (void)removeObserver:(id<FTDataSourceObserver>)observer;

@end
