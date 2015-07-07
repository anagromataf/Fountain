//
//  FTTableViewAdapter.m
//  Fountain
//
//  Created by Tobias Kraentzer on 06.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTAdapterPrepareHandler.h"

#import "FTTableViewAdapter.h"

@interface FTTableViewAdapter () <FTDataSourceObserver, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly) NSMutableArray *cellPrepareHandler;
@property (nonatomic, readonly) NSMutableArray *headerPrepareHandler;
@property (nonatomic, readonly) NSMutableArray *footerPrepareHandler;
@property (nonatomic, assign) NSInteger userDrivenChangeCount;
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
        _rowAnimation = UITableViewRowAnimationAutomatic;
        _cellPrepareHandler = [[NSMutableArray alloc] init];
        _headerPrepareHandler = [[NSMutableArray alloc] init];
        _footerPrepareHandler = [[NSMutableArray alloc] init];
        _userDrivenChangeCount = 0;
    }
    return self;
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

#pragma mark Data Source

- (void)setDataSource:(id<FTDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        [_dataSource removeObserver:self];
        _dataSource = dataSource;
        [_dataSource addObserver:self];
        [self.tableView reloadData];
    }
}

#pragma mark Prepare Handler

- (void)forRowsMatchingPredicate:(NSPredicate *)predicate
      useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                    prepareBlock:(FTTableViewAdapterCellPrepareBlock)prepareBlock
{
    FTAdapterPrepareHandler *handler = [[FTAdapterPrepareHandler alloc] initWithPredicate:predicate ?: [NSPredicate predicateWithValue:YES]
                                                                          reuseIdentifier:reuseIdentifier
                                                                                    block:prepareBlock];
    [self.cellPrepareHandler addObject:handler];
}

- (void)forHeaderMatchingPredicate:(NSPredicate *)predicate
        useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                      prepareBlock:(FTTableViewAdapterHeaderFooterPrepareBlock)prepareBlock
{
    FTAdapterPrepareHandler *handler = [[FTAdapterPrepareHandler alloc] initWithPredicate:predicate ?: [NSPredicate predicateWithValue:YES]
                                                                          reuseIdentifier:reuseIdentifier
                                                                                    block:prepareBlock];
    [self.headerPrepareHandler addObject:handler];
}

- (void)forFooterMatchingPredicate:(NSPredicate *)predicate
        useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                      prepareBlock:(FTTableViewAdapterHeaderFooterPrepareBlock)prepareBlock
{
    FTAdapterPrepareHandler *handler = [[FTAdapterPrepareHandler alloc] initWithPredicate:predicate ?: [NSPredicate predicateWithValue:YES]
                                                                          reuseIdentifier:reuseIdentifier
                                                                                    block:prepareBlock];
    [self.footerPrepareHandler addObject:handler];
}

- (void)rowPreperationForItemAtIndexPath:(NSIndexPath *)indexPath withBlock:(void (^)(NSString *reuseIdentifier, FTTableViewAdapterCellPrepareBlock prepareBlock, id item))block
{
    id item = [self.dataSource itemAtIndexPath:indexPath];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                             @"ITEM" : @(indexPath.item),
                                             @"ROW" : @(indexPath.row) };

    [self.cellPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

- (void)headerPreperationForSection:(NSUInteger)section withBlock:(void (^)(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item))block
{
    id item = [self.dataSource itemForSection:section];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                             @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

    [self.headerPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item ? item : [NSNull null] substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

- (void)footerPreperationForSection:(NSUInteger)section withBlock:(void (^)(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item))block
{
    id item = [self.dataSource itemForSection:section];

    NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                             @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

    [self.footerPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *handler, NSUInteger idx, BOOL *stop) {
        if ([handler.predicate evaluateWithObject:item ? item : [NSNull null] substitutionVariables:substitutionVariables]) {
            if (block) {
                block(handler.reuseIdentifier, handler.block, item);
            }
            *stop = YES;
        }
    }];
}

#pragma mark User-driven Changes

- (BOOL)userDrivenChange
{
    return self.userDrivenChangeCount > 0;
}

- (void)beginUserDrivenChange
{
    self.userDrivenChangeCount += 1;
}

- (void)endUserDrivenChange
{
    self.userDrivenChangeCount -= 1;
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
    if (tableView == self.tableView) {
        if ([self.delegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
            [self.delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
        }

        if (self.shouldLoadNextPage == YES &&
            [self.dataSource respondsToSelector:@selector(loadNextPageCompletionHandler:)] &&
            indexPath.section == [self.dataSource numberOfSections] - 1 &&
            indexPath.row == [self.dataSource numberOfItemsInSection:indexPath.section] - 1) {

            id<FTPagingDataSource> dataSource = (id<FTPagingDataSource>)(self.dataSource);

            [dataSource loadNextPageCompletionHandler:^(BOOL success, NSError *error){

            }];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (tableView == self.tableView) {
        if ([self.dataSource conformsToProtocol:@protocol(FTReorderableDataSource)]) {
            return [(id<FTReorderableDataSource>)self.dataSource targetIndexPathForMoveFromItemAtIndexPath:sourceIndexPath
                                                                                       toProposedIndexPath:proposedDestinationIndexPath];
        } else {
            return proposedDestinationIndexPath;
        }
    } else {
        return proposedDestinationIndexPath;
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        return [self.dataSource numberOfSections];
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return [self.dataSource numberOfItemsInSection:section];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        __block UITableViewCell *cell = nil;
        [self rowPreperationForItemAtIndexPath:indexPath
                                     withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterCellPrepareBlock prepareBlock, id item) {

                                         UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier
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

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if ([self.dataSource conformsToProtocol:@protocol(FTReorderableDataSource)]) {
            return [(id<FTReorderableDataSource>)self.dataSource canMoveItemAtIndexPath:indexPath];
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (tableView == self.tableView) {
        if ([self.dataSource conformsToProtocol:@protocol(FTReorderableDataSource)]) {
            [(id<FTReorderableDataSource>)self.dataSource moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
        }
    }
}

#pragma mark Delegate Forwarding

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;

        self.tableView.delegate = nil;
        self.tableView.delegate = self;
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
        [self.tableView reloadData];
    }
}

#pragma mark Begin End Updates

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView beginUpdates];
    }
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView endUpdates];
    }
}

#pragma mark Manage Sections

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView insertSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView deleteSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadSections:(NSIndexSet *)sections
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView reloadSections:sections withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView moveSection:section toSection:newSection];
    }
}

#pragma mark Manage Items

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didReloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (dataSource == self.dataSource && self.reloadRowIfItemChanged && self.userDrivenChange == NO) {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    if (dataSource == self.dataSource && self.userDrivenChange == NO) {
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

@end
