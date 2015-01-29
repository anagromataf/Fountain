//
//  FTCollectionViewAdapter.m
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTAdapterPrepareHandler.h"

#import "FTCollectionViewAdapter.h"

@interface UICollectionReusableView ()
- (void)setPreferredMaxLayoutWidth:(CGFloat)width;
@end

@interface FTCollectionViewAdapter () <FTDataSourceObserver, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, readonly) NSMutableArray *cellPrepareHandler;
@property (nonatomic, readonly) NSMutableDictionary *supplementaryElementPrepareHandler;

#pragma mark Data Source Changes
@property (nonatomic, readonly) NSMutableIndexSet *insertedSections;
@property (nonatomic, readonly) NSMutableIndexSet *deletedSections;
@property (nonatomic, readonly) NSMutableIndexSet *reloadedSections;
@property (nonatomic, readonly) NSMutableArray *movedSections;
@property (nonatomic, readonly) NSMutableArray *insertedItems;
@property (nonatomic, readonly) NSMutableArray *deletedItems;
@property (nonatomic, readonly) NSMutableArray *reloadedItems;
@property (nonatomic, readonly) NSMutableArray *movedItems;
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
        
        _insertedSections = [[NSMutableIndexSet alloc] init];
        _deletedSections = [[NSMutableIndexSet alloc] init];
        _movedSections = [[NSMutableArray alloc] init];
        _reloadedSections = [[NSMutableIndexSet alloc] init];
        
        _insertedItems = [[NSMutableArray alloc] init];
        _deletedItems = [[NSMutableArray alloc] init];
        _movedItems = [[NSMutableArray alloc] init];
        _reloadedItems = [[NSMutableArray alloc] init];
        
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
            
            return cell;
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
            id view = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                              withReuseIdentifier:handler.reuseIdentifier
                                                                     forIndexPath:indexPath];
            FTCollectionViewAdapterSupplementaryViewPrepareBlock prepareBlock = handler.block;
            if (prepareBlock) {
                prepareBlock(view, item, indexPath, self.dataSource);
            }
            
            return view;
        }
    }
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView) {
        if ([self.delegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
            [self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
        }
        
        if (self.shouldLoadNextPage == YES &&
            [self.dataSource respondsToSelector:@selector(loadNextPageCompletionHandler:)] &&
            indexPath.section == [self.dataSource numberOfSections] - 1 &&
            indexPath.row == [self.dataSource numberOfItemsInSection:indexPath.section] - 1) {
            
            id<FTPagingDataSource> dataSource = (id<FTPagingDataSource>)(self.dataSource);
            
            [dataSource loadNextPageCompletionHandler:^(BOOL success, NSError *error) {
                
            }];
        }
    }
}

#pragma mark Delegate Forwarding

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        
        self.collectionView.delegate = nil;
        self.collectionView.delegate = self;
        self.collectionView.dataSource = nil;
        self.collectionView.dataSource = self;
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

#pragma mark - FTDataSourceObserver

#pragma mark Reload

- (void)dataSourceWillReload:(id<FTDataSource>)dataSource
{
}

- (void)dataSourceDidReload:(id<FTDataSource>)dataSource
{
    if (dataSource == self.dataSource) {
        [self.collectionView reloadData];
    }
}

#pragma mark Begin End Updates

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    [self.insertedSections removeAllIndexes];
    [self.deletedSections removeAllIndexes];
    [self.reloadedSections removeAllIndexes];
    [self.movedSections removeAllObjects];
    [self.insertedItems removeAllObjects];
    [self.deletedItems removeAllObjects];
    [self.movedItems removeAllObjects];
    [self.reloadedItems removeAllObjects];
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteSections:self.deletedSections];
        [self.collectionView insertSections:self.insertedSections];
        [self.collectionView reloadSections:self.reloadedSections];
        
        [self.movedSections enumerateObjectsUsingBlock:^(NSArray *indexes, NSUInteger idx, BOOL *stop) {
            [self.collectionView moveSection:[[indexes firstObject] integerValue]
                                   toSection:[[indexes lastObject] integerValue]];
        }];
        
        [self.collectionView insertItemsAtIndexPaths:self.insertedItems];
        [self.collectionView deleteItemsAtIndexPaths:self.deletedItems];
        [self.collectionView reloadItemsAtIndexPaths:self.reloadedItems];
        
        [self.movedItems enumerateObjectsUsingBlock:^(NSArray *indexPaths, NSUInteger idx, BOOL *stop) {
            [self.collectionView moveItemAtIndexPath:[indexPaths firstObject]
                                         toIndexPath:[indexPaths lastObject]];
        }];
        
    } completion:^(BOOL finished) {
        
    }];
    
    [self.insertedSections removeAllIndexes];
    [self.deletedSections removeAllIndexes];
    [self.reloadedSections removeAllIndexes];
    [self.movedSections removeAllObjects];
    [self.insertedItems removeAllObjects];
    [self.deletedItems removeAllObjects];
    [self.movedItems removeAllObjects];
    [self.reloadedItems removeAllObjects];
}

#pragma mark Manage Sections

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    if (dataSource == self.dataSource) {
        [self.insertedSections addIndexes:sections];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    if (dataSource == self.dataSource) {
        [self.deletedSections addIndexes:sections];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadSections:(NSIndexSet *)sections
{
    if (dataSource == self.dataSource) {
        [self.reloadedSections addIndexes:sections];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (dataSource == self.dataSource) {
        [self.movedSections addObject:@[@(section), @(newSection)]];
    }
}

#pragma mark Manage Items

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.dataSource) {
        [self.insertedItems addObjectsFromArray:indexPaths];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.dataSource) {
        [self.deletedItems addObjectsFromArray:indexPaths];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.dataSource) {
        [self.reloadedItems addObjectsFromArray:indexPaths];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    if (dataSource == self.dataSource) {
        [self.movedItems addObject:@[indexPath, newIndexPath]];
    }
}

@end
