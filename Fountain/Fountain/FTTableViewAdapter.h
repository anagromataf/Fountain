//
//  FTTableViewAdapter.h
//  Fountain
//
//  Created by Tobias Kraentzer on 06.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FTDataSource.h"

typedef void(^FTTableViewAdapterCellPrepareBlock)(id cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource);
typedef void(^FTTableViewAdapterHeaderFooterPrepareBlock)(id view, id item, NSUInteger section, id<FTDataSource> dataSource);

@interface FTTableViewAdapter : NSObject

#pragma mark Life-cycle
- (instancetype)initWithTableView:(UITableView *)tableView;

#pragma mark Delegate
@property (nonatomic, weak) id<UITableViewDelegate> delegate;

#pragma mark Table View
@property (nonatomic, readonly) UITableView *tableView;

#pragma mark Data Source
@property (nonatomic, strong) id<FTDataSource> dataSource;

#pragma mark Reload Behaviour
@property (nonatomic, assign) UITableViewRowAnimation rowAnimation;
@property (nonatomic, assign) BOOL reloadRowIfItemChanged;

#pragma mark Paging
@property (nonatomic, assign) BOOL shouldLoadNextPage;

#pragma mark Heights
@property (nonatomic, assign) CGFloat estimatedRowHeight;

@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat sectionHeaderHeight;
@property (nonatomic, assign) CGFloat sectionFooterHeight;

#pragma mark Prepare Handler
- (void)forRowsMatchingPredicate:(NSPredicate *)predicate
      useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                    prepareBlock:(FTTableViewAdapterCellPrepareBlock)prepareBlock;

- (void)forHeaderMatchingPredicate:(NSPredicate *)predicate
        useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                      prepareBlock:(FTTableViewAdapterHeaderFooterPrepareBlock)prepareBlock;

- (void)forFooterMatchingPredicate:(NSPredicate *)predicate
        useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                      prepareBlock:(FTTableViewAdapterHeaderFooterPrepareBlock)prepareBlock;

#pragma mark User-driven Changes
@property (nonatomic, readonly) BOOL userDrivenChange;
- (void)beginUserDrivenChange;
- (void)endUserDrivenChange;

@end

