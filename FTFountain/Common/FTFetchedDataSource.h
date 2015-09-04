//
//  FTFetchedDataSource.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 20.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "FTMutableClusterSet.h"

#import "FTDataSource.h"

@interface FTFetchedDataSource : NSObject <FTDataSource, FTReverseDataSource>

#pragma mark Life-cycle
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                      entity:(NSEntityDescription *)entity
                             sortDescriptors:(NSArray *)sortDescriptors
                                   predicate:(NSPredicate *)predicate;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                      entity:(NSEntityDescription *)entity
                             sortDescriptors:(NSArray *)sortDescriptors
                                   predicate:(NSPredicate *)predicate
                           clusterComperator:(FTClusterComperator *)clusterComperator;

#pragma mark Managed Object Context
@property (nonatomic, readonly) NSManagedObjectContext *context;

#pragma mark Request Parameters
@property (nonatomic, readonly) NSEntityDescription *entity;
@property (nonatomic, readonly) NSArray *sortDescriptors;
@property (nonatomic, readonly) NSPredicate *predicate;
@property (nonatomic, readonly) FTClusterComperator *clusterComperator;

#pragma mark Fetch Objects
- (BOOL)fetchObject:(NSError **)error;
- (void)fetchObjectsWithCompletion:(void (^)(BOOL success, NSError *error))completion;

@end
