//
//  FTFutureItemsDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 30.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSource.h"
#import "FTDataSourceObserver.h"

@protocol FTFutureItemsDataSource <FTDataSource>
#pragma mark Future Items
- (NSUInteger)numberOfFutureItemsInSection:(NSUInteger)section;
- (id)futureItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol FTFutureItemsDataSourceObserver <FTDataSourceObserver>
@optional
- (void)dataSource:(id<FTFutureItemsDataSource>)dataSource didInsertFutureItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(id<FTFutureItemsDataSource>)dataSource didDeleteFutureItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(id<FTFutureItemsDataSource>)dataSource didChangeFutureItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(id<FTFutureItemsDataSource>)dataSource didMoveFutureItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;
@end
