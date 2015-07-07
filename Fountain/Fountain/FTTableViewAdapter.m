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
        _estimatedRowHeight = UITableViewAutomaticDimension;
        _rowHeight = UITableViewAutomaticDimension;
        _sectionHeaderHeight = UITableViewAutomaticDimension;
        _sectionFooterHeight = UITableViewAutomaticDimension;
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

- (void)forRowsKindOfClass:(Class)aClass
useCellWithReuseIdentifier:(NSString *)reuseIdentifier
              prepareBlock:(FTTableViewAdapterCellPrepareBlock)prepareBlock
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:aClass];
    }];

    [self forRowsMatchingPredicate:predicate useCellWithReuseIdentifier:reuseIdentifier prepareBlock:prepareBlock];
}

- (void)forRowsConformingToProtocol:(Protocol *)aProtocol
         useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                       prepareBlock:(FTTableViewAdapterCellPrepareBlock)prepareBlock
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject conformsToProtocol:aProtocol];
    }];

    [self forRowsMatchingPredicate:predicate useCellWithReuseIdentifier:reuseIdentifier prepareBlock:prepareBlock];
}

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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {

        if (self.estimatedRowHeight != UITableViewAutomaticDimension) {

            return self.estimatedRowHeight;

        } else {

            id item = [self.dataSource itemAtIndexPath:indexPath];
            __block FTAdapterPrepareHandler *handler = nil;

            NSDictionary *substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                                     @"ITEM" : @(indexPath.item),
                                                     @"ROW" : @(indexPath.row) };

            [self.cellPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
                handler = h;
                if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
                    *stop = YES;
                }
            }];

            if (handler) {

                if (handler.prototype == nil) {
                    handler.prototype = [tableView dequeueReusableCellWithIdentifier:handler.reuseIdentifier];
                }

                FTTableViewAdapterCellPrepareBlock prepareBlock = handler.block;
                if (prepareBlock) {
                    prepareBlock(handler.prototype, item, indexPath, self.dataSource);
                }

                CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);

                CGSize size = [handler.prototype systemLayoutSizeFittingSize:targetSize];

                return size.height;
            } else {
                return UITableViewAutomaticDimension;
            }
        }

    } else {
        return tableView.estimatedRowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {

        if (self.rowHeight != UITableViewAutomaticDimension) {

            return self.rowHeight;

        } else {

            id item = [self.dataSource itemAtIndexPath:indexPath];
            __block FTAdapterPrepareHandler *handler = nil;

            NSDictionary *substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                                     @"ITEM" : @(indexPath.item),
                                                     @"ROW" : @(indexPath.row) };

            [self.cellPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
                handler = h;
                if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
                    *stop = YES;
                }
            }];

            if (handler) {

                if (handler.prototype == nil) {
                    handler.prototype = [tableView dequeueReusableCellWithIdentifier:handler.reuseIdentifier];
                }

                FTTableViewAdapterCellPrepareBlock prepareBlock = handler.block;
                if (prepareBlock) {
                    prepareBlock(handler.prototype, item, indexPath, self.dataSource);
                }

                CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);

                CGSize size = [handler.prototype systemLayoutSizeFittingSize:targetSize];

                return size.height;
            } else {
                return UITableViewAutomaticDimension;
            }
        }

    } else {
        return tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {

        if (self.sectionHeaderHeight != UITableViewAutomaticDimension) {

            return self.sectionHeaderHeight;

        } else {

            id item = [self.dataSource itemForSection:section];
            __block FTAdapterPrepareHandler *handler = nil;

            NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                                     @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

            [self.headerPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
                if ([h.predicate evaluateWithObject:item ? item : [NSNull null]
                              substitutionVariables:substitutionVariables]) {
                    *stop = YES;
                    handler = h;
                }
            }];

            if (handler) {
                if (handler.prototype == nil) {
                    handler.prototype = [tableView dequeueReusableHeaderFooterViewWithIdentifier:handler.reuseIdentifier];
                }

                FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock = handler.block;
                if (prepareBlock) {
                    prepareBlock(handler.prototype, item, section, self.dataSource);
                }

                CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);

                CGSize size = [handler.prototype systemLayoutSizeFittingSize:targetSize];

                return size.height;

            } else {
                return 0;
            }
        }
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (tableView == self.tableView) {

        if (self.sectionFooterHeight != UITableViewAutomaticDimension) {

            return self.sectionFooterHeight;

        } else {

            id item = [self.dataSource itemForSection:section];
            __block FTAdapterPrepareHandler *handler = nil;

            NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                                     @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

            [self.footerPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
                if ([h.predicate evaluateWithObject:item ? item : [NSNull null]
                              substitutionVariables:substitutionVariables]) {
                    *stop = YES;
                    handler = h;
                }
            }];

            if (handler) {
                if (handler.prototype == nil) {
                    handler.prototype = [tableView dequeueReusableHeaderFooterViewWithIdentifier:handler.reuseIdentifier];
                }

                FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock = handler.block;
                if (prepareBlock) {
                    prepareBlock(handler.prototype, item, section, self.dataSource);
                }

                CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);

                CGSize size = [handler.prototype systemLayoutSizeFittingSize:targetSize];

                return size.height;

            } else {
                return 0;
            }
        }
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {

        id item = [self.dataSource itemForSection:section];
        __block FTAdapterPrepareHandler *handler = nil;

        NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                                 @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

        [self.headerPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
            if ([h.predicate evaluateWithObject:item ? item : [NSNull null]
                          substitutionVariables:substitutionVariables]) {
                *stop = YES;
                handler = h;
            }
        }];

        if (handler) {

            UIView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:handler.reuseIdentifier];

            FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock = handler.block;
            if (prepareBlock) {
                prepareBlock(view, item, section, self.dataSource);
            }

            return view;

        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (tableView == self.tableView) {

        id item = [self.dataSource itemForSection:section];
        __block FTAdapterPrepareHandler *handler = nil;

        NSDictionary *substitutionVariables = @{ @"SECTION" : @(section),
                                                 @"ITEMS_COUNT" : @([self.dataSource numberOfItemsInSection:section]) };

        [self.footerPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
            if ([h.predicate evaluateWithObject:item ? item : [NSNull null]
                          substitutionVariables:substitutionVariables]) {
                *stop = YES;
                handler = h;
            }
        }];

        if (handler) {

            UIView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:handler.reuseIdentifier];

            FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock = handler.block;
            if (prepareBlock) {
                prepareBlock(view, item, section, self.dataSource);
            }

            return view;

        } else {
            return nil;
        }
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

        id item = [self.dataSource itemAtIndexPath:indexPath];
        __block FTAdapterPrepareHandler *handler = nil;

        NSDictionary *substitutionVariables = @{ @"SECTION" : @(indexPath.section),
                                                 @"ITEM" : @(indexPath.item),
                                                 @"ROW" : @(indexPath.row) };

        [self.cellPrepareHandler enumerateObjectsUsingBlock:^(FTAdapterPrepareHandler *h, NSUInteger idx, BOOL *stop) {
            handler = h;
            if ([handler.predicate evaluateWithObject:item substitutionVariables:substitutionVariables]) {
                *stop = YES;
            }
        }];

        if (handler) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:handler.reuseIdentifier
                                                                         forIndexPath:indexPath];
            FTTableViewAdapterCellPrepareBlock prepareBlock = handler.block;
            if (prepareBlock) {
                prepareBlock(cell, item, indexPath, self.dataSource);
            }

            return cell;
        } else {
            return nil;
        }

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
