//
//  FTCollectionViewAdapter.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 13.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTCollectionViewAdapter.h"
#import "FTCollectionViewAdapter+Subclassing.h"

@interface FTCollectionViewAdapterPreperationHandler : NSObject
#pragma mark Life-cycle
- (instancetype)initWithPredicate:(NSPredicate *)predicate
                  reuseIdentifier:(NSString *)reuseIdentifier
                            block:(id)block;
#pragma mark Properties
@property (nonatomic, readonly) NSString *reuseIdentifier;
@property (nonatomic, readonly) NSPredicate *predicate;
@property (nonatomic, readonly) id block;
@property (nonatomic, strong) id prototype;
@end

#pragma mark -

@interface FTCollectionViewAdapter () <FTDataSourceObserver, UICollectionViewDelegate, UICollectionViewDataSource> {
    UICollectionView *_collectionView;
    id<FTDataSource> _dataSource;

    NSMutableArray *_cellPrepareHandler;
    NSMutableDictionary *_supplementaryElementPrepareHandler;

    NSMutableIndexSet *_insertedSections;
    NSMutableIndexSet *_deletedSections;
    NSMutableIndexSet *_reloadedSections;
    NSMutableArray *_movedSections;
    NSMutableArray *_insertedItems;
    NSMutableArray *_deletedItems;
    NSMutableArray *_reloadedItems;
    NSMutableArray *_movedItems;

    BOOL _isLoadingMoreItemsBeforeFirstItem;
    BOOL _isLoadingMoreItemsAfterLastItem;

    NSInteger _isInUserDrivenChangeCallCount;
}

@end

@implementation FTCollectionViewAdapter

#pragma mark Life-cycle

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
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
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

#pragma mark Data Source

- (id<FTDataSource>)dataSource
{
    return _dataSource;
}

- (void)setDataSource:(id<FTDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        [_dataSource removeObserver:self];
        _dataSource = dataSource;
        [_dataSource addObserver:self];
        [_collectionView reloadData];
    }
}

#pragma mark User-driven Change

- (void)performUserDrivenChange:(void (^)())block
{
    if (block) {
        _isInUserDrivenChangeCallCount++;
        block();
        _isInUserDrivenChangeCallCount--;
    }
}

#pragma mark Prepare Handler

- (void)forItemsMatchingPredicate:(NSPredicate *)predicate
       useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                     prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock
{
    predicate = predicate ?: [NSPredicate predicateWithValue:YES];

    FTCollectionViewAdapterPreperationHandler *handler = [[FTCollectionViewAdapterPreperationHandler alloc] initWithPredicate:predicate
                                                                                                              reuseIdentifier:reuseIdentifier
                                                                                                                        block:prepareBlock];
    [_cellPrepareHandler addObject:handler];
}

- (void)forSupplementaryViewsOfKind:(NSString *)kind
                  matchingPredicate:(NSPredicate *)predicate
         useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                       prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock
{
    predicate = predicate ?: [NSPredicate predicateWithValue:YES];

    FTCollectionViewAdapterPreperationHandler *handler = [[FTCollectionViewAdapterPreperationHandler alloc] initWithPredicate:predicate
                                                                                                              reuseIdentifier:reuseIdentifier
                                                                                                                        block:prepareBlock];

    NSMutableArray *handlers = [_supplementaryElementPrepareHandler objectForKey:kind];
    if (handlers == nil) {
        handlers = [[NSMutableArray alloc] init];
        [_supplementaryElementPrepareHandler setObject:handlers forKey:kind];
    }

    [handlers addObject:handler];
}

#pragma mark Preperation

- (void)itemPreperationForItemAtIndexPath:(NSIndexPath *)indexPath
                                withBlock:(void (^)(NSString *, FTCollectionViewAdapterCellPrepareBlock, id))block
{
    id item = [_dataSource itemAtIndexPath:indexPath];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                             @"ITEM" : @(indexPath.item),
                                             @"ROW" : @(indexPath.row) };

    [_cellPrepareHandler enumerateObjectsUsingBlock:^(FTCollectionViewAdapterPreperationHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

- (void)preperationForSupplementaryViewOfKind:(NSString *)kind
                                  atIndexPath:(NSIndexPath *)indexPath
                                    withBlock:(void (^)(NSString *reuseIdentifier,
                                                        FTCollectionViewAdapterCellPrepareBlock prepareBlock,
                                                        id item))block
{
    NSMutableArray *handlers = [_supplementaryElementPrepareHandler objectForKey:kind];

    if (handlers) {

        NSDictionary *substitutionVariables = @{};
        id item = [NSNull null];

        if ([indexPath length] == 1) {
            item = [self.dataSource sectionItemForSection:indexPath.section];
            substitutionVariables = @{ @"SECTION" : @(indexPath.section) };
        } else if ([indexPath length] == 2) {
            item = [self.dataSource itemAtIndexPath:indexPath];
            substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                       @"ITEM" : @(indexPath.item),
                                       @"ROW" : @(indexPath.row) };
        }

        [handlers enumerateObjectsUsingBlock:^(FTCollectionViewAdapterPreperationHandler *handler, NSUInteger idx, BOOL *stop) {
            if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
                if (block) {
                    block(handler.reuseIdentifier, handler.block, item);
                }
                *stop = YES;
            }
        }];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView == _collectionView) {
        return [self.dataSource numberOfSections];
    } else {
        return 0;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == _collectionView) {
        return [self.dataSource numberOfItemsInSection:section];
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _collectionView) {
        __block UICollectionViewCell *cell = nil;
        [self itemPreperationForItemAtIndexPath:indexPath
                                      withBlock:^(NSString *reuseIdentifier, FTCollectionViewAdapterCellPrepareBlock prepareBlock, id item) {
                                          cell = [_collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                                                            forIndexPath:indexPath];
                                          if (prepareBlock) {
                                              prepareBlock(cell, item, indexPath, _dataSource);
                                          }
                                      }];

        return cell;
    } else {
        return nil;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _collectionView) {
        __block UICollectionReusableView *view = nil;

        [self preperationForSupplementaryViewOfKind:kind
                                        atIndexPath:indexPath
                                          withBlock:^(NSString *reuseIdentifier, FTCollectionViewAdapterCellPrepareBlock prepareBlock, id item) {
                                              view = [_collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                         withReuseIdentifier:reuseIdentifier
                                                                                                forIndexPath:indexPath];
                                              if (prepareBlock) {
                                                  prepareBlock(view, item, indexPath, _dataSource);
                                              }
                                          }];
        return view;
    } else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _collectionView) {

        if ([self.delegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
            [self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
        }

        if ([_dataSource conformsToProtocol:@protocol(FTPagingDataSource)]) {
            id<FTPagingDataSource> pagingDataSource = (id<FTPagingDataSource>)_dataSource;

            if (indexPath.section == 0 && indexPath.row == 0) {

                if (_isLoadingMoreItemsBeforeFirstItem == NO && [pagingDataSource hasItemsBeforeFirstItem]) {
                    _isLoadingMoreItemsBeforeFirstItem = YES;

                    [pagingDataSource loadMoreItemsBeforeFirstItemCompletionHandler:^(BOOL success, NSError *error) {
                        _isLoadingMoreItemsBeforeFirstItem = NO;
                    }];
                }

            } else if (indexPath.section == [self.dataSource numberOfSections] - 1 &&
                       indexPath.row == [self.dataSource numberOfItemsInSection:indexPath.section] - 1) {

                if (_isLoadingMoreItemsAfterLastItem == NO && [pagingDataSource hasItemsAfterLastItem]) {
                    _isLoadingMoreItemsAfterLastItem = YES;

                    [pagingDataSource loadMoreItemsAfterLastItemCompletionHandler:^(BOOL success, NSError *error) {
                        _isLoadingMoreItemsAfterLastItem = NO;
                    }];
                }
            }
        }
    }
}

#pragma mark Delegate Forwarding

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;

        _collectionView.delegate = nil;
        _collectionView.delegate = self;
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

#pragma mark FTDataSourceObserver

- (void)dataSourceDidReset:(id<FTDataSource>)dataSource
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_collectionView reloadData];
    }
}

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_insertedSections removeAllIndexes];
        [_deletedSections removeAllIndexes];
        [_reloadedSections removeAllIndexes];
        [_movedSections removeAllObjects];
        [_insertedItems removeAllObjects];
        [_deletedItems removeAllObjects];
        [_movedItems removeAllObjects];
        [_reloadedItems removeAllObjects];
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {

        [_collectionView performBatchUpdates:^{
            [_collectionView deleteSections:_deletedSections];
            [_collectionView insertSections:_insertedSections];
            [_collectionView reloadSections:_reloadedSections];

            [_movedSections enumerateObjectsUsingBlock:^(NSArray *indexes, NSUInteger idx, BOOL *stop) {
                [_collectionView moveSection:[[indexes firstObject] integerValue]
                                   toSection:[[indexes lastObject] integerValue]];
            }];

            [_collectionView insertItemsAtIndexPaths:_insertedItems];
            [_collectionView deleteItemsAtIndexPaths:_deletedItems];
            [_collectionView reloadItemsAtIndexPaths:_reloadedItems];

            [_movedItems enumerateObjectsUsingBlock:^(NSArray *indexPaths, NSUInteger idx, BOOL *stop) {
                [_collectionView moveItemAtIndexPath:[indexPaths firstObject]
                                         toIndexPath:[indexPaths lastObject]];
            }];

        } completion:^(BOOL finished){

        }];

        [_insertedSections removeAllIndexes];
        [_deletedSections removeAllIndexes];
        [_reloadedSections removeAllIndexes];
        [_movedSections removeAllObjects];
        [_insertedItems removeAllObjects];
        [_deletedItems removeAllObjects];
        [_movedItems removeAllObjects];
        [_reloadedItems removeAllObjects];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_insertedSections addIndexes:sections];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_deletedSections addIndexes:sections];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_reloadedSections addIndexes:sections];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_movedSections addObject:@[ @(section), @(newSection) ]];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_insertedItems addObjectsFromArray:indexPaths];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_deletedItems addObjectsFromArray:indexPaths];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_reloadedItems addObjectsFromArray:indexPaths];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_movedItems addObject:@[ indexPath, newIndexPath ]];
    }
}

@end

#pragma mark -

@implementation FTCollectionViewAdapterPreperationHandler

#pragma mark Life-cycle

- (instancetype)initWithPredicate:(NSPredicate *)predicate
                  reuseIdentifier:(NSString *)reuseIdentifier
                            block:(id)block
{
    self = [super init];
    if (self) {
        _predicate = predicate;
        _reuseIdentifier = reuseIdentifier;
        _block = block;
    }
    return self;
}

@end