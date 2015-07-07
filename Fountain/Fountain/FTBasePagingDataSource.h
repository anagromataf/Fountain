
//
//  FTPagingDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 29.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"

@protocol FTPagingDataSourceOperation <NSObject>
- (void)cancel;
@end

@interface FTBasePagingDataSource : NSObject <FTPagingDataSource>

@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nonatomic, readonly) NSUInteger totalNumberOfItems;
@property (nonatomic, copy, readonly) NSArray *allItems;

@property (nonatomic, assign) NSUInteger pageSize;

- (void)resetCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

- (id<FTPagingDataSourceOperation>)fetchItemsWithOffset:(NSUInteger)offset
                                                  limit:(NSUInteger)limit
                                             completion:(void (^)(NSArray *items, NSUInteger offset, NSUInteger limit, NSUInteger total, NSError *error))completion;

@end
