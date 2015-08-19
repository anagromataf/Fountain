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

    NSMutableArray *_sections;
    NSMapTable *_sectionsByItems;
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
        _sortDescriptors = sortDescriptors ? [sortDescriptors copy] : @[];
        _clusterComperator = clusterComperator;

        if ([_sortDescriptors count] > 0) {
            [_backingStore sortUsingDescriptors:_sortDescriptors];

            if (clusterComperator) {
                _sections = [[NSMutableArray alloc] init];
                _sectionsByItems = [NSMapTable weakToWeakObjectsMapTable];
            }
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
    if (![_backingStore containsObject:anObject]) {
        [self performBatchUpdates:^{

            NSIndexPath *indexPath = nil;

            if ([self.sortDescriptors count] > 0) {

                NSComparator comperator = [[self class] comperatorUsingSortDescriptors:self.sortDescriptors];

                NSUInteger index = [_backingStore indexOfObject:anObject
                                                  inSortedRange:NSMakeRange(0, [_backingStore count])
                                                        options:NSBinarySearchingInsertionIndex
                                                usingComparator:comperator];
                [_backingStore insertObject:anObject atIndex:index];

                if (_clusterComperator) {

                    BOOL combineWithPreviousSection = NO;
                    BOOL combineWithNextSection = NO;

                    id previousItem = nil;
                    id nextItem = nil;

                    NSMutableArray *previousSection = nil;
                    NSMutableArray *nextSection = nil;

                    NSUInteger previousSectionIndex = NSNotFound;

                    if (index > 0) {
                        previousItem = [_backingStore objectAtIndex:index - 1];
                        combineWithPreviousSection = _clusterComperator(previousItem, anObject);
                        previousSection = [_sectionsByItems objectForKey:previousItem];
                        previousSectionIndex = [_sections indexOfObject:previousSection];
                    }

                    if ([_backingStore count] > index + 1) {
                        nextItem = [_backingStore objectAtIndex:index + 1];
                        combineWithNextSection = _clusterComperator(anObject, nextItem);
                        nextSection = [_sectionsByItems objectForKey:nextItem];
                    }

                    if (combineWithPreviousSection == NO && combineWithNextSection == NO) {

                        NSMutableArray *newSection = [[NSMutableArray alloc] init];
                        [newSection addObject:anObject];

                        NSUInteger sectionIndex = previousSectionIndex == NSNotFound ? 0 : previousSectionIndex + 1;
                        [_sections insertObject:newSection atIndex:sectionIndex];
                        [_sectionsByItems setObject:newSection forKey:anObject];

                    } else if (combineWithPreviousSection == YES && combineWithNextSection == NO) {

                        NSUInteger indexOfPreviousItemInSection = [previousSection indexOfObject:previousItem];
                        [previousSection insertObject:anObject atIndex:indexOfPreviousItemInSection + 1];

                        [_sectionsByItems setObject:previousSection forKey:anObject];

                    } else if (combineWithPreviousSection == NO && combineWithNextSection == YES) {

                        NSUInteger indexOfNextItemInSection = [nextSection indexOfObject:nextItem];
                        [nextSection insertObject:anObject atIndex:indexOfNextItemInSection];

                        [_sectionsByItems setObject:previousSection forKey:anObject];

                    } else {

                        NSUInteger indexOfPreviousItemInSection = [previousSection indexOfObject:previousItem];
                        [previousSection insertObject:anObject atIndex:indexOfPreviousItemInSection + 1];

                        [_sectionsByItems setObject:previousSection forKey:anObject];

                        if (previousSection != nextSection) {
                            [previousSection addObjectsFromArray:nextSection];

                            for (id obj in nextSection) {
                                [_sectionsByItems setObject:previousSection forKey:obj];
                            }

                            [_sections removeObject:nextSection];
                        }
                    }
                }

                indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

            } else {
                [_backingStore addObject:anObject];
                NSUInteger index = [_backingStore count] - 1;

                indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];
            }

            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                    [observer dataSource:self didInsertItemsAtIndexPaths:@[ indexPath ]];
                }
            }

        }];
    }
}

- (void)removeObject:(id)object
{
    [self performBatchUpdates:^{

        NSUInteger index = [_backingStore indexOfObject:object];
        if (index != NSNotFound) {

            if (_clusterComperator) {

                NSMutableArray *section = [_sectionsByItems objectForKey:object];
                NSUInteger sectionIndex = [_sections indexOfObject:section];
                NSUInteger indexInSection = [section indexOfObject:object];
                NSMutableArray *newSection = nil;

                if ([section firstObject] != object && [section lastObject] != object) {

                    id previousItem = [section objectAtIndex:indexInSection - 1];
                    id nextItem = [section objectAtIndex:indexInSection + 1];

                    if (!_clusterComperator(previousItem, nextItem)) {

                        newSection = [[NSMutableArray alloc] init];
                        for (NSUInteger i = indexInSection + 1; i < [section count]; i++) {
                            id obj = [section objectAtIndex:i];
                            [newSection addObject:obj];
                            [_sectionsByItems setObject:newSection forKey:obj];
                        }
                    }
                }

                [_sectionsByItems removeObjectForKey:object];

                [section removeObject:object];
                if (newSection) {
                    [section removeObjectsInArray:newSection];
                    [_sections insertObject:newSection atIndex:sectionIndex + 1];
                } else if ([section count] == 0) {
                    [_sections removeObjectAtIndex:sectionIndex];
                }

            } else {

                [_backingStore removeObjectAtIndex:index];

                NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                        [observer dataSource:self didDeleteItemsAtIndexPaths:@[ indexPath ]];
                    }
                }
            }
        }
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

#pragma mark Batch Updates

- (void)performBatchUpdates:(void (^)(void))updates
{
    if (updates) {
        if (_batchUpdateCallCount == 0) {
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
                    [observer dataSourceWillChange:self];
                }
            }
        }

        _batchUpdateCallCount++;

        updates();

        _batchUpdateCallCount--;

        if (_batchUpdateCallCount == 0) {
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
                    [observer dataSourceDidChange:self];
                }
            }
        }
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
