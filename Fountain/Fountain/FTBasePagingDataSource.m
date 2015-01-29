//
//  FTPagingDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 29.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTBasePagingDataSource.h"

@interface FTBasePagingDataSource ()
@property (nonatomic, readonly) NSMutableArray *items;
@property (nonatomic, assign, readwrite) NSUInteger totalNumberOfItems;
@property (nonatomic, readonly) NSHashTable *observers;

@property (nonatomic, weak) id<FTPagingDataSourceOperation> loadingOperation;
@property (nonatomic, readonly) NSMutableArray *completionHandler;
@end

@implementation FTBasePagingDataSource

+ (NSSet *)keyPathsForValuesAffectingLoading
{
    return [NSSet setWithObject:@"loadingOperation"];
}

+ (NSSet *)keyPathsForValuesAffectingHasMoreItems
{
    return [NSSet setWithObjects:@"numberOfItems", nil];
}

#pragma mark Life-cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _items = [[NSMutableArray alloc] init];
        _completionHandler = [[NSMutableArray alloc] init];
        _pageSize = 10;
    }
    return self;
}

#pragma mark All Items

- (NSArray *)allItems
{
    return [self.items copy];
}

#pragma mark State

- (BOOL)isLoading
{
    return self.loadingOperation != nil;
}

- (BOOL)hasMoreItems
{
    return [self.items count] < self.totalNumberOfItems;
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.items count];
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

#pragma mark Reload

- (void)reloadWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    [self loadItemsWithOffset:0 limit:self.pageSize reset:YES completion:completionHandler];
}

- (void)resetCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    [self loadItemsWithOffset:0 limit:0 reset:YES completion:completionHandler];
}

- (void)loadNextPageCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (self.hasMoreItems) {
        NSUInteger limit = self.pageSize;
        NSUInteger offset = [self.items count];
        [self loadItemsWithOffset:offset limit:limit reset:NO completion:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(YES, nil);
        }
    }
}

- (id<FTPagingDataSourceOperation>)fetchItemsWithOffset:(NSUInteger)offset
                                                  limit:(NSUInteger)limit
                                             completion:(void(^)(NSArray *items, NSUInteger offset, NSUInteger limit, NSUInteger total, NSError *error))completion
{
    
    if (completion) {
        completion(@[], offset, limit, 0, nil);
    }
    
    return nil;
}

#pragma mark Observer

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers addObject:observer];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers removeObject:observer];
}

#pragma mark Load Items

- (void)loadItemsWithOffset:(NSUInteger)offset
                      limit:(NSUInteger)limit
                      reset:(BOOL)reset
                 completion:(void(^)(BOOL success, NSError *error))completion
{
    if (completion) {
        [self.completionHandler addObject:completion];
    }

    if (reset && self.loadingOperation) {
        [self.loadingOperation cancel];
        self.loadingOperation = nil;
    }
    
    if (self.loadingOperation == nil) {
        
        if (limit == 0) {
            
            if (reset) {
                [[self.observers allObjects] enumerateObjectsUsingBlock:^(id<FTDataSourceObserver> observer, NSUInteger idx, BOOL *stop) {
                    [observer dataSourceWillChange:self];
                }];
                
                [self willChangeValueForKey:@"hasMoreItems"];
                [self.items removeAllObjects];
                self.totalNumberOfItems = 0;
                
                [self didChangeValueForKey:@"hasMoreItems"];
                
                [[self.observers allObjects] enumerateObjectsUsingBlock:^(id<FTDataSourceObserver> observer, NSUInteger idx, BOOL *stop) {
                    [observer dataSource:self didReloadSections:[NSIndexSet indexSetWithIndex:0]];
                    [observer dataSourceDidChange:self];
                }];
            }
            
            for (void(^completion)(BOOL success, NSError *error) in self.completionHandler) {
                completion(YES, nil);
            }
            
        } else {
            self.loadingOperation = [self fetchItemsWithOffset:offset
                                                         limit:limit
                                                    completion:^(NSArray *items,
                                                                 NSUInteger offset,
                                                                 NSUInteger limit,
                                                                 NSUInteger total,
                                                                 NSError *error) {
                                                        if (items) {
                                                            
                                                            [[self.observers allObjects] enumerateObjectsUsingBlock:^(id<FTDataSourceObserver> observer, NSUInteger idx, BOOL *stop) {
                                                                [observer dataSourceWillChange:self];
                                                            }];
                                                            
                                                            [self willChangeValueForKey:@"hasMoreItems"];
                                                            
                                                            if (reset) {
                                                                [self.items removeAllObjects];
                                                            }
                                                            
                                                            [self.items addObjectsFromArray:items];
                                                            self.totalNumberOfItems = total;
                                                            
                                                            [self didChangeValueForKey:@"hasMoreItems"];
                                                            
                                                            [[self.observers allObjects] enumerateObjectsUsingBlock:^(id<FTDataSourceObserver> observer, NSUInteger idx, BOOL *stop) {
                                                                
                                                                if (reset) {
                                                                    [observer dataSource:self didReloadSections:[NSIndexSet indexSetWithIndex:0]];
                                                                } else {
                                                                    NSMutableArray *indexPaths = [NSMutableArray array];
                                                                    NSIndexPath *section = [NSIndexPath indexPathWithIndex:0];
                                                                    for (NSUInteger i = offset; i < offset + [items count]; i++) {
                                                                        [indexPaths addObject:[section indexPathByAddingIndex:i]];
                                                                    }
                                                                    [observer dataSource:self didInsertItemsAtIndexPaths:indexPaths];
                                                                }
                                                                
                                                                [observer dataSourceDidChange:self];
                                                            }];
                                                        }
                                                        
                                                        for (void(^completion)(BOOL success, NSError *error) in self.completionHandler) {
                                                            completion(items != nil, error);
                                                        }
                                                        [self.completionHandler removeAllObjects];
                                                        self.loadingOperation = nil;
                                                    }];
        }
    }
}

@end
