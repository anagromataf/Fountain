//
//  FTSectionDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"

typedef id<NSCopying>(^FTSectionDataSourceSectionIdentifier)(id);

@interface FTSectionDataSource : NSObject <FTDataSource>

#pragma mark Life-cycle
- (instancetype)initWithSectionDataSource:(id<FTDataSource>)sectionDataSource;

#pragma mark Section Data Source
@property (nonatomic, readonly) id<FTDataSource> sectionDataSource;

@end
