//
//  FTFetchedDataSource.m
//  Fountain
//
//  Created by Tobias Kraentzer on 20.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSourceObserver.h"
#import "FTMutableSet.h"
#import "FTObserverProxy.h"

#import "FTFetchedDataSource.h"

@interface FTFetchedDataSource () {
    NSMutableSet<FTDataSource, FTReverseDataSource> *_fetchedObjects;
    FTObserverProxy *_observers;
    NSPredicate *_filterPredicate;
}

@end

@implementation FTFetchedDataSource

#pragma mark Life-cycle

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                      entity:(NSEntityDescription *)entity
                             sortDescriptors:(NSArray *)sortDescriptors
                                   predicate:(NSPredicate *)predicate
{
    return [self initWithManagedObjectContext:context
                                       entity:entity
                              sortDescriptors:sortDescriptors
                                    predicate:predicate
                            clusterComperator:nil];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                      entity:(NSEntityDescription *)entity
                             sortDescriptors:(NSArray *)sortDescriptors
                                   predicate:(NSPredicate *)predicate
                           clusterComperator:(FTClusterComperator *)clusterComperator
{
    self = [super init];
    if (self) {
        _observers = [[FTObserverProxy alloc] init];
        _observers.object = self;
        _context = context;
        _entity = entity;
        _sortDescriptors = [sortDescriptors copy];
        _predicate = [predicate copy];
        _clusterComperator = clusterComperator;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextObjectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:_context];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Fetch Predicate

- (NSPredicate *)fetchPredicate
{
    NSMutableArray *predicates = [[NSMutableArray alloc] init];

    if (self.predicate) {
        [predicates addObject:self.predicate];
    }

    if (self.filterPredicate) {
        [predicates addObject:self.filterPredicate];
    }

    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

#pragma mark Fetch Objects

- (BOOL)fetchObject:(NSError **)error
{
    return [self fetchObjects:error];
}

- (BOOL)fetchObjects:(NSError **)error
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:_entity.name];
    request.predicate = [self fetchPredicate];

    NSArray *result = [_context executeFetchRequest:request error:error];
    if (result) {

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceWillReset:)]) {
                [observer dataSourceWillReset:self];
            }
        }

        if (_clusterComperator) {
            FTMutableClusterSet *set = [[FTMutableClusterSet alloc] initSortDescriptors:self.sortDescriptors comperator:self.clusterComperator];
            [set addObjectsFromArray:result];
            [set addObserver:_observers];
            _fetchedObjects = set;
        } else {
            FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:self.sortDescriptors];
            [set addObjectsFromArray:result];
            [set addObserver:_observers];
            _fetchedObjects = set;
        }

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceDidReset:)]) {
                [observer dataSourceDidReset:self];
            }
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)fetchObjectsWithCompletion:(void (^)(BOOL success, NSError *error))completion
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:_entity.name];
    request.predicate = [self fetchPredicate];

    NSPersistentStoreAsynchronousFetchResultCompletionBlock resultBlock = ^(NSAsynchronousFetchResult *result) {

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceWillReset:)]) {
                [observer dataSourceWillReset:self];
            }
        }

        if (_clusterComperator) {
            FTMutableClusterSet *set = [[FTMutableClusterSet alloc] initSortDescriptors:self.sortDescriptors comperator:self.clusterComperator];
            [set addObjectsFromArray:result.finalResult];
            [set addObserver:_observers];
            _fetchedObjects = set;
        } else {
            FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:self.sortDescriptors];
            [set addObjectsFromArray:result.finalResult];
            [set addObserver:_observers];
            _fetchedObjects = set;
        }

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceDidReset:)]) {
                [observer dataSourceDidReset:self];
            }
        }

        if (completion) {
            completion(YES, nil);
        }
    };

    NSAsynchronousFetchRequest *asyncRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:request
                                                                                        completionBlock:resultBlock];

    [_context performBlock:^{
        NSError *error = nil;
        NSAsynchronousFetchResult *result = (NSAsynchronousFetchResult *)[_context executeRequest:asyncRequest error:&error];
        if (result == nil) {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark Filter Result

- (BOOL)filterResultWithPredicate:(NSPredicate *)predicate
                            error:(NSError **)error
{
    _filterPredicate = predicate;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:_entity.name];
    request.predicate = [self fetchPredicate];

    NSArray *result = [_context executeFetchRequest:request error:error];
    if (result) {

        if ([_fetchedObjects isKindOfClass:[FTMutableSet class]]) {

            FTMutableSet *fetchedObjects = (FTMutableSet *)_fetchedObjects;
            [fetchedObjects performBatchUpdate:^{
                [fetchedObjects removeAllObjects];
                [fetchedObjects addObjectsFromArray:result];
            }];

        } else if ([_fetchedObjects isKindOfClass:[FTMutableClusterSet class]]) {

            FTMutableClusterSet *fetchedObjects = (FTMutableClusterSet *)_fetchedObjects;
            [fetchedObjects performBatchUpdate:^{
                [fetchedObjects removeAllObjects];
                [fetchedObjects addObjectsFromArray:result];
            }];

        } else {
            NSAssert(NO, @"Internal error backing store must either be of kind 'FTMutableSet' or 'FTMutableClusterSet', but it is of kind '%@'", NSStringFromClass([_fetchedObjects class]));
            return NO;
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)filterResultWithPredicate:(NSPredicate *)predicate
                       completion:(void (^)(BOOL success, NSError *error))completion
{
    _filterPredicate = predicate;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:_entity.name];
    request.predicate = [self fetchPredicate];

    NSPersistentStoreAsynchronousFetchResultCompletionBlock resultBlock = ^(NSAsynchronousFetchResult *result) {

        if ([_fetchedObjects isKindOfClass:[FTMutableSet class]]) {

            FTMutableSet *fetchedObjects = (FTMutableSet *)_fetchedObjects;
            [fetchedObjects performBatchUpdate:^{
                [fetchedObjects removeAllObjects];
                [fetchedObjects addObjectsFromArray:result.finalResult];
            }];

        } else if ([_fetchedObjects isKindOfClass:[FTMutableClusterSet class]]) {

            FTMutableClusterSet *fetchedObjects = (FTMutableClusterSet *)_fetchedObjects;
            [fetchedObjects performBatchUpdate:^{
                [fetchedObjects removeAllObjects];
                [fetchedObjects addObjectsFromArray:result.finalResult];
            }];

        } else {
            NSAssert(NO, @"Internal error backing store must either be of kind 'FTMutableSet' or 'FTMutableClusterSet', but it is of kind '%@'", NSStringFromClass([_fetchedObjects class]));

            if (completion) {
                completion(NO, nil);
            }
        }

        if (completion) {
            completion(YES, nil);
        }
    };

    NSAsynchronousFetchRequest *asyncRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:request
                                                                                        completionBlock:resultBlock];

    [_context performBlock:^{
        NSError *error = nil;
        NSAsynchronousFetchResult *result = (NSAsynchronousFetchResult *)[_context executeRequest:asyncRequest error:&error];
        if (result == nil) {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark Notification Handling

- (void)managedObjectContextObjectsDidChange:(NSNotification *)notification
{
    NSPredicate *entityPredicate = [NSPredicate predicateWithBlock:^BOOL(NSManagedObject *evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject.entity isKindOfEntity:self.entity];
    }];

    // Deleted Object

    NSSet *deletedObjects = [notification.userInfo[NSDeletedObjectsKey] filteredSetUsingPredicate:entityPredicate];

    // Inserted Objects

    NSSet *insertedObjects = [notification.userInfo[NSInsertedObjectsKey] filteredSetUsingPredicate:entityPredicate];
    insertedObjects = [insertedObjects filteredSetUsingPredicate:[self fetchPredicate]];

    // Updates

    NSMutableSet *updatedObjects = [[NSMutableSet alloc] init];

    if (notification.userInfo[NSUpdatedObjectsKey]) {
        [updatedObjects unionSet:[notification.userInfo[NSUpdatedObjectsKey] filteredSetUsingPredicate:entityPredicate]];
    }

    if (notification.userInfo[NSRefreshedObjectsKey]) {
        [updatedObjects unionSet:[notification.userInfo[NSRefreshedObjectsKey] filteredSetUsingPredicate:entityPredicate]];
    }

    NSSet *updatedObjectsToInsert = [updatedObjects filteredSetUsingPredicate:[self fetchPredicate]];

    NSMutableSet *updatedObjectsToRemove = [updatedObjects mutableCopy];
    [updatedObjectsToRemove minusSet:updatedObjectsToInsert];

    // Apply Updates

    if ([deletedObjects count] > 0 ||
        [insertedObjects count] > 0 ||
        [updatedObjectsToRemove count] > 0 ||
        [updatedObjectsToInsert count] > 0) {

        if ([_fetchedObjects isKindOfClass:[FTMutableSet class]]) {
            [(FTMutableSet *)_fetchedObjects performBatchUpdate:^{
                [_fetchedObjects minusSet:deletedObjects];
                [_fetchedObjects unionSet:insertedObjects];
                [_fetchedObjects minusSet:updatedObjectsToRemove];
                [_fetchedObjects unionSet:updatedObjectsToInsert];
            }];
        } else if ([_fetchedObjects isKindOfClass:[FTMutableClusterSet class]]) {
            [(FTMutableClusterSet *)_fetchedObjects performBatchUpdate:^{
                [_fetchedObjects minusSet:deletedObjects];
                [_fetchedObjects unionSet:insertedObjects];
                [_fetchedObjects minusSet:updatedObjectsToRemove];
                [_fetchedObjects unionSet:updatedObjectsToInsert];
            }];
        }
    }
}

#pragma mark FTDataSource

#pragma mark Getting Item and Section Metrics

- (NSUInteger)numberOfSections
{
    return [_fetchedObjects numberOfSections];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    return [_fetchedObjects numberOfItemsInSection:section];
}

#pragma mark Getting Items and Sections

- (id)sectionItemForSection:(NSUInteger)section
{
    return [_fetchedObjects sectionItemForSection:section];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_fetchedObjects.count == 0) {
        return nil;
    }

    return [_fetchedObjects itemAtIndexPath:indexPath];
}

#pragma mark Observer

- (NSArray *)observers
{
    return [_observers observers];
}

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [_observers addObserver:observer];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [_observers removeObserver:observer];
}

#pragma mark FTReverseDataSource

#pragma mark Getting Section Indexes

- (NSIndexSet *)sectionsOfSectionItem:(id)sectionItem
{
    return [_fetchedObjects sectionsOfSectionItem:sectionItem];
}

#pragma mark Getting Item Index Paths

- (NSArray *)indexPathsOfItem:(id)item
{
    return [_fetchedObjects indexPathsOfItem:item];
}

@end
