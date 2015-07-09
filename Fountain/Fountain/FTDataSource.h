//
//  FTDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTDataSource;

@protocol FTDataSourceObserver <NSObject>
@optional

#pragma mark Begin End Updates
- (void)dataSourceWillChange:(id<FTDataSource>)dataSource;
- (void)dataSourceDidChange:(id<FTDataSource>)dataSource;

#pragma mark Reload
- (void)dataSourceWillReload:(id<FTDataSource>)dataSource;
- (void)dataSourceDidReload:(id<FTDataSource>)dataSource;

#pragma mark Manage Sections
- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections;
- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections;
- (void)dataSource:(id<FTDataSource>)dataSource didReloadSections:(NSIndexSet *)sections;
- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection;

#pragma mark Manage Items
- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(id<FTDataSource>)dataSource didReloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

@end

#pragma mark -

@protocol FTDataSource <NSObject>

#pragma mark Getting Item and Section Metrics
- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

#pragma mark Getting Items and Index Paths
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Getting Section Item
- (id)itemForSection:(NSInteger)section;

#pragma mark Reload
- (void)reloadWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

#pragma mark Observer
- (NSArray *)observers;
- (void)addObserver:(id<FTDataSourceObserver>)observer;
- (void)removeObserver:(id<FTDataSourceObserver>)observer;
@end

#pragma mark -

@protocol FTReverseDataSource <FTDataSource>

#pragma mark Getting Item Index Paths
- (NSArray *)indexPathsOfItem:(id)item;

#pragma mark Getting Section Indexes

- (NSIndexSet *)sectionsForItem:(id)item;
@end

#pragma mark -

@protocol FTPagingDataSource <FTDataSource>

@property (nonatomic, readonly) BOOL hasMoreItems;
- (void)loadNextPageCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end

#pragma mark -

@protocol FTMutableDataSource <FTDataSource>

@property (nonatomic, readonly) BOOL hasChanges;
#pragma mark Apply Changes
- (void)applyChangesWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end

#pragma mark -

@protocol FTReorderableDataSource <FTMutableDataSource>

- (BOOL)canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath
                                       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;
- (void)moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end
