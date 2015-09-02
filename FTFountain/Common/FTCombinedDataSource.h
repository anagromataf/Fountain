//
//  FTCombinedDataSource.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 01.09.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

@interface FTCombinedDataSource : NSObject <FTDataSource, FTReverseDataSource>

#pragma mark Life-cycle
- (instancetype)initWithDataSources:(NSArray *)dataSources;

#pragma mark Data Sources
@property (nonatomic, readonly) NSArray *dataSources;

- (NSUInteger)convertSection:(NSUInteger)section toDataSource:(id<FTDataSource>)dataSource;
- (NSUInteger)convertSection:(NSUInteger)section fromDataSource:(id<FTDataSource>)dataSource;
- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath toDataSource:(id<FTDataSource>)dataSource;
- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath fromDataSource:(id<FTDataSource>)dataSource;

@end
