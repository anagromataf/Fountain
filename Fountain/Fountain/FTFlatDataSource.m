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

- (void)deleteItems:(NSArray *)sectionItems
{
}

- (void)insertItems:(NSArray *)sectionItems
{
}

- (void)updateItems:(NSArray *)sectionItems
{
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
