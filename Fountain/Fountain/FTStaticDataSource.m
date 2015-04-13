//
//  FTStaticDataSource.m
//  Fountain
//
//  Created by Tobias Kraentzer on 13.04.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTStaticDataSource.h"

@interface FTStaticDataSource ()
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, readonly) NSHashTable *observers;
@end

@implementation FTStaticDataSource


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
    
    // Set the Items
    // -------------
    
    self.items = [items copy];
    
    
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
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers removeObject:observer];
}

@end
