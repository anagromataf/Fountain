//
//  FTMutableSet.h
//  Fountain
//
//  Created by Tobias Kraentzer on 16.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

/*! <code>FTMutableSet</code> is a subclass of <code>NSMutableSet</code> that conforms
    to the <code>FTDataSource</code> and the <code>FTReverseDataSource</code> protocols.
 
    If <code>FTMutableSet</code> is initialized with sort descriptors, the items are
    provided to you via the data source protocol in that sort order.
 
    If sort descriptors are not defined during initialization, a default sort descriptor
    is used, that sorts the items in an undefined but consistent manner.
 */
@interface FTMutableSet : NSMutableSet <FTDataSource, FTReverseDataSource>

#pragma mark Life-cycle
- (instancetype)initSortDescriptors:(NSArray *)sortDescriptors DEPRECATED_ATTRIBUTE;
- (instancetype)initWithSortDescriptors:(NSArray *)sortDescriptors;
- (instancetype)initWithSortDescriptors:(NSArray *)sortDescriptors includeEmptySections:(BOOL)includeEmptySections;

#pragma mark Sort Descriptors
@property (nonatomic, readonly) NSArray *sortDescriptors;

#pragma mark Include Empty Sections
@property (nonatomic, readonly) BOOL includeEmptySections;

#pragma mark Batch Updates

/** Combines multiple insert, delete, and replace operations to one change.
 
 You can use this method in cases where you want to make multiple changes to the set and want to treat them as a single change. Use the blocked passed in the updates parameter to specify all of the operations you want to perform. The observer methods <code>dataSourceWillChange:</code> and <code>dataSourceDidChange:</code> are only called once for all operations performed in the batch update.
 
 @note This method may safely be called reentrantly.
 
 @param updates The block that performs the relevant insert, delete, and replace operations.
 */
- (void)performBatchUpdate:(void (^)(void))updates;

@end
