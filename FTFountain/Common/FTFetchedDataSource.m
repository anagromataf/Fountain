//
//  FTFetchedDataSource.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 20.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTMutableSet.h"

#import "FTFetchedDataSource.h"

@interface FTFetchedDataSource () {
    FTMutableSet *_fetchedObjects;

    NSMutableArray *_predicates;
}

@end

@implementation FTFetchedDataSource

#pragma mark Life-cycle

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                      entity:(NSEntityDescription *)entity
                             sortDescriptors:(NSArray *)sortDescriptors
                                   predicate:(NSPredicate *)predicate
{
    self = [super init];
    if (self) {
        _context = context;
        _entity = entity;
        _sortDescriptors = [sortDescriptors copy];
        _predicates = [[NSMutableArray alloc] init];

        _fetchedObjects = [[FTMutableSet alloc] initSortDescriptors:_sortDescriptors];
    }
    return self;
}

#pragma mark Fetch Objects

- (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:_entity.name];
    request.sortDescriptors = _sortDescriptors;
    request.predicate = predicate;

    NSPersistentStoreAsynchronousFetchResultCompletionBlock resultBlock = ^(NSAsynchronousFetchResult *result) {
        if (result.finalResult) {
            [_fetchedObjects addObjectsFromArray:result.finalResult];
        }
    };

    NSAsynchronousFetchRequest *asyncRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:request
                                                                                        completionBlock:resultBlock];

    [_context performBlock:^{
        NSError *error = nil;
        NSAsynchronousFetchResult *result = (NSAsynchronousFetchResult *)[_context executeRequest:asyncRequest error:&error];
        if (result == nil) {
            NSLog(@"Failed to execute fetch: %@", [error localizedDescription]);
        }
    }];

    [_predicates addObject:predicate];
    _compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:_predicates];
}

@end
