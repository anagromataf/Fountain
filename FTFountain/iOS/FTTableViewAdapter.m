//
//  FTTableViewAdapter.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 10.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTableViewAdapter.h"
#import "FTDataSource.h"
#import "FTDataSourceObserver.h"
#import "FTMutableDataSource.h"
#import "FTPagingDataSource.h"
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

@interface FTTableViewAdapter () <FTDataSourceObserver, FTMutableDataSourceObserver, UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;
    id<FTDataSource> _dataSource;

    NSMutableArray *_cellPrepareHandler;
    NSMutableArray *_headerPrepareHandler;
    NSMutableArray *_footerPrepareHandler;

    BOOL _isLoadingMoreItemsBeforeFirstItem;
    BOOL _isLoadingMoreItemsAfterLastItem;

    NSInteger _isInUserDrivenChangeCallCount;

    NSMutableArray *_indexPathsOfMovedItemsToReload;
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

        _indexPathsOfMovedItemsToReload = [[NSMutableArray alloc] init];
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

#pragma mark Editing

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (_editing != editing) {

        _editing = editing;

        [self.tableView setEditing:editing animated:animated];

        if ([self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {

            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;

            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];

            NSUInteger numberOfSections = [self.dataSource numberOfSections];
            for (NSUInteger section = 0; section < numberOfSections; section++) {
                NSUInteger numberOfTemplateItems = [mutableDataSource numberOfFutureItemTypesInSection:section];

                if (numberOfTemplateItems > 0) {
                    NSUInteger firstTemplateIndex = [self.dataSource numberOfItemsInSection:section];
                    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstTemplateIndex, numberOfTemplateItems)];

                    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
                    }];
                }
            }

            if ([indexPaths count] > 0) {
                UITableViewRowAnimation animation = animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone;

                if (editing) {
                    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
                } else {
                    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
                }
            }
        }
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
    id item = nil;

    NSUInteger numberOfItemsInSection = [self.dataSource numberOfItemsInSection:indexPath.section];
    if (indexPath.item < numberOfItemsInSection) {
        item = [_dataSource itemAtIndexPath:indexPath];
    } else if (self.editing && [self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
        id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;

        NSIndexPath *futureItemIndexPath = [NSIndexPath indexPathForItem:indexPath.item - numberOfItemsInSection
                                                               inSection:indexPath.section];
        item = [mutableDataSource futureItemTypeAtIndexPath:futureItemIndexPath];
    }

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
        NSUInteger numberOfItemsInSection = [self.dataSource numberOfItemsInSection:section];
        if (self.editing && [self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;
            numberOfItemsInSection += [mutableDataSource numberOfFutureItemTypesInSection:section];
        }
        return numberOfItemsInSection;
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numberOfItemsInSection = [self.dataSource numberOfItemsInSection:indexPath.section];
    if (indexPath.item < numberOfItemsInSection) {
        if ([self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;
            return [mutableDataSource canEditItemAtIndexPath:indexPath];
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numberOfItemsInSection = [self.dataSource numberOfItemsInSection:indexPath.section];
    if (indexPath.item < numberOfItemsInSection) {
        if ([self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;
            BOOL canDelete = [mutableDataSource canDeleteItemAtIndexPath:indexPath];
            return canDelete ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
        } else {
            return UITableViewCellEditingStyleNone;
        }
    } else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numberOfItemsInSection = [self.dataSource numberOfItemsInSection:indexPath.section];
    if (indexPath.item < numberOfItemsInSection) {
        if (editingStyle == UITableViewCellEditingStyleDelete &&
            [self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;
            [self performUserDrivenChange:^{
                [mutableDataSource deleteItemAtIndexPath:indexPath];
                [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
        }
    } else if (self.editing && [self.dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {

        if (editingStyle == UITableViewCellEditingStyleInsert) {
            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)self.dataSource;

            NSIndexPath *futureItemIndexPath = [NSIndexPath indexPathForItem:indexPath.item - numberOfItemsInSection
                                                                   inSection:indexPath.section];
            id futureItem = [mutableDataSource futureItemTypeAtIndexPath:futureItemIndexPath];
            NSDictionary *properties = nil;

            if (self.cellPropertiesBlock) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                properties = self.cellPropertiesBlock(cell, indexPath, self.dataSource);
            }

            [mutableDataSource insertItemWithProperties:properties basedOnType:futureItem atIndexPath:futureItemIndexPath];
        }
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
        [_tableView reloadData];
    }
}

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView beginUpdates];
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView endUpdates];
        if (self.shouldSkipReloadOfUpdatedItems == NO && self.reloadMovedItems == YES) {
            [_tableView beginUpdates];
            [_tableView reloadRowsAtIndexPaths:_indexPathsOfMovedItemsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
            [_tableView endUpdates];
        }
        [_indexPathsOfMovedItemsToReload removeAllObjects];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView insertSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView deleteSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView reloadSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView moveSection:section toSection:newSection];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource && !_shouldSkipReloadOfUpdatedItems) {
        [_tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];

        if (self.shouldSkipReloadOfUpdatedItems == NO && self.reloadMovedItems == YES) {
            [_indexPathsOfMovedItemsToReload addObject:newIndexPath];
        }
    }
}

#pragma mark FTMutableDataSourceObserver

- (void)dataSource:(id<FTMutableDataSource>)dataSource didChangeFutureItemTypesInSections:(NSIndexSet *)sections
{
    if (_isInUserDrivenChangeCallCount == 0 && dataSource == _dataSource) {
        [_tableView reloadSections:sections withRowAnimation:self.rowAnimation];
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
