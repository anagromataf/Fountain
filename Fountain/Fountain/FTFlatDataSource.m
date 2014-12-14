//
//  FTFlatDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 12.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTFlatDataSource.h"

@interface FTFlatDataSource ()
@property (nonatomic, readonly) NSComparator comperator;
@property (nonatomic, readonly) FTFlatDataSourceItemIdentifier identifier;

@property (nonatomic, readonly) NSMutableArray *items;
@property (nonatomic, readonly) NSMapTable *itemItentifiers;

@property (nonatomic, readonly) NSHashTable *observers;
@end

@implementation FTFlatDataSource

#pragma mark Life-cycle

- (instancetype)initWithComerator:(NSComparator)comperator
                       identifier:(FTFlatDataSourceItemIdentifier)identifier
{
    self = [super init];
    if (self) {
        _comperator = comperator;
        _identifier = identifier;
        
        _items = [[NSMutableArray alloc] init];
        _itemItentifiers = [NSMapTable strongToWeakObjectsMapTable];
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
    id identifier = self.identifier(item);
    id object = [self.itemItentifiers objectForKey:identifier];
    if (object) {
        NSUInteger index = [self.items indexOfObject:object];
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
    // Tell all observers to relaod
    // ----------------------------
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer reload];
    }
    
    
    // Call the completion handler
    // ---------------------------
    
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

- (void)reloadWithItems:(NSArray *)sectionItems
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    // Sort new items
    // --------------
    
    [self.items removeAllObjects];
    [self.items addObjectsFromArray:sectionItems];
    [self.items sortUsingComparator:self.comperator];
    
    [self.itemItentifiers removeAllObjects];
    [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.itemItentifiers setObject:obj forKey:self.identifier(obj)];
    }];
    
    // Tell all observers to relaod
    // ----------------------------
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer reload];
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
}

- (void)deleteItems:(NSArray *)items
{
    NSIndexSet *itemsToDelete = [self _deleteItems:items];
    
    NSIndexPath *section = [NSIndexPath indexPathWithIndex:0];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    [itemsToDelete enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[section indexPathByAddingIndex:idx]];
    }];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer deleteItemsAtIndexPaths:indexPaths];
    }
}

- (NSIndexSet *)_deleteItems:(NSArray *)items
{
    NSMutableIndexSet *itemsToDelete = [[NSMutableIndexSet alloc] init];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger index = [self.items indexOfObject:[self.itemItentifiers objectForKey:self.identifier(obj)]];
        [itemsToDelete addIndex:index];
    }];
    
    [self.items removeObjectsAtIndexes:itemsToDelete];
    
    return itemsToDelete;
}

- (void)insertItems:(NSArray *)items
{
    NSIndexSet *itemsToInsert = [self _insertItems:items];
    
    NSIndexPath *section = [NSIndexPath indexPathWithIndex:0];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    [itemsToInsert enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[section indexPathByAddingIndex:idx]];
    }];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer insertItemsAtIndexPaths:indexPaths];
    }
}

- (NSIndexSet *)_insertItems:(NSArray *)items
{
    items = [items sortedArrayUsingComparator:self.comperator];
    
    NSMutableIndexSet *itemsToInsert = [[NSMutableIndexSet alloc] init];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.itemItentifiers setObject:obj forKey:self.identifier(obj)];
        
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
    NSArray *updates = [self _updateItems:items];
    
    NSIndexPath *sectionIndex = [NSIndexPath indexPathWithIndex:0];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [updates enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL *stop) {
            NSUInteger index = [[obj firstObject] unsignedIntegerValue];
            NSUInteger newIndex = [[obj lastObject] unsignedIntegerValue];
            if (index != newIndex) {
                [observer moveItemAtIndexPath:[sectionIndex indexPathByAddingIndex:index]
                                  toIndexPath:[sectionIndex indexPathByAddingIndex:newIndex]];
            }
        }];
    }
}

- (NSArray *)_updateItems:(NSArray *)items
{
    items = [items sortedArrayUsingComparator:self.comperator];
    
    __block NSUInteger lastIndex = 0;
    
    NSMutableArray *updates = [[NSMutableArray alloc] init];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSUInteger index = [self.items indexOfObject:[self.itemItentifiers objectForKey:self.identifier(obj)]];
        NSUInteger newIndex = [self.items indexOfObject:obj
                                                 inSortedRange:NSMakeRange(lastIndex, [self.items count] - lastIndex)
                                                       options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                                               usingComparator:self.comperator];
        
        [updates addObject:@[@(index), @(newIndex)]];
        
        [self.itemItentifiers setObject:obj forKey:self.identifier(obj)];
        
        if (newIndex < index) {
            [self.items removeObjectAtIndex:index];
            [self.items insertObject:obj atIndex:newIndex];
        } else if (newIndex > index) {
            [self.items insertObject:obj atIndex:newIndex];
            [self.items removeObjectAtIndex:index];
        }
    }];
    
    return updates;
}

#pragma mark Observer

@synthesize observers = _observers;
- (NSHashTable *)observers
{
    if (_observers == nil) {
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return _observers;
}

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers addObject:observer];
    [observer reload];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers removeObject:observer];
}

@end
