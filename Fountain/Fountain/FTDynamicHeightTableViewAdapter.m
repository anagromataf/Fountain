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
@end

@implementation FTDynamicHeightTableViewAdapter

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super initWithTableView:tableView];
    if (self) {
        _estimatedRowHeight = UITableViewAutomaticDimension;
        _rowHeight = UITableViewAutomaticDimension;
        _cellPrototypes = [NSMapTable weakToStrongObjectsMapTable];
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

@end
