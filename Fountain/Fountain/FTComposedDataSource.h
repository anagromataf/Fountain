//
//  FTComposedDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"

@interface FTComposedDataSource : NSObject <FTDataSource, FTReverseDataSource>

#pragma mark Life-cycle
- (instancetype)initWithSectionDataSource:(id<FTDataSource>)sectionDataSource;

#pragma mark Section Data Source
@property (nonatomic, readonly) id<FTDataSource> sectionDataSource;

- (id<FTDataSource>)createDataSourceWithSectionItem:(id)sectionItem;
- (id<FTDataSource>)dataSourceForSection:(NSUInteger)section;

@end
