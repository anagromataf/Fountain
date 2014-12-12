//
//  FTFlatDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 12.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"

typedef id<NSCopying>(^FTFlatDataSourceItemIdentifier)(id);

@interface FTFlatDataSource : NSObject <FTDataSource>

#pragma mark Life-cycle
- (instancetype)initWithComerator:(NSComparator)comperator
                        identifier:(FTFlatDataSourceItemIdentifier)identifier;

#pragma mark Relaod
- (void)reloadWithItems:(NSArray *)sectionItems
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

#pragma mark Updating
- (void)updateWithDeletedItems:(NSArray *)deleted insertedItems:(NSArray *)inserted updatedItems:(NSArray *)updated;
- (void)deleteItems:(NSArray *)sectionItems;
- (void)insertItems:(NSArray *)sectionItems;
- (void)updateItems:(NSArray *)sectionItems;

@end
