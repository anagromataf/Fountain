//
//  FTMutableClusterSet.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 26.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

typedef BOOL (^FTMutableClusterSetComperator)(id obj1, id obj2);

@interface FTMutableClusterSet : NSMutableSet <FTDataSource>

#pragma mark Life-cycle
- (instancetype)initSortDescriptors:(NSArray *)sortDescriptors comperator:(FTMutableClusterSetComperator)comperator;

#pragma mark Sort Descriptors & Clustering
@property (nonatomic, readonly) NSArray *sortDescriptors;
@property (nonatomic, readonly) FTMutableClusterSetComperator comperator;

#pragma mark Batch Updates

/** Combines multiple insert, delete, and replace operations to one change.
 
 You can use this method in cases where you want to make multiple changes to the set and want to treat them as a single change. Use the blocked passed in the updates parameter to specify all of the operations you want to perform. The observer methods <code>dataSourceWillChange:</code> and <code>dataSourceDidChange:</code> are only called once for all operations performed in the batch update.
 
 @note This method may safely be called reentrantly.
 
 @param updates The block that performs the relevant insert, delete, and replace operations.
 */
- (void)performBatchUpdates:(void (^)(void))updates;

@end
