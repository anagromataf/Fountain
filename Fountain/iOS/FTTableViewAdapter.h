//
//  FTTableViewAdapter.h
//  Fountain
//
//  Created by Tobias Kraentzer on 10.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FTDataSource;

typedef void (^FTTableViewAdapterCellPrepareBlock)(id cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource);
typedef void (^FTTableViewAdapterHeaderFooterPrepareBlock)(id view, id item, NSUInteger section, id<FTDataSource> dataSource);

typedef NSDictionary * (^FTTableViewAdapterCellPropertiesBlock)(id cell, NSIndexPath *indexPath, id<FTDataSource> dataSource);

@interface FTTableViewAdapter : NSObject

#pragma mark Life-cycle
- (instancetype)initWithTableView:(UITableView *)tableView;

#pragma mark Table View
@property (nonatomic, readonly) UITableView *tableView;

#pragma mark Delegate
@property (nonatomic, weak) id<UITableViewDelegate> delegate;

#pragma mark Data Source
@property (nonatomic, strong) id<FTDataSource> dataSource;

#pragma mark Reload Behaviour
@property (nonatomic, assign) UITableViewRowAnimation rowAnimation;
@property (nonatomic, assign) BOOL shouldSkipReloadOfUpdatedItems;
@property (nonatomic, assign) BOOL reloadMovedItems;

#pragma mark Editing
@property (nonatomic, getter=isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark User-driven Change
- (void)performUserDrivenChange:(void (^)())block;

#pragma mark Collapsed Sections
@property (nonatomic, readonly) NSIndexSet *collapsedSections;
- (void)setCollapsedSections:(NSIndexSet *)collapsedSections withRowAnimation:(UITableViewRowAnimation)rowAnimation;

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

#pragma mark Cell Properties
@property (nonatomic, strong) FTTableViewAdapterCellPropertiesBlock cellPropertiesBlock;

@end
