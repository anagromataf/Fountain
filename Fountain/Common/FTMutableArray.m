//
//  FTMutableArray.m
//  Fountain
//
//  Created by Tobias Kraentzer on 24.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSourceObserver.h"

#import "FTMutableArray.h"

@implementation FTMutableArray {
    NSMutableArray *_backingStore;
    NSHashTable *_observers;
    NSUInteger _batchUpdateCallCount;
}

#pragma mark Life-cycle

- (nonnull instancetype)init
{
    return [self initWithBackingStore:[[NSMutableArray alloc] init]];
}

- (nonnull instancetype)initWithObjects:(const id __unsafe_unretained *)objects count:(NSUInteger)cnt
{
    return [self initWithBackingStore:[[NSMutableArray alloc] initWithObjects:objects count:cnt]];
}

- (nonnull instancetype)initWithBackingStore:(NSMutableArray *)backingStore
{
    self = [super init];
    if (self) {
        _backingStore = backingStore;
        _observers = [[NSHashTable alloc] init];
        _batchUpdateCallCount = 0;
    }
    return self;
}

#pragma mark FTMutableArray

- (void)replaceAllObjectsWithObjects:(NSArray *)objects
{
    [self ft_performBatchUpdate:^{
        [self removeAllObjects];
        [self addObjectsFromArray:objects];
    }];
}

- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [self ft_performBatchUpdate:^{
        id object = [self objectAtIndex:fromIndex];
        [self insertObject:object atIndex:toIndex];
        if (fromIndex < toIndex) {
            [self removeObjectAtIndex:fromIndex];
        } else if (fromIndex > toIndex) {
            [self removeObjectAtIndex:fromIndex + 1];
        }
    }];
}

#pragma mark NSArray

- (NSUInteger)count
{
    return [_backingStore count];
}

- (nonnull id)objectAtIndex:(NSUInteger)index
{
    return [_backingStore objectAtIndex:index];
}

#pragma mark NSMutableArray

- (void)insertObject:(nonnull id)anObject atIndex:(NSUInteger)index
{
    [self ft_performBatchUpdate:^{

        [_backingStore insertObject:anObject atIndex:index];

        NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                [observer dataSource:self didInsertItemsAtIndexPaths:@[ indexPath ]];
            }
        }
    }];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [self ft_performBatchUpdate:^{

        [_backingStore removeObjectAtIndex:index];

        NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                [observer dataSource:self didDeleteItemsAtIndexPaths:@[ indexPath ]];
            }
        }
    }];
}

- (void)addObject:(nonnull id)anObject
{
    [self ft_performBatchUpdate:^{

        [_backingStore addObject:anObject];

        NSUInteger index = [_backingStore count] - 1;

        NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                [observer dataSource:self didInsertItemsAtIndexPaths:@[ indexPath ]];
            }
        }
    }];
}

- (void)addObjectsFromArray:(NSArray *)otherArray
{
    [self ft_performBatchUpdate:^{
        [super addObjectsFromArray:otherArray];
    }];
}

- (void)removeLastObject
{
    [self ft_performBatchUpdate:^{

        [_backingStore removeLastObject];

        NSUInteger index = [_backingStore count];

        NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                [observer dataSource:self didDeleteItemsAtIndexPaths:@[ indexPath ]];
            }
        }
    }];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(nonnull id)anObject
{
    [self ft_performBatchUpdate:^{

        [_backingStore replaceObjectAtIndex:index withObject:anObject];

        NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:index];

        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didChangeItemsAtIndexPaths:)]) {
                [observer dataSource:self didChangeItemsAtIndexPaths:@[ indexPath ]];
            }
        }
    }];
}

- (void)replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
{
    [self ft_performBatchUpdate:^{
        [super replaceObjectsAtIndexes:indexes withObjects:objects];
    }];
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[[self class] alloc] initWithBackingStore:[_backingStore mutableCopy]];
}

#pragma mark NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithBackingStore:[_backingStore mutableCopy]];
}

#pragma mark NSCoding

- (Class)classForCoder
{
    return [FTMutableArray class];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_backingStore forKey:@"_backingStore"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _backingStore = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"_backingStore"];
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

#pragma mark Batch Updates

- (void)ft_performBatchUpdate:(void (^)(void))updates
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
    return 1;
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
