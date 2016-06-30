//
//  FTObserverProxy.m
//  Fountain
//
//  Created by Tobias Kraentzer on 25.04.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "FTObserverProxy.h"

@interface FTObserverProxy () {
    NSHashTable *_observers;
}

@end

@implementation FTObserverProxy

#pragma mark Life-cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark Observer

- (NSArray *)observers;
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

#pragma mark -
#pragma mark FTDataSourceObserver

- (void)dataSourceWillReset:(id<FTDataSource>)dataSource
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceWillReset:)]) {
            [observer dataSourceWillReset:self.object ?: self];
        }
    }
}

- (void)dataSourceDidReset:(id<FTDataSource>)dataSource
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceDidReset:)]) {
            [observer dataSourceDidReset:self.object ?: self];
        }
    }
}

#pragma mark Begin End Updates

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
            [observer dataSourceWillChange:self.object ?: self];
        }
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
            [observer dataSourceDidChange:self.object ?: self];
        }
    }
}

#pragma mark Manage Sections

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didInsertSections:)]) {
            [observer dataSource:self.object ?: self didInsertSections:sections];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didDeleteSections:)]) {
            [observer dataSource:self.object ?: self didDeleteSections:sections];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeSections:(NSIndexSet *)sections
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didChangeSections:)]) {
            [observer dataSource:self.object ?: self didChangeSections:sections];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didMoveSection:toSection:)]) {
            [observer dataSource:self.object ?: self didMoveSection:section toSection:newSection];
        }
    }
}

#pragma mark Manage Items

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
            [observer dataSource:self.object ?: self didInsertItemsAtIndexPaths:indexPaths];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
            [observer dataSource:self.object ?: self didDeleteItemsAtIndexPaths:indexPaths];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeItemsAtIndexPaths:(NSArray *)indexPaths
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didChangeItemsAtIndexPaths:)]) {
            [observer dataSource:self.object ?: self didChangeItemsAtIndexPaths:indexPaths];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)]) {
            [observer dataSource:self.object ?: self didMoveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
        }
    }
}

@end
