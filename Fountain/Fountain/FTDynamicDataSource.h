//
//  FTDynamicDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 12.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"

@interface FTDynamicDataSource : NSObject <FTDataSource, FTReverseDataSource>

#pragma mark Life-cycle
- (instancetype)initWithComerator:(NSComparator)comperator;

#pragma mark Relaod
- (void)reloadWithItems:(NSArray *)sectionItems
      completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

#pragma mark Updating
- (void)updateWithDeletedItems:(NSArray *)deleted insertedItems:(NSArray *)inserted updatedItems:(NSArray *)updated;
- (void)deleteItems:(NSArray *)sectionItems;
- (void)insertItems:(NSArray *)sectionItems;
- (void)updateItems:(NSArray *)sectionItems;

@end
