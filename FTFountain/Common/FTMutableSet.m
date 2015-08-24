//
//  FTMutableSet.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 16.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSourceObserver.h"

#import "FTMutableSet.h"

@implementation FTMutableSet {
    NSMutableArray *_backingStore;
    NSHashTable *_observers;
    NSUInteger _batchUpdateCallCount;
    NSArray *_sortDescriptors;

    NSMutableArray *_sections;

    NSMutableSet *_insertedObjects;
    NSMutableSet *_updatedObjects;
    NSMutableSet *_deletedObjects;
}

#pragma mark Life-cycle

- (instancetype)init
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init] sortDescriptors:nil clusterComperator:nil];
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
    return [self initWithBackingStore:backingStore sortDescriptors:nil clusterComperator:nil];
}

- (instancetype)initSortDescriptors:(NSArray *)sortDescriptors
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init]
                      sortDescriptors:sortDescriptors
                    clusterComperator:nil];
}

- (nonnull instancetype)initSortDescriptors:(NSArray *)sortDescriptors clusterComperator:(FTMutableSetClusterComperator)clusterComperator
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init]
                      sortDescriptors:sortDescriptors
                    clusterComperator:clusterComperator];
}

- (nonnull instancetype)initWithBackingStore:(NSMutableArray *)backingStore
                             sortDescriptors:(NSArray *)sortDescriptors
                           clusterComperator:(FTMutableSetClusterComperator)clusterComperator
{
    self = [super init];
    if (self) {
        _backingStore = backingStore;
        _observers = [[NSHashTable alloc] init];
        _batchUpdateCallCount = 0;
        _sortDescriptors = [sortDescriptors count] > 0 ? [sortDescriptors copy] : nil;
        _clusterComperator = clusterComperator;

        [_backingStore sortUsingDescriptors:self.sortDescriptors];

        if (clusterComperator) {
            _sections = [[NSMutableArray alloc] init];
        }
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
    [self performBatchUpdates:^{
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
    [self performBatchUpdates:^{
        [_deletedObjects addObject:object];
        [_insertedObjects removeObject:object];
        [_updatedObjects removeObject:object];
    }];
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[[self class] alloc] initWithBackingStore:[_backingStore mutableCopy] sortDescriptors:[_sortDescriptors copy] clusterComperator:nil];
}

#pragma mark NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithBackingStore:[_backingStore mutableCopy] sortDescriptors:[_sortDescriptors copy] clusterComperator:nil];
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

+ (NSComparator)comperatorUsingSortDescriptors:(NSArray *)sortDescriptors
{
    return ^(id firstObject, id secondObject) {
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            NSComparisonResult result = [sortDescriptor compareObject:firstObject toObject:secondObject];
            switch (result) {
            case NSOrderedAscending:
                return sortDescriptor.ascending ? NSOrderedAscending : NSOrderedDescending;
            case NSOrderedDescending:
                return sortDescriptor.ascending ? NSOrderedDescending : NSOrderedAscending;
            default:
                break;
            }
        }
        return NSOrderedSame;
    };
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

#pragma mark Clustering

+ (NSArray *)clustersWithObjects:(NSSet *)objects
            usingSortDescriptors:(NSArray *)sortDescriptors
               clusterComperator:(FTMutableSetClusterComperator)clusterComperator
{
    NSMutableArray *clusters = [[NSMutableArray alloc] init];

    NSArray *sortedObjects = [objects sortedArrayUsingDescriptors:sortDescriptors];

    for (id object in sortedObjects) {
        id previousObject = [[clusters lastObject] lastObject];
        if (previousObject && clusterComperator(previousObject, object)) {
            [[clusters lastObject] addObject:object];
        } else {
            [clusters addObject:[NSMutableArray arrayWithObject:object]];
        }
    }

    return clusters;
}

#pragma mark Batch Updates

- (void)performBatchUpdates:(void (^)(void))updates
{
    if (updates) {
        if (_batchUpdateCallCount == 0) {

            if (_clusterComperator) {
                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSourceWillReset:)]) {
                        [observer dataSourceWillReset:self];
                    }
                }
            } else {
                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
                        [observer dataSourceWillChange:self];
                    }
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

            if (_clusterComperator) {

                [self ft_applyDeletion_Clusters];
                [self ft_applyInsertion_Clusters];

                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSourceDidReset:)]) {
                        [observer dataSourceDidReset:self];
                    }
                }

            } else {

                [self ft_applyDeletion];
                [self ft_applyInsertion];

                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
                        [observer dataSourceDidChange:self];
                    }
                }
            }

            _insertedObjects = nil;
            _updatedObjects = nil;
            _deletedObjects = nil;
        }
    }
}

#pragma mark Apply Changes

- (void)ft_applyDeletion_Clusters
{
    if ([_deletedObjects count] > 0) {

        NSComparator comperator = [[self class] comperatorUsingSortDescriptors:self.sortDescriptors];
        NSArray *deletedObjects = [_deletedObjects sortedArrayUsingDescriptors:self.sortDescriptors];

        NSUInteger offset = 0;

        for (id object in deletedObjects) {

            NSUInteger index = [_backingStore indexOfObject:object
                                              inSortedRange:NSMakeRange(offset, [_backingStore count] - offset)
                                                    options:NSBinarySearchingInsertionIndex
                                            usingComparator:comperator];

            [_backingStore insertObject:object atIndex:index];

            NSUInteger sectionIndex = [_sections indexOfObject:object
                                                 inSortedRange:NSMakeRange(0, [_sections count])
                                                       options:NSBinarySearchingFirstEqual
                                               usingComparator:^NSComparisonResult(NSMutableArray *section, id object) {

                                                   NSUInteger itemIndex = [section indexOfObject:object
                                                                                   inSortedRange:NSMakeRange(0, [section count])
                                                                                         options:NSBinarySearchingInsertionIndex
                                                                                 usingComparator:comperator];

                                                   if (itemIndex == 0) {
                                                       if (_clusterComperator(object, [section firstObject])) {
                                                           return NSOrderedSame;
                                                       } else {
                                                           return NSOrderedDescending;
                                                       }
                                                   } else if (itemIndex == [section count]) {
                                                       if (_clusterComperator([section lastObject], object)) {
                                                           return NSOrderedSame;
                                                       } else {
                                                           return NSOrderedAscending;
                                                       }
                                                   } else {
                                                       return NSOrderedSame;
                                                   }
                                               }];

            if (sectionIndex != NSNotFound) {
                NSMutableArray *section = [_sections objectAtIndex:sectionIndex];

                NSUInteger itemIndex = [section indexOfObject:object
                                                inSortedRange:NSMakeRange(0, [section count])
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:comperator];

                if (itemIndex != NSNotFound) {

                    if ([section count] == 1) {
                        [_sections removeObject:section];
                    } else {
                        [section removeObject:object];

                        if (itemIndex < [section count] && itemIndex > 0) {
                            id previousObject = [section objectAtIndex:itemIndex - 1];
                            id nextObject = [section objectAtIndex:itemIndex];

                            if (!_clusterComperator(previousObject, nextObject)) {

                                // Section needs to be split into two sections

                                NSMutableArray *newSection = [[section subarrayWithRange:NSMakeRange(itemIndex, [section count] - itemIndex)] mutableCopy];
                                [section removeObjectsInRange:NSMakeRange(itemIndex, [section count] - itemIndex)];
                                [_sections insertObject:newSection atIndex:sectionIndex + 1];
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)ft_applyDeletion
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

            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                    [observer dataSource:self didDeleteItemsAtIndexPaths:indexPathsOfDeletedItems];
                }
            }
        }

        [_backingStore removeObjectsAtIndexes:indexes];
        [_deletedObjects removeAllObjects];
    }
}

- (void)ft_applyInsertion_Clusters
{
    if ([_insertedObjects count] > 0) {

        NSComparator comperator = [[self class] comperatorUsingSortDescriptors:self.sortDescriptors];
        NSArray *insertedObjects = [_insertedObjects sortedArrayUsingDescriptors:self.sortDescriptors];

        NSUInteger offset = 0;

        for (id object in insertedObjects) {

            NSUInteger index = [_backingStore indexOfObject:object
                                              inSortedRange:NSMakeRange(offset, [_backingStore count] - offset)
                                                    options:NSBinarySearchingInsertionIndex
                                            usingComparator:comperator];

            [_backingStore insertObject:object atIndex:index];

            NSUInteger sectionIndex = [_sections indexOfObject:object
                                                 inSortedRange:NSMakeRange(0, [_sections count])
                                                       options:NSBinarySearchingFirstEqual
                                               usingComparator:^NSComparisonResult(NSMutableArray *section, id object) {

                                                   NSUInteger itemIndex = [section indexOfObject:object
                                                                                   inSortedRange:NSMakeRange(0, [section count])
                                                                                         options:NSBinarySearchingInsertionIndex
                                                                                 usingComparator:comperator];

                                                   if (itemIndex == 0) {
                                                       if (_clusterComperator(object, [section firstObject])) {
                                                           return NSOrderedSame;
                                                       } else {
                                                           return NSOrderedDescending;
                                                       }
                                                   } else if (itemIndex == [section count]) {
                                                       if (_clusterComperator([section lastObject], object)) {
                                                           return NSOrderedSame;
                                                       } else {
                                                           return NSOrderedAscending;
                                                       }
                                                   } else {
                                                       return NSOrderedSame;
                                                   }
                                               }];

            if (sectionIndex == NSNotFound) {

                // Create new section

                NSMutableArray *newSection = [[NSMutableArray alloc] init];
                [newSection addObject:object];

                sectionIndex = [_sections indexOfObject:newSection
                                          inSortedRange:NSMakeRange(0, [_sections count])
                                                options:NSBinarySearchingInsertionIndex
                                        usingComparator:^NSComparisonResult(NSArray *section1, NSArray *section2) {
                                            return comperator([section1 firstObject], [section2 firstObject]);
                                        }];

                [_sections insertObject:newSection atIndex:sectionIndex];

            } else {

                // Use exsiting section

                NSMutableArray *section = [_sections objectAtIndex:sectionIndex];

                NSUInteger itemIndex = [section indexOfObject:object
                                                inSortedRange:NSMakeRange(0, [section count])
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:comperator];

                [section insertObject:object atIndex:itemIndex];

                if (itemIndex == [section count] - 1 && sectionIndex < [_sections count] - 1) {

                    NSMutableArray *nextSection = [_sections objectAtIndex:sectionIndex + 1];

                    if (_clusterComperator([section lastObject], [nextSection firstObject])) {

                        // Merge with next cluster

                        [section addObjectsFromArray:nextSection];
                        [_sections removeObject:nextSection];
                    }
                }
            }
        }

        [_insertedObjects removeAllObjects];
    }
}

- (void)ft_applyInsertion
{
    if ([_insertedObjects count] > 0) {

        NSComparator comperator = [[self class] comperatorUsingSortDescriptors:self.sortDescriptors];
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
        }

        if ([indexPathsOfInsertedItems count] > 0) {
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                    [observer dataSource:self didInsertItemsAtIndexPaths:indexPathsOfInsertedItems];
                }
            }
        }

        [_insertedObjects removeAllObjects];
    }
}

#pragma mark FTDataSource

#pragma mark Getting Item and Section Metrics

- (NSUInteger)numberOfSections
{
    return _sections != nil ? [_sections count] : 1;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    if ((_sections == nil && _sections != 0) || (_sections != nil && [_sections count] <= section)) {
        [NSException raise:NSRangeException format:@"*** %s: section index %ld beyond bounds [0 .. 1].", __PRETTY_FUNCTION__, (long)section];
    }

    if (_sections) {
        return [[_sections objectAtIndex:section] count];
    } else {
        return [_backingStore count];
    }
}

#pragma mark Getting Items and Sections

- (id)sectionItemForSection:(NSUInteger)section
{
    if ((_sections == nil && _sections != 0) || (_sections != nil && [_sections count] <= section)) {
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

    if ((_sections == nil && _sections != 0) || (_sections != nil && [_sections count] <= section)) {
        [NSException raise:NSRangeException format:@"*** %s: section index %ld beyond bounds [0 .. 1].", __PRETTY_FUNCTION__, (long)section];
    }

    if (_sections) {
        return [[_sections objectAtIndex:section] objectAtIndex:item];
    } else {
        return [_backingStore objectAtIndex:item];
    }
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
