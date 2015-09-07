//
//  FTTableViewAdapter.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 10.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTableViewAdapter.h"
#import "FTTableViewAdapter+Subclassing.h"

@interface FTTableViewAdapterPreperationHandler : NSObject
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

@interface FTTableViewAdapter () <FTDataSourceObserver, UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;
    id<FTDataSource> _dataSource;

    NSMutableArray *_cellPrepareHandler;
    NSMutableArray *_headerPrepareHandler;
    NSMutableArray *_footerPrepareHandler;

    BOOL _isLoadingMoreItemsBeforeFirstItem;
    BOOL _isLoadingMoreItemsAfterLastItem;
}

@end

@implementation FTTableViewAdapter

#pragma mark Life-cycle

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        _tableView = tableView;
        _tableView.dataSource = self;
        _tableView.delegate = self;

        _cellPrepareHandler = [[NSMutableArray alloc] init];
        _headerPrepareHandler = [[NSMutableArray alloc] init];
        _footerPrepareHandler = [[NSMutableArray alloc] init];

        _rowAnimation = UITableViewRowAnimationAutomatic;
    }
    return self;
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
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
        [_tableView reloadData];
    }
}

#pragma mark Prepare Handler

- (void)forRowsMatchingPredicate:(NSPredicate *)predicate
      useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                    prepareBlock:(FTTableViewAdapterCellPrepareBlock)prepareBlock
{
    predicate = predicate ?: [NSPredicate predicateWithValue:YES];

    FTTableViewAdapterPreperationHandler *handler = [[FTTableViewAdapterPreperationHandler alloc] initWithPredicate:predicate
                                                                                                    reuseIdentifier:reuseIdentifier
                                                                                                              block:prepareBlock];
    [_cellPrepareHandler addObject:handler];
}

- (void)forHeaderMatchingPredicate:(NSPredicate *)predicate
        useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                      prepareBlock:(FTTableViewAdapterHeaderFooterPrepareBlock)prepareBlock
{
    predicate = predicate ?: [NSPredicate predicateWithValue:YES];

    FTTableViewAdapterPreperationHandler *handler = [[FTTableViewAdapterPreperationHandler alloc] initWithPredicate:predicate
                                                                                                    reuseIdentifier:reuseIdentifier
                                                                                                              block:prepareBlock];
    [_headerPrepareHandler addObject:handler];
}

- (void)forFooterMatchingPredicate:(NSPredicate *)predicate
        useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                      prepareBlock:(FTTableViewAdapterHeaderFooterPrepareBlock)prepareBlock
{
    predicate = predicate ?: [NSPredicate predicateWithValue:YES];

    FTTableViewAdapterPreperationHandler *handler = [[FTTableViewAdapterPreperationHandler alloc] initWithPredicate:predicate
                                                                                                    reuseIdentifier:reuseIdentifier
                                                                                                              block:prepareBlock];
    [_footerPrepareHandler addObject:handler];
}

#pragma mark Preperation

- (void)rowPreperationForItemAtIndexPath:(NSIndexPath *)indexPath
                               withBlock:(void (^)(NSString *reuseIdentifier,
                                                   FTTableViewAdapterCellPrepareBlock prepareBlock,
                                                   id item))block
{
    id item = [_dataSource itemAtIndexPath:indexPath];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                             @"ITEM" : @(indexPath.item),
                                             @"ROW" : @(indexPath.row) };

    [_cellPrepareHandler enumerateObjectsUsingBlock:^(FTTableViewAdapterPreperationHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

- (void)headerPreperationForSection:(NSUInteger)section
                          withBlock:(void (^)(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item))block
{
    id item = [self.dataSource sectionItemForSection:section];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                             @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

    [_headerPrepareHandler enumerateObjectsUsingBlock:^(FTTableViewAdapterPreperationHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item ? item : [NSNull null] substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

- (void)footerPreperationForSection:(NSUInteger)section
                          withBlock:(void (^)(NSString *reuseIdentifier,
                                              FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock,
                                              id item))block
{
    id item = [self.dataSource sectionItemForSection:section];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                             @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

    [_footerPrepareHandler enumerateObjectsUsingBlock:^(FTTableViewAdapterPreperationHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item ? item : [NSNull null] substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == _tableView) {
        return [self.dataSource numberOfSections];
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _tableView) {
        return [self.dataSource numberOfItemsInSection:section];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _tableView) {
        __block UITableViewCell *cell = nil;
        [self rowPreperationForItemAtIndexPath:indexPath
                                     withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterCellPrepareBlock prepareBlock, id item) {

                                         cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                                                 forIndexPath:indexPath];
                                         if (prepareBlock) {
                                             prepareBlock(cell, item, indexPath, self.dataSource);
                                         }

                                     }];
        return cell;
    } else {
        return nil;
    }
}

#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {

        __block UIView *view = nil;

        [self headerPreperationForSection:section
                                withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item) {
                                    view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
                                    if (prepareBlock) {
                                        prepareBlock(view, item, section, self.dataSource);
                                    }
                                }];

        return view;
    } else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (tableView == self.tableView) {

        __block UIView *view = nil;

        [self footerPreperationForSection:section
                                withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item) {
                                    view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
                                    if (prepareBlock) {
                                        prepareBlock(view, item, section, self.dataSource);
                                    }
                                }];

        return view;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _tableView) {

        if ([self.delegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
            [self.delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
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

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;

        _tableView.delegate = nil;
        _tableView.delegate = self;
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(tableView:willDisplayCell:forRowAtIndexPath:)) {
        
    }
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
    if (dataSource == _dataSource) {
        [_tableView reloadData];
    }
}

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (dataSource == _dataSource) {
        [_tableView beginUpdates];
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    if (dataSource == _dataSource) {
        [_tableView endUpdates];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    if (dataSource == _dataSource) {
        [_tableView insertSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    if (dataSource == _dataSource) {
        [_tableView deleteSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeSections:(NSIndexSet *)sections
{
    if (dataSource == _dataSource) {
        [_tableView reloadSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (dataSource == _dataSource) {
        [_tableView moveSection:section toSection:newSection];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == _dataSource) {
        [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == _dataSource) {
        [_tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == _dataSource) {
        [_tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    if (dataSource == _dataSource) {
        [_tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

@end

#pragma mark -

@implementation FTTableViewAdapterPreperationHandler

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
