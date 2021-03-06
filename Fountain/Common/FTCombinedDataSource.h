//
//  FTCombinedDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 01.09.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTMovableItemsDataSource.h"
#import "FTMutableDataSource.h"
#import "FTReverseDataSource.h"

/*! <code>FTCombinedDataSource</code> is a data source, that combines the data sources
    it is initialized with to one data source.
 
    The resulting data sour e is a concatenation of the sections of the given data sources.
 */
@interface FTCombinedDataSource : NSObject <FTDataSource, FTReverseDataSource, FTMutableDataSource, FTMovableItemsDataSource>

#pragma mark Life-cycle
- (instancetype)initWithDataSources:(NSArray *)dataSources;

#pragma mark Data Sources
@property (nonatomic, readonly) NSArray *dataSources;
- (id<FTDataSource>)dataSourceOfIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)convertSection:(NSUInteger)section toDataSource:(id<FTDataSource>)dataSource;
- (NSUInteger)convertSection:(NSUInteger)section fromDataSource:(id<FTDataSource>)dataSource;
- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath toDataSource:(id<FTDataSource>)dataSource;
- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath fromDataSource:(id<FTDataSource>)dataSource;

@end
