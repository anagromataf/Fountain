//
//  FTMutableClusterSet.h
//  Fountain
//
//  Created by Tobias Kraentzer on 26.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

@interface FTClusterComperator : NSObject <NSSecureCoding>

/*! Return YES if if object1 and object2 belong to the same cluster.
 */
- (BOOL)compareObject:(id)object1 toObject:(id)object2;
@end

/*! <code>FTMutableClusterSet</code> is a subclass of <code>NSMutableSet</code> that conforms
    to the <code>FTDataSource</code> and the <code>FTReverseDataSource</code> protocols.
 
    <code>FTMutableClusterSet</code> can be initalized with sort descriptors and a cluster
    comperator. In this case, the items in the set are grouped acording to the cluster comperator.
    Those clusters are represented by section via the data source protocol.
 
    @warning This class is experimental.
 */
@interface FTMutableClusterSet : NSMutableSet <FTDataSource, FTReverseDataSource>

#pragma mark Life-cycle
- (instancetype)initSortDescriptors:(NSArray *)sortDescriptors comperator:(FTClusterComperator *)comperator;

#pragma mark Sort Descriptors & Clustering
@property (nonatomic, readonly) NSArray *sortDescriptors;
@property (nonatomic, readonly) FTClusterComperator *comperator;

#pragma mark Batch Updates

/** Combines multiple insert, delete, and replace operations to one change.
 
 You can use this method in cases where you want to make multiple changes to the set and want to treat them as a single change. Use the blocked passed in the updates parameter to specify all of the operations you want to perform. The observer methods <code>dataSourceWillChange:</code> and <code>dataSourceDidChange:</code> are only called once for all operations performed in the batch update.
 
 @note This method may safely be called reentrantly.
 
 @param updates The block that performs the relevant insert, delete, and replace operations.
 */
- (void)performBatchUpdate:(void (^)(void))updates;

@end
