//
//  FTDynamicDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 12.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTDynamicDataSource.h"

@interface FTDynamicDataSource ()
@property (nonatomic, readonly) NSComparator comperator;
@property (nonatomic, readonly) NSMutableArray *items;
@end

@implementation FTDynamicDataSource {
    NSHashTable *_observers;
}

#pragma mark Life-cycle

- (instancetype)initWithComerator:(NSComparator)comperator
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _comperator = comperator;
        _items = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.items count];
    } else {
        return 0;
    }
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath length] > 1 && [indexPath indexAtPosition:0] == 0) {
        NSUInteger index = [indexPath indexAtPosition:1];
        return [self.items objectAtIndex:index];
    } else {
        return nil;
    }
}

- (NSArray *)indexPathsOfItem:(id)item
{
    if (item) {
        NSUInteger index = [self.items indexOfObject:item];
        if (index != NSNotFound) {
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
            return @[[sectionIndexPath indexPathByAddingIndex:index]];
        }
    }
    return @[];
}

#pragma mark Getting Section Item

- (id)itemForSection:(NSInteger)section
{
    return nil;
}

- (NSIndexSet *)sectionsForItem:(id)item
{
    return [NSIndexSet indexSet];
}

#pragma mark Relaod

- (void)reloadWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    // Call the completion handler
    // ---------------------------
    
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

- (void)reloadWithItems:(NSArray *)items
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSourceWillReload:self];
    }
    
    // Sort new items
    // --------------
    
    [self.items removeAllObjects];
    [self.items addObjectsFromArray:items];
    [self.items sortUsingComparator:self.comperator];
    
    
    // Tell all observers to relaod
    // ----------------------------
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSourceDidReload:self];
    }
    
    // Call the completion handler
    // ---------------------------
    
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

#pragma mark Updating

- (void)updateWithDeletedItems:(NSArray *)deleted insertedItems:(NSArray *)inserted updatedItems:(NSArray *)updated
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSourceWillChange:self];
    }
    
    NSIndexSet *itemsToDelete = [self _deleteItems:deleted];
    NSIndexSet *itemsToInsert = [self _insertItems:inserted];
    NSArray *updates = [self _updateItems:updated];
    
    NSIndexPath *section = [NSIndexPath indexPathWithIndex:0];
    
    NSMutableArray *indexPathsOfDeletedItems = [[NSMutableArray alloc] init];
    [itemsToDelete enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPathsOfDeletedItems addObject:[section indexPathByAddingIndex:idx]];
    }];
    
    NSMutableArray *indexPathsOfInsertedItems = [[NSMutableArray alloc] init];
    [itemsToInsert enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPathsOfInsertedItems addObject:[section indexPathByAddingIndex:idx]];
    }];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSource:self didDeleteItemsAtIndexPaths:indexPathsOfDeletedItems];
        [observer dataSource:self didInsertItemsAtIndexPaths:indexPathsOfInsertedItems];
        
        [updates enumerateObjectsUsingBlock:^(NSArray *indexes, NSUInteger idx, BOOL *stop) {
            
            NSUInteger index = [[indexes firstObject] unsignedIntegerValue];
            NSUInteger newIndex = [[indexes lastObject] unsignedIntegerValue];
            
            if (index == newIndex) {
                [observer dataSource:self didReloadItemsAtIndexPaths:@[[section indexPathByAddingIndex:index]]];
            } else {
                [observer dataSource:self
              didMoveItemAtIndexPath:[section indexPathByAddingIndex:index]
                         toIndexPath:[section indexPathByAddingIndex:newIndex]];
            }
            
        }];
        [observer dataSourceDidChange:self];
    }
}

- (void)deleteItems:(NSArray *)items
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSourceWillChange:self];
    }
    
    NSIndexSet *itemsToDelete = [self _deleteItems:items];
    
    NSIndexPath *section = [NSIndexPath indexPathWithIndex:0];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    [itemsToDelete enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[section indexPathByAddingIndex:idx]];
    }];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSource:self didDeleteItemsAtIndexPaths:indexPaths];
        [observer dataSourceDidChange:self];
    }
}

- (NSIndexSet *)_deleteItems:(NSArray *)items
{
    NSMutableIndexSet *itemsToDelete = [[NSMutableIndexSet alloc] init];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger index = [self.items indexOfObject:obj];
        [itemsToDelete addIndex:index];
    }];
    
    [self.items removeObjectsAtIndexes:itemsToDelete];
    
    return itemsToDelete;
}

- (void)insertItems:(NSArray *)items
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSourceWillChange:self];
    }
    
    NSIndexSet *itemsToInsert = [self _insertItems:items];
    
    NSIndexPath *section = [NSIndexPath indexPathWithIndex:0];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    [itemsToInsert enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[section indexPathByAddingIndex:idx]];
    }];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSource:self didInsertItemsAtIndexPaths:indexPaths];
        [observer dataSourceDidChange:self];
    }
}

- (NSIndexSet *)_insertItems:(NSArray *)items
{
    items = [items sortedArrayUsingComparator:self.comperator];
    
    NSMutableIndexSet *itemsToInsert = [[NSMutableIndexSet alloc] init];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSUInteger offset = [itemsToInsert lastIndex];
        if (offset == NSNotFound) {
            offset = 0;
        }
        
        NSUInteger index = [self.items indexOfObject:obj
                                       inSortedRange:NSMakeRange(offset, [self.items count] - offset)
                                             options:NSBinarySearchingInsertionIndex
                                     usingComparator:self.comperator];
        [itemsToInsert addIndex:index];
        
        [self.items insertObject:obj atIndex:index];
    }];
    
    return itemsToInsert;
}

- (void)updateItems:(NSArray *)items
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer dataSourceWillChange:self];
    }
    
    NSArray *updates = [self _updateItems:items];
    
    NSIndexPath *sectionIndex = [NSIndexPath indexPathWithIndex:0];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [updates enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL *stop) {
            NSUInteger index = [[obj firstObject] unsignedIntegerValue];
            NSUInteger newIndex = [[obj lastObject] unsignedIntegerValue];
            if (index != newIndex) {
                [observer dataSource:self
              didMoveItemAtIndexPath:[sectionIndex indexPathByAddingIndex:index]
                         toIndexPath:[sectionIndex indexPathByAddingIndex:newIndex]];
            }
        }];
        [observer dataSourceDidChange:self];
    }
}

- (NSArray *)_updateItems:(NSArray *)items
{
    items = [items sortedArrayUsingComparator:self.comperator];
    
    __block NSUInteger lastIndex = 0;
    
    NSMutableArray *updates = [[NSMutableArray alloc] init];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSUInteger index = [self.items indexOfObject:obj];
        if (index != NSNotFound) {
            [self.items removeObjectAtIndex:index];
        }
        
        NSUInteger newIndex = [self.items indexOfObject:obj
                                          inSortedRange:NSMakeRange(lastIndex, [self.items count] - lastIndex)
                                                options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                                        usingComparator:self.comperator];
        [self.items insertObject:obj atIndex:newIndex];
        
        [updates addObject:@[@(index), @(newIndex)]];
    }];
    
    return updates;
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

@end
