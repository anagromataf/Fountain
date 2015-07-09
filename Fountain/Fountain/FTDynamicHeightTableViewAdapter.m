//
//  FTDynamicHeightTableViewAdapter.m
//  Fountain
//
//  Created by Tobias Kräntzer on 06.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTableViewAdapter+Subclassing.h"

#import "FTDynamicHeightTableViewAdapter.h"

@interface FTDynamicHeightTableViewAdapter ()
@property (nonatomic, readonly) NSMapTable *cellPrototypes;
@property (nonatomic, readonly) NSMapTable *headerPrototypes;
@property (nonatomic, readonly) NSMapTable *footerPrototypes;
@end

@implementation FTDynamicHeightTableViewAdapter

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super initWithTableView:tableView];
    if (self) {
        _estimatedRowHeight = UITableViewAutomaticDimension;
        _rowHeight = UITableViewAutomaticDimension;
        _sectionHeaderHeight = UITableViewAutomaticDimension;
        _sectionFooterHeight = UITableViewAutomaticDimension;
        _cellPrototypes = [NSMapTable weakToStrongObjectsMapTable];
        _headerPrototypes = [NSMapTable weakToStrongObjectsMapTable];
        _footerPrototypes = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {

        if (self.estimatedRowHeight != UITableViewAutomaticDimension) {

            return self.estimatedRowHeight;

        } else {

            __block CGFloat height = UITableViewAutomaticDimension;

            [self rowPreperationForItemAtIndexPath:indexPath
                                         withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterCellPrepareBlock prepareBlock, id item) {

                                             if (prepareBlock) {

                                                 UIView *prototype = [self.cellPrototypes objectForKey:prepareBlock];

                                                 if (prototype == nil) {
                                                     prototype = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
                                                     [self.cellPrototypes setObject:prototype forKey:prepareBlock];
                                                 }

                                                 prepareBlock(prototype, item, indexPath, self.dataSource);

                                                 CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);
                                                 CGSize size = [prototype systemLayoutSizeFittingSize:targetSize];
                                                 height = size.height;
                                             }

                                         }];

            return height;
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

            __block CGFloat height = UITableViewAutomaticDimension;

            [self rowPreperationForItemAtIndexPath:indexPath
                                         withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterCellPrepareBlock prepareBlock, id item) {

                                             if (prepareBlock) {

                                                 UIView *prototype = [self.cellPrototypes objectForKey:prepareBlock];

                                                 if (prototype == nil) {
                                                     prototype = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
                                                     [self.cellPrototypes setObject:prototype forKey:prepareBlock];
                                                 }

                                                 prepareBlock(prototype, item, indexPath, self.dataSource);

                                                 CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);
                                                 CGSize size = [prototype systemLayoutSizeFittingSize:targetSize];
                                                 height = size.height;
                                             }

                                         }];

            return height;
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

            __block CGFloat height = 0;

            [self headerPreperationForSection:section
                                    withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item) {
                                        if (prepareBlock) {

                                            UIView *prototype = [self.headerPrototypes objectForKey:prepareBlock];

                                            if (prototype == nil) {
                                                prototype = [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
                                                [self.headerPrototypes setObject:prototype forKey:prepareBlock];
                                            }

                                            prepareBlock(prototype, item, section, self.dataSource);
                                            CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);
                                            CGSize size = [prototype systemLayoutSizeFittingSize:targetSize];
                                            height = size.height;
                                        }
                                    }];

            return height;
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

            __block CGFloat height = 0;

            [self footerPreperationForSection:section
                                    withBlock:^(NSString *reuseIdentifier, FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock, id item) {
                                        if (prepareBlock) {

                                            UIView *prototype = [self.footerPrototypes objectForKey:prepareBlock];

                                            if (prototype == nil) {
                                                prototype = [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
                                                [self.footerPrototypes setObject:prototype forKey:prepareBlock];
                                            }

                                            prepareBlock(prototype, item, section, self.dataSource);
                                            CGSize targetSize = CGSizeMake(CGRectGetWidth(tableView.bounds), 0);
                                            CGSize size = [prototype systemLayoutSizeFittingSize:targetSize];
                                            height = size.height;
                                        }
                                    }];

            return height;
        }
    } else {
        return 0;
    }
}

@end
