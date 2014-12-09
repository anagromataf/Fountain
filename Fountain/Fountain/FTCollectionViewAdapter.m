//
//  FTCollectionViewAdapter.m
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTAdapterPrepareHandler.h"

#import "FTCollectionViewAdapter.h"

@interface FTCollectionViewAdapter () <FTDataSourceObserver, UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, readonly) NSMutableArray *cellPrepareHandler;
@property (nonatomic, readonly) NSMutableDictionary *supplementaryElementPrepareHandler;
@end

@implementation FTCollectionViewAdapter

#pragma mark Life-cycle

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;
{
    self = [super init];
    if (self) {
        _collectionView = collectionView;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        _cellPrepareHandler = [[NSMutableArray alloc] init];
        _supplementaryElementPrepareHandler = [[NSMutableDictionary alloc] init];
        
        [_collectionView reloadData];
    }
    return self;
}

- (void)dealloc
{
    self.collectionView.dataSource = nil;
    self.collectionView.delegate = nil;
}

#pragma mark Data Source

- (void)setDataSource:(id<FTDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        [_dataSource removeObserver:self];
        _dataSource = dataSource;
        [_dataSource addObserver:self];
        [self.collectionView reloadData];
    }
}

#pragma mark Prepare Handler

- (void)forItemsMatchingPredicate:(NSPredicate *)predicate
       useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                     prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock
{
    FTAdapterPrepareHandler *handler = [[FTAdapterPrepareHandler alloc] initWithPredicate:predicate
                                                                          reuseIdentifier:reuseIdentifier
                                                                                    block:prepareBlock];
    [self.cellPrepareHandler addObject:handler];
}

- (void)forSupplementaryViewsOfKind:(NSString *)kind
                  matchingPredicate:(NSPredicate *)predicate
         useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                       prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock
{
    NSMutableArray *handlers = [self.supplementaryElementPrepareHandler objectForKey:kind];
    if (handlers == nil) {
        handlers = [[NSMutableArray alloc] init];
        [self.supplementaryElementPrepareHandler setObject:handlers forKey:kind];
    }
    
    FTAdapterPrepareHandler *handler = [[FTAdapterPrepareHandler alloc] initWithPredicate:predicate
                                                                          reuseIdentifier:reuseIdentifier
                                                                                    block:prepareBlock];
    [handlers addObject:handler];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView == self.collectionView) {
        return [self.dataSource numberOfSections];
    }
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.collectionView) {
        return [self.dataSource numberOfItemsInSection:section];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView) {
        
        id item = [self.dataSource itemAtIndexPath:indexPath];
        __block FTAdapterPrepareHandler *handler = nil;
        
        NSDictionary *substitutionVariables = @{@"SECTION": @(indexPath.section),
                                                @"ITEM":    @(indexPath.item),
                                                @"ROW":     @(indexPath.row)};
        
        [self.cellPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
            handler = h;
            if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
                *stop = YES;
            }
        }];
        
        if (handler) {
            UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:handler.reuseIdentifier
                                                                                        forIndexPath:indexPath];
            FTCollectionViewAdapterCellPrepareBlock prepareBlock = handler.block;
            if (prepareBlock) {
                prepareBlock(cell, item, indexPath, self.dataSource);
            }
        }
    }
    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *handlers = [self.supplementaryElementPrepareHandler objectForKey:kind];
    if (handlers) {
        
        NSDictionary *substitutionVariables = @{};
        id item = [NSNull null];
        
        if ([indexPath length] == 1) {
            item = [self.dataSource itemForSection:indexPath.section];
            substitutionVariables = @{@"SECTION": @(indexPath.section)};
        } else if ([indexPath length] == 2) {
            item = [self.dataSource itemAtIndexPath:indexPath];
            substitutionVariables = @{@"SECTION": @(indexPath.section),
                                      @"ITEM":    @(indexPath.item),
                                      @"ROW":     @(indexPath.row)};
        }
        
        __block FTAdapterPrepareHandler *handler = nil;
        
        [handlers enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
            handler = h;
            if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
                *stop = YES;
            }
        }];
        
        if (handler) {
            UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:handler.reuseIdentifier
                                                                                        forIndexPath:indexPath];
            FTCollectionViewAdapterCellPrepareBlock prepareBlock = handler.block;
            if (prepareBlock) {
                prepareBlock(cell, item, indexPath, self.dataSource);
            }
        }
        
    }
    return nil;
}

#pragma mark Delegate Forwarding

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        
        self.collectionView.delegate = nil;
        self.collectionView.delegate = self;
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector]) {
        return YES;
    } else {
        BOOL respondsToSelector = [self.delegate respondsToSelector:aSelector];
        return respondsToSelector;
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.delegate;
}

#pragma mark UICollectionViewDelegate

#pragma mark - FTDataSourceObserver

#pragma mark Reload
- (void)reload { [self.collectionView reloadData]; }

#pragma mark Perform Batch Update
- (void)performBatchUpdate:(void (^)(void))update { [self.collectionView performBatchUpdates:update completion:nil]; }

#pragma mark Manage Sections
- (void)insertSections:(NSIndexSet *)sections { [self.collectionView insertSections:sections]; }
- (void)deleteSections:(NSIndexSet *)sections { [self.collectionView deleteSections:sections]; }
- (void)reloadSections:(NSIndexSet *)sections { [self.collectionView reloadSections:sections]; }
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection { [self.collectionView moveSection:section toSection:newSection]; }

#pragma mark Manage Items
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths { [self.collectionView insertItemsAtIndexPaths:indexPaths]; }
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths { [self.collectionView deleteItemsAtIndexPaths:indexPaths]; }
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths { [self.collectionView reloadItemsAtIndexPaths:indexPaths]; }
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath { [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath]; }

@end
