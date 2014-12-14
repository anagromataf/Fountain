//
//  FTSectionDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTSectionDataSource.h"

@interface FTSectionDataSource () <FTDataSourceObserver>
@property (nonatomic, assign) BOOL updating;
@property (nonatomic, readonly) NSHashTable *observers;
@end

@implementation FTSectionDataSource

#pragma mark Life-cycle

- (instancetype)initWithSectionDataSource:(id<FTDataSource>)sectionDataSource
{
    self = [super init];
    if (self) {
        _sectionDataSource = sectionDataSource;
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
    [observer dataSourceDidReload:self];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers removeObject:observer];
}

#pragma mark - FTDataSourceObserver

#pragma mark Reload

- (void)dataSourceDidReload:(id<FTDataSource>)dataSource
{
    if (dataSource == self.sectionDataSource) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            [observer dataSourceDidReload:self];
        }
    }
}

#pragma mark Begin End Updates

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (self.updating == NO) {
        self.updating = YES;
        for (id<FTDataSourceObserver> observer in self.observers) {
            [observer dataSourceWillChange:self];
        }
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    if (self.updating == YES) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            [observer dataSourceDidChange:self];
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
            [observer dataSource:self didInsertSections:indexes];
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
            }
        }
        
        for (id<FTDataSourceObserver> observer in self.observers) {
            [observer dataSource:self didDeleteSections:indexes];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.sectionDataSource) {
        
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
            
            for (id<FTDataSourceObserver> observer in self.observers) {
                [observer dataSource:self didMoveSection:index toSection:newIndex];
            }
        }
    }
}


@end
