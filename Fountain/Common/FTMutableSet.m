//
//  FTMutableSet.m
//  Fountain
//
//  Created by Tobias Kraentzer on 16.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSourceObserver.h"
#import "NSArray+Fountain.h"
#import "NSSortDescriptor+Fountain.h"

#import "FTMutableSet.h"

@implementation FTMutableSet {

    NSHashTable *_observers;
    NSUInteger _batchUpdateCallCount;

    NSMutableArray *_backingStore;
    NSArray *_sortDescriptors;

    NSMutableSet *_insertedObjects;
    NSMutableSet *_updatedObjects;
    NSMutableSet *_deletedObjects;

    BOOL _includeEmptySections;
}

#pragma mark Life-cycle

- (instancetype)init
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init] sortDescriptors:nil includeEmptySections:YES];
}

- (instancetype)initWithObjects:(const id __unsafe_unretained *)objects count:(NSUInteger)cnt
{
    NSMutableArray *backingStore = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < cnt; i++) {
        id obj = objects[i];
        if (![backingStore containsObject:obj]) {
            [backingStore addObject:obj];
        }
    }
    return [self initWithBackingStore:backingStore sortDescriptors:nil includeEmptySections:YES];
}

- (instancetype)initSortDescriptors:(NSArray *)sortDescriptors
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init]
                      sortDescriptors:sortDescriptors
                 includeEmptySections:YES];
}

- (instancetype)initWithSortDescriptors:(NSArray *)sortDescriptors
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init]
                      sortDescriptors:sortDescriptors
                 includeEmptySections:YES];
}

- (instancetype)initWithSortDescriptors:(NSArray *)sortDescriptors includeEmptySections:(BOOL)includeEmptySections
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init]
                      sortDescriptors:sortDescriptors
                 includeEmptySections:includeEmptySections];
}

- (nonnull instancetype)initWithBackingStore:(NSMutableArray *)backingStore
                             sortDescriptors:(NSArray *)sortDescriptors
                        includeEmptySections:(BOOL)includeEmptySections
{
    self = [super init];
    if (self) {
        _backingStore = backingStore;
        _observers = [[NSHashTable alloc] init];
        _batchUpdateCallCount = 0;
        _sortDescriptors = [sortDescriptors count] > 0 ? [sortDescriptors copy] : nil;
        _includeEmptySections = includeEmptySections;

        [_backingStore sortUsingDescriptors:self.sortDescriptors];
    }
    return self;
}

#pragma mark NSSet

- (NSUInteger)count
{
    return [_backingStore count];
}

- (id)member:(id)object
{
    NSUInteger index = [_backingStore indexOfObject:object];
    return index != NSNotFound ? [_backingStore objectAtIndex:index] : nil;
}

- (NSEnumerator *)objectEnumerator
{
    return [_backingStore objectEnumerator];
}

#pragma mark NSMutableSet

- (void)addObject:(nonnull id)anObject
{
    [self performBatchUpdate:^{
        if ([_backingStore containsObject:anObject]) {
            [_updatedObjects addObject:anObject];
        } else {
            [_insertedObjects addObject:anObject];
        }
        [_deletedObjects removeObject:anObject];
    }];
}

- (void)removeObject:(id)object
{
    [self performBatchUpdate:^{
        [_deletedObjects addObject:object];
        [_insertedObjects removeObject:object];
        [_updatedObjects removeObject:object];
    }];
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[[self class] alloc] initWithBackingStore:[_backingStore mutableCopy] sortDescriptors:[_sortDescriptors copy] includeEmptySections:_includeEmptySections];
}

#pragma mark NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithBackingStore:[_backingStore mutableCopy] sortDescriptors:[_sortDescriptors copy] includeEmptySections:_includeEmptySections];
}

#pragma mark NSCoding

- (Class)classForCoder
{
    return [FTMutableSet class];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_backingStore forKey:@"_backingStore"];
    [aCoder encodeObject:_sortDescriptors forKey:@"_sortDescriptors"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _backingStore = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"_backingStore"];
        _sortDescriptors = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"_sortDescriptors"];
        _observers = [[NSHashTable alloc] init];
        _batchUpdateCallCount = 0;
    }
    return self;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark Sort Descriptors

- (NSArray *)sortDescriptors
{
    if (_sortDescriptors) {
        return _sortDescriptors;
    } else {
        return @[ [[self class] defaultSortDescriptor] ];
    }
}

+ (NSSortDescriptor *)defaultSortDescriptor
{
    return [NSSortDescriptor sortDescriptorWithKey:@"self"
                                         ascending:YES
                                        comparator:^NSComparisonResult(id obj1, id obj2) {
                                            if (obj1 < obj2) {
                                                return NSOrderedAscending;
                                            } else if (obj1 > obj2) {
                                                return NSOrderedDescending;
                                            } else {
                                                return NSOrderedSame;
                                            }
                                        }];
}

#pragma mark Include Empty Sections

- (BOOL)includeEmptySections
{
    return _includeEmptySections;
}

#pragma mark Batch Updates

- (void)performBatchUpdate:(void (^)(void))updates
{
    if (updates) {
        if (_batchUpdateCallCount == 0) {

            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
                    [observer dataSourceWillChange:self];
                }
            }

            _insertedObjects = [[NSMutableSet alloc] init];
            _updatedObjects = [[NSMutableSet alloc] init];
            _deletedObjects = [[NSMutableSet alloc] init];
        }

        _batchUpdateCallCount++;

        updates();

        _batchUpdateCallCount--;

        if (_batchUpdateCallCount == 0) {

            BOOL insertSection = NO;
            BOOL removeSection = NO;

            BOOL callObserver = YES;
            if (_includeEmptySections == NO) {
                if ([_backingStore count] == 0) {
                    callObserver = NO;
                    if ([_insertedObjects count] > 0) {
                        insertSection = YES;
                    }
                } else {
                    NSSet *exsitingObjects = [NSSet setWithArray:_backingStore];
                    if ([exsitingObjects isEqual:_deletedObjects]) {
                        callObserver = NO;
                        removeSection = YES;
                    }
                }
            }

            [self ft_applyUpdateAndCallObserver:callObserver];
            [self ft_applyDeletionAndCallObserver:callObserver];
            [self ft_applyInsertionAndCallObserver:callObserver];

            for (id<FTDataSourceObserver> observer in self.observers) {

                if (insertSection) {
                    if ([observer respondsToSelector:@selector(dataSource:didInsertSections:)]) {
                        [observer dataSource:self didInsertSections:[NSIndexSet indexSetWithIndex:0]];
                    }
                }

                if (removeSection) {
                    if ([observer respondsToSelector:@selector(dataSource:didDeleteSections:)]) {
                        [observer dataSource:self didDeleteSections:[NSIndexSet indexSetWithIndex:0]];
                    }
                }

                if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
                    [observer dataSourceDidChange:self];
                }
            }

            _insertedObjects = nil;
            _updatedObjects = nil;
            _deletedObjects = nil;
        }
    }
}

#pragma mark Apply Changes

- (void)ft_applyDeletionAndCallObserver:(BOOL)callObserver
{
    if ([_deletedObjects count] > 0) {

        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];

        for (id obj in _deletedObjects) {
            NSUInteger index = [_backingStore indexOfObject:obj];
            if (index != NSNotFound) {
                [indexes addIndex:index];
            }
        }

        if ([indexes count] > 0) {

            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];

            NSMutableArray *indexPathsOfDeletedItems = [[NSMutableArray alloc] init];
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [indexPathsOfDeletedItems addObject:[sectionIndexPath indexPathByAddingIndex:idx]];
            }];

            if (callObserver == YES) {
                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                        [observer dataSource:self didDeleteItemsAtIndexPaths:indexPathsOfDeletedItems];
                    }
                }
            }
        }

        [_backingStore removeObjectsAtIndexes:indexes];
        [_deletedObjects removeAllObjects];
    }
}

- (void)ft_applyInsertionAndCallObserver:(BOOL)callObserver
{
    if ([_insertedObjects count] > 0) {

        NSComparator comperator = [NSSortDescriptor ft_comperatorUsingSortDescriptors:self.sortDescriptors];
        NSArray *insertedObjects = [_insertedObjects sortedArrayUsingDescriptors:self.sortDescriptors];

        NSMutableArray *indexPathsOfInsertedItems = [[NSMutableArray alloc] init];

        NSUInteger offset = 0;

        for (id object in insertedObjects) {

            NSUInteger index = [_backingStore indexOfObject:object
                                              inSortedRange:NSMakeRange(offset, [_backingStore count] - offset)
                                                    options:NSBinarySearchingInsertionIndex
                                            usingComparator:comperator];

            [_backingStore insertObject:object atIndex:index];

            NSUInteger indexes[] = {0, index};
            [indexPathsOfInsertedItems addObject:[NSIndexPath indexPathWithIndexes:indexes length:2]];

            offset = index + 1;
        }

        if (callObserver == YES && [indexPathsOfInsertedItems count] > 0) {
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                    [observer dataSource:self didInsertItemsAtIndexPaths:indexPathsOfInsertedItems];
                }
            }
        }

        [_insertedObjects removeAllObjects];
    }
}

- (void)ft_applyUpdateAndCallObserver:(BOOL)callObserver
{
    if ([_updatedObjects count] > 0) {

        NSComparator comperator = [NSSortDescriptor ft_comperatorUsingSortDescriptors:self.sortDescriptors];
        NSArray *updatedObjects = [NSArray ft_arrayBySortingObjects:_updatedObjects
                                               usingSortDescriptors:self.sortDescriptors
                                orderAmbiguousObjectsByOrderInArray:_backingStore];

        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        NSMapTable *indexesByObjects = [NSMapTable strongToStrongObjectsMapTable];

        for (id object in updatedObjects) {
            NSUInteger index = [_backingStore indexOfObject:object];
            [indexes addIndex:index];

            // Replace the object in the set with the updated object. The object might
            // be a different object, because the update is based on equality and not
            // on identity.
            [_backingStore replaceObjectAtIndex:index withObject:object];

            [indexesByObjects setObject:@(index) forKey:object];
        }

        [_backingStore sortUsingComparator:comperator];

        if (callObserver) {
            NSIndexPath *sectionIndex = [NSIndexPath indexPathWithIndex:0];

            for (id object in updatedObjects) {
                NSUInteger index = [[indexesByObjects objectForKey:object] unsignedIntegerValue];
                NSUInteger newIndex = [_backingStore indexOfObject:object];

                if (index == newIndex) {

                    NSIndexPath *indexPath = [sectionIndex indexPathByAddingIndex:index];

                    for (id<FTDataSourceObserver> observer in self.observers) {
                        if ([observer respondsToSelector:@selector(dataSource:didChangeItemsAtIndexPaths:)]) {
                            [observer dataSource:self didChangeItemsAtIndexPaths:@[ indexPath ]];
                        }
                    }

                } else {

                    for (id<FTDataSourceObserver> observer in self.observers) {
                        if ([observer respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)]) {

                            [observer dataSource:self
                                didMoveItemAtIndexPath:[sectionIndex indexPathByAddingIndex:index]
                                           toIndexPath:[sectionIndex indexPathByAddingIndex:newIndex]];
                        }
                    }
                }
            }
        }
    }
}

#pragma mark FTDataSource

#pragma mark Getting Item and Section Metrics

- (NSUInteger)numberOfSections
{
    if (_includeEmptySections) {
        return 1;
    } else {
        return [_backingStore count] > 0 ? 1 : 0;
    }
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    if (section != 0) {
        [NSException raise:NSRangeException format:@"*** %s: section index %ld beyond bounds [0 .. 1].", __PRETTY_FUNCTION__, (long)section];
    }

    return [_backingStore count];
}

#pragma mark Getting Items and Sections

- (id)sectionItemForSection:(NSUInteger)section
{
    if (section != 0) {
        [NSException raise:NSRangeException format:@"*** %s: section index %ld beyond bounds [0 .. 1].", __PRETTY_FUNCTION__, (long)section];
    }

    return nil;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath length] != 2) {
        [NSException raise:NSInvalidArgumentException format:@"*** %s: length of index path must be 2, got an index path with length %lu.", __PRETTY_FUNCTION__, (unsigned long)[indexPath length]];
    }

    NSUInteger section = [indexPath indexAtPosition:0];
    NSUInteger item = [indexPath indexAtPosition:1];

    if (section != 0) {
        [NSException raise:NSRangeException format:@"*** %s: section index %ld beyond bounds [0 .. 1].", __PRETTY_FUNCTION__, (long)section];
    }

    return [_backingStore objectAtIndex:item];
}

#pragma mark Observer

- (NSArray *)observers
{
    return [_observers allObjects];
}

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [_observers addObject:observer];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [_observers removeObject:observer];
}

#pragma mark FTReverseDataSource

- (NSIndexSet *)sectionsOfSectionItem:(id)sectionItem
{
    return [NSIndexSet indexSet];
}

- (NSArray *)indexPathsOfItem:(id)item
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];

    NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];

    [_backingStore enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqual:item]) {
            [indexPaths addObject:[sectionIndexPath indexPathByAddingIndex:idx]];
        }
    }];

    return [indexPaths copy];
}

@end
