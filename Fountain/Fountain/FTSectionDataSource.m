//
//  FTSectionDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTSectionDataSource.h"

@interface FTSectionDataSource ()
@property (nonatomic, readonly) NSHashTable *observers;
@end

@implementation FTSectionDataSource

#pragma mark Life-cycle

- (instancetype)initWithSectionDataSource:(id<FTDataSource>)sectionDataSource
{
    self = [super init];
    if (self) {
        _sectionDataSource = sectionDataSource;
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
        [observer reload];
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
    [observer reload];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers removeObject:observer];
}

@end
