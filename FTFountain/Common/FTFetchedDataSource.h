//
//  FTFetchedDataSource.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 20.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "FTDataSource.h"

@interface FTFetchedDataSource : NSObject <FTDataSource>

#pragma mark Life-cycle
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                      entity:(NSEntityDescription *)entity
                             sortDescriptors:(NSArray *)sortDescriptors;

#pragma mark Managed Object Context
@property (nonatomic, readonly) NSManagedObjectContext *context;

#pragma mark Request Parameters
@property (nonatomic, readonly) NSEntityDescription *entity;
@property (nonatomic, readonly) NSArray *sortDescriptors;

#pragma mark Fetch Objects
@property (nonatomic, readonly) NSCompoundPredicate *compoundPredicate;
- (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate;

@end
