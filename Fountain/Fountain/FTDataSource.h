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

@protocol FTPagingDataSource <FTDataSource>

@property (nonatomic, readonly) BOOL hasMoreItems;
- (void)loadNextPageCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

@end
