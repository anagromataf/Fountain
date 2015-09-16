//
//  FTMutableDataSource.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 15.09.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSource.h"

@protocol FTMutableDataSource;

@protocol FTMutableDataSourceObserver <FTDataSourceObserver>
@optional
- (void)dataSource:(id<FTMutableDataSource>)dataSource didChangeFutureItemTypesInSections:(NSIndexSet *)sections;
@end

@protocol FTMutableDataSource <FTDataSource>

#pragma mark Insertion
- (NSUInteger)numberOfFutureItemTypesInSection:(NSUInteger)section;
- (id)futureItemTypeAtIndexPath:(NSIndexPath *)indexPath;
- (void)insertItemWithProperties:(NSDictionary *)properties basedOnType:(id)futureItemType atIndexPath:(NSIndexPath *)indexPath;

#pragma mark Deletion
- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath;

@end
