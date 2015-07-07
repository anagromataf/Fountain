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
@end

@implementation FTStaticDataSource {
    NSHashTable *_observers;
}

#pragma mark Life-cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
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
            return @[ [sectionIndexPath indexPathByAddingIndex:index] ];
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

- (void)reloadWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler
{
    // Call the completion handler
    // ---------------------------

    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

- (void)reloadWithItems:(NSArray *)items
      completionHandler:(void (^)(BOOL success, NSError *error))completionHandler
{

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceWillReload:)]) {
            [observer dataSourceWillReload:self];
        }
    }

    // Set the Items
    // -------------

    self.items = [items copy];

    // Tell all observers to relaod
    // ----------------------------

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceDidReload:)]) {
            [observer dataSourceDidReload:self];
        }
    }

    // Call the completion handler
    // ---------------------------

    if (completionHandler) {
        completionHandler(YES, nil);
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

@end
