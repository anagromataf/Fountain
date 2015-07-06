//
//  FTComposedDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTComposedDataSource.h"

@interface FTComposedDataSource () <FTDataSourceObserver>
@property (nonatomic, assign) BOOL updating;
@property (nonatomic, readonly) NSMapTable *sectionDataSources;
@end

@implementation FTComposedDataSource {
    NSHashTable *_observers;
}

#pragma mark Life-cycle

- (instancetype)initWithSectionDataSource:(id<FTDataSource>)sectionDataSource
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _sectionDataSource = sectionDataSource;
        _sectionDataSources = [NSMapTable strongToStrongObjectsMapTable];
        [_sectionDataSource addObserver:self];
    }
    return self;
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    if ([self.sectionDataSource numberOfSections] > 0) {
        return [self.sectionDataSource numberOfItemsInSection:0];
    }
    return 0;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    id<FTDataSource> dataSource = [self dataSourceForSection:section];
    if (dataSource && [dataSource numberOfSections] > 0) {
        return [dataSource numberOfItemsInSection:0];
    } else {
        return 0;
    }
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath length] >= 2) {
        NSUInteger section = [indexPath indexAtPosition:0];
        id<FTDataSource> dataSource = [self dataSourceForSection:section];
        if (dataSource) {
            NSIndexPath *childIndexPath = [NSIndexPath indexPathWithIndex:0];
            childIndexPath = [childIndexPath indexPathByAddingIndex:[indexPath indexAtPosition:1]];
            return [dataSource itemAtIndexPath:childIndexPath];
        } else {
            return nil;
        }
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
    if ([self.sectionDataSource numberOfSections] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:0];
        return [self.sectionDataSource itemAtIndexPath:[indexPath indexPathByAddingIndex:section]];
    }
    return nil;
}

- (NSIndexSet *)sectionsForItem:(id)item
{
    NSArray *indexPaths = [self.sectionDataSource indexPathsOfItem:item];
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        if ([indexPath indexAtPosition:0] == 0) {
            [indexes addIndex:[indexPath indexAtPosition:1]];
        }
    }];
    return indexes;
}

#pragma mark Reload

- (void)reloadWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    // Call the completion handler
    // ---------------------------
    
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

#pragma mark Section Data Sources

- (id<FTDataSource>)createDataSourceWithSectionItem:(id)sectionItem
{
    return nil;
}

- (id<FTDataSource>)dataSourceForSection:(NSUInteger)section
{
    id<FTDataSource> dataSource = [self.sectionDataSources objectForKey:@(section)];
    if (dataSource == nil) {
        id sectionItem = [self itemForSection:section];
        if (sectionItem) {
            dataSource = [self createDataSourceWithSectionItem:sectionItem];
            [dataSource addObserver:self];
            [self.sectionDataSources setObject:dataSource forKey:@(section)];
        }
    }
    
    if (dataSource == nil) {
        [self.sectionDataSources setObject:[NSNull null] forKey:@(section)];
    }
    
    return [dataSource isEqual:[NSNull null]] ? nil : dataSource;
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

#pragma mark - FTDataSourceObserver

#pragma mark Reload

- (void)dataSourceWillReload:(id<FTDataSource>)dataSource
{
    if (dataSource == self.sectionDataSource) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceWillReload:)]) {
                [observer dataSourceWillReload:self];
            }
        }
    } else {
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
                [observer dataSourceWillChange:self];
            }
        }
    }
}

- (void)dataSourceDidReload:(id<FTDataSource>)dataSource
{
    if (dataSource == self.sectionDataSource) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceDidReload:)]) {
                [observer dataSourceDidReload:self];
            }
        }
    } else {
        NSUInteger section = NSNotFound;
        for (id key in [self.sectionDataSources keyEnumerator]) {
            if ([self.sectionDataSources objectForKey:key] == dataSource) {
                section = [key integerValue];
                break;
            }
        }
        
        if (section != NSNotFound) {
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didReloadSections:)]) {
                    [observer dataSource:self didReloadSections:[NSIndexSet indexSetWithIndex:section]];
                }
                if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
                    [observer dataSourceDidChange:self];
                }
            }
        }
    }
}

#pragma mark Begin End Updates

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (self.updating == NO) {
        self.updating = YES;
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
                [observer dataSourceWillChange:self];
            }
        }
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    if (self.updating == YES) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
                [observer dataSourceDidChange:self];
            }
        }
        self.updating = NO;
    }
}

#pragma mark Manage Sections

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    if (dataSource == self.sectionDataSource) {
        
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    if (dataSource == self.sectionDataSource) {
        
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadSections:(NSIndexSet *)sections
{
    if (dataSource == self.sectionDataSource) {
        
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (dataSource == self.sectionDataSource) {
        
    }
}

#pragma mark Manage Items

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.sectionDataSource) {
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        
        for (NSIndexPath *indexPath in indexPaths) {
            if ([indexPath length] >= 2 && [indexPath indexAtPosition:0] == 0) {
                NSUInteger index = [indexPath indexAtPosition:1];
                [indexes addIndex:index];
            }
        }
        
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didInsertSections:)]) {
                [observer dataSource:self didInsertSections:indexes];
            }
        }
    } else {
        NSUInteger section = NSNotFound;
        for (id key in [self.sectionDataSources keyEnumerator]) {
            if ([self.sectionDataSources objectForKey:key] == dataSource) {
                section = [key integerValue];
                break;
            }
        }
        
        if (section != NSNotFound) {
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:section];
            
            NSMutableArray *translatedIndexPaths = [[NSMutableArray alloc] init];
            for (NSIndexPath *indexPath in indexPaths) {
                if ([indexPath length] >= 2 && [indexPath indexAtPosition:0] == 0) {
                    NSUInteger index = [indexPath indexAtPosition:1];
                    [translatedIndexPaths addObject:[sectionIndexPath indexPathByAddingIndex:index]];
                }
            }
            
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                    [observer dataSource:self didInsertItemsAtIndexPaths:translatedIndexPaths];
                }
            }
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.sectionDataSource) {
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        
        for (NSIndexPath *indexPath in indexPaths) {
            if ([indexPath length] >= 2 && [indexPath indexAtPosition:0] == 0) {
                NSUInteger index = [indexPath indexAtPosition:1];
                [indexes addIndex:index];
                [self.sectionDataSources removeObjectForKey:@(index)];
            }
        }
        
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSource:didDeleteSections:)]) {
                [observer dataSource:self didDeleteSections:indexes];
            }
        }
    } else {
        NSUInteger section = NSNotFound;
        for (id key in [self.sectionDataSources keyEnumerator]) {
            if ([self.sectionDataSources objectForKey:key] == dataSource) {
                section = [key integerValue];
                break;
            }
        }
        
        if (section != NSNotFound) {
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:section];
            
            NSMutableArray *translatedIndexPaths = [[NSMutableArray alloc] init];
            for (NSIndexPath *indexPath in indexPaths) {
                if ([indexPath length] >= 2 && [indexPath indexAtPosition:0] == 0) {
                    NSUInteger index = [indexPath indexAtPosition:1];
                    [translatedIndexPaths addObject:[sectionIndexPath indexPathByAddingIndex:index]];
                }
            }
            
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                    [observer dataSource:self didDeleteItemsAtIndexPaths:translatedIndexPaths];
                }
            }
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.sectionDataSource) {
        
    } else {
        NSUInteger section = NSNotFound;
        for (id key in [self.sectionDataSources keyEnumerator]) {
            if ([self.sectionDataSources objectForKey:key] == dataSource) {
                section = [key integerValue];
                break;
            }
        }
        
        if (section != NSNotFound) {
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:section];
            
            NSMutableArray *translatedIndexPaths = [[NSMutableArray alloc] init];
            for (NSIndexPath *indexPath in indexPaths) {
                if ([indexPath length] >= 2 && [indexPath indexAtPosition:0] == 0) {
                    NSUInteger index = [indexPath indexAtPosition:1];
                    [translatedIndexPaths addObject:[sectionIndexPath indexPathByAddingIndex:index]];
                }
            }
            
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didReloadSections:)]) {
                    [observer dataSource:self didReloadItemsAtIndexPaths:translatedIndexPaths];
                }
            }
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    if (dataSource == self.sectionDataSource) {
        if ([indexPath length] >= 2 &&
            [newIndexPath length] >= 2 &&
            [indexPath indexAtPosition:0] == 0 &&
            [newIndexPath indexAtPosition:0] == 0) {
            
            NSUInteger index = [indexPath indexAtPosition:1];
            NSUInteger newIndex = [newIndexPath indexAtPosition:1];
            
            id<FTDataSource> sectionDataSource = [self.sectionDataSources objectForKey:@(index)];
            if (sectionDataSource) {
                [self.sectionDataSources removeObjectForKey:@(index)];
                [self.sectionDataSources setObject:sectionDataSource
                                            forKey:@(newIndex)];
            }
            
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didMoveSection:toSection:)]) {
                    [observer dataSource:self didMoveSection:index toSection:newIndex];
                }
            }
        }
    } else {
        NSUInteger section = NSNotFound;
        for (id key in [self.sectionDataSources keyEnumerator]) {
            if ([self.sectionDataSources objectForKey:key] == dataSource) {
                section = [key integerValue];
                break;
            }
        }
        
        if (section != NSNotFound) {
            
            if ([indexPath length] >= 2 &&
                [newIndexPath length] >= 2 &&
                [indexPath indexAtPosition:0] == 0 &&
                [newIndexPath indexAtPosition:0] == 0) {
            
                NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:section];
                
                NSUInteger index = [indexPath indexAtPosition:1];
                NSUInteger newIndex = [newIndexPath indexAtPosition:1];
                
                for (id<FTDataSourceObserver> observer in self.observers) {
                    if ([observer respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)]) {
                        [observer dataSource:self
                      didMoveItemAtIndexPath:[sectionIndexPath indexPathByAddingIndex:index]
                                 toIndexPath:[sectionIndexPath indexPathByAddingIndex:newIndex]];
                    }
                }
            }
        }
    }
}

@end
