//
//  FTSectionDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTSectionDataSource.h"

@interface FTSectionDataSource ()
@property (nonatomic, readonly) NSComparator comperator;
@property (nonatomic, readonly) FTSectionDataSourceSectionIdentifier identifier;

@property (nonatomic, readonly) NSMutableArray *sectionItems;
@property (nonatomic, readonly) NSMapTable *sectionItemItentifiers;

@property (nonatomic, readonly) NSHashTable *observers;
@end

@implementation FTSectionDataSource

#pragma mark Life-cycle

- (instancetype)initWithComerator:(NSComparator)comperator
                        identifer:(FTSectionDataSourceSectionIdentifier)identifier
{
    self = [super init];
    if (self) {
        _comperator = comperator;
        _identifier = identifier;
        
        _sectionItems = [[NSMutableArray alloc] init];
        _sectionItemItentifiers = [NSMapTable strongToWeakObjectsMapTable];
        
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    return [self.sectionItems count];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSArray *)indexPathsOfItem:(id)item
{
    return @[];
}

#pragma mark Getting Section Item

- (id)itemForSection:(NSInteger)section
{
    return [self.sectionItems objectAtIndex:section];
}

- (NSIndexSet *)sectionsForItem:(id)item
{
    id identifier = self.identifier(item);
    return [self.sectionItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [identifier isEqual:self.identifier(obj)];
    }];
}

#pragma mark Reload

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

- (void)reloadWithInitialSectionItems:(NSArray *)sectionItems
                    completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    // Prepare the initial sections
    // ----------------------------
    
    [self.sectionItems removeAllObjects];
    [self.sectionItems addObjectsFromArray:sectionItems];
    [self.sectionItems sortUsingComparator:self.comperator];
    
    [self.sectionItemItentifiers removeAllObjects];
    [self.sectionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.sectionItemItentifiers setObject:obj forKey:self.identifier(obj)];
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

- (void)updateWithDeletions:(NSArray *)deletions insertions:(NSArray *)insertions updates:(NSArray *)updates
{
    NSIndexSet *deletedSections = [self _deleteSectionItems:deletions];
    NSIndexSet *insertedSections = [self _insertSectionItems:insertions];
    NSArray *movedSections = [self _updateSectionItems:updates];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer performBatchUpdate:^{
            [observer deleteSections:deletedSections];
            [observer insertSections:insertedSections];
            [movedSections enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL *stop) {
                NSUInteger index = [[obj firstObject] unsignedIntegerValue];
                NSUInteger newIndex = [[obj lastObject] unsignedIntegerValue];
                if (index != newIndex) {
                    [observer moveSection:index toSection:newIndex];
                }
            }];
        }];
    }
}

- (void)deleteSectionItems:(NSArray *)sectionItems
{
    NSIndexSet *sectionsToDelete = [self _deleteSectionItems:sectionItems];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer deleteSections:sectionsToDelete];
    }
}

- (NSIndexSet *)_deleteSectionItems:(NSArray *)sectionItems
{
    NSMutableIndexSet *sectionsToDelete = [[NSMutableIndexSet alloc] init];
    [sectionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger index = [self.sectionItems indexOfObject:[self.sectionItemItentifiers objectForKey:self.identifier(obj)]];
        [sectionsToDelete addIndex:index];
    }];
    
    [self.sectionItems removeObjectsAtIndexes:sectionsToDelete];
    
    return sectionsToDelete;
}

- (void)insertSectionItems:(NSArray *)sectionItems
{
    NSIndexSet *sectionsToInsert = [self _insertSectionItems:sectionItems];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer insertSections:sectionsToInsert];
    }
}

- (NSIndexSet *)_insertSectionItems:(NSArray *)sectionItems
{
    sectionItems = [sectionItems sortedArrayUsingComparator:self.comperator];
    
    NSMutableIndexSet *sectionsToInsert = [[NSMutableIndexSet alloc] init];
    
    [sectionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.sectionItemItentifiers setObject:obj forKey:self.identifier(obj)];
        
        NSUInteger offset = [sectionsToInsert lastIndex];
        if (offset == NSNotFound) {
            offset = 0;
        }
        
        NSUInteger index = [self.sectionItems indexOfObject:obj
                                              inSortedRange:NSMakeRange(offset, [self.sectionItems count] - offset)
                                                    options:NSBinarySearchingInsertionIndex
                                            usingComparator:self.comperator];
        [sectionsToInsert addIndex:index];
        
        [self.sectionItems insertObject:obj atIndex:index];
    }];
    
    return sectionsToInsert;
}

- (void)updateSectionItems:(NSArray *)sectionItems
{
    NSArray *updates = [self _updateSectionItems:sectionItems];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [updates enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL *stop) {
            NSUInteger index = [[obj firstObject] unsignedIntegerValue];
            NSUInteger newIndex = [[obj lastObject] unsignedIntegerValue];
            if (index != newIndex) {
                [observer moveSection:index toSection:newIndex];
            }
        }];
    }
}

- (NSArray *)_updateSectionItems:(NSArray *)sectionItems
{
    sectionItems = [sectionItems sortedArrayUsingComparator:self.comperator];
    
    __block NSUInteger lastIndex = 0;
    
    NSMutableArray *updates = [[NSMutableArray alloc] init];
    
    [sectionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSUInteger index = [self.sectionItems indexOfObject:[self.sectionItemItentifiers objectForKey:self.identifier(obj)]];
        NSUInteger newIndex = [self.sectionItems indexOfObject:obj
                                                 inSortedRange:NSMakeRange(lastIndex, [self.sectionItems count] - lastIndex)
                                                       options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                                               usingComparator:self.comperator];
        
        [updates addObject:@[@(index), @(newIndex)]];
        
        [self.sectionItemItentifiers setObject:obj forKey:self.identifier(obj)];
        
        if (newIndex < index) {
            [self.sectionItems removeObjectAtIndex:index];
            [self.sectionItems insertObject:obj atIndex:newIndex];
        } else if (newIndex > index) {
            [self.sectionItems insertObject:obj atIndex:newIndex];
            [self.sectionItems removeObjectAtIndex:index];
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
