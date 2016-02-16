//
//  FTTableViewAdapterTests.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 12.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import "FTFountain.h"
#import "FTFountainiOS.h"

#import "FTSectionHeaderFooterView.h"

#import "FTTestItem.h"
#import "FTTestTableViewController.h"

@interface FTTableViewAdapterTests : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) FTTestTableViewController *viewController;
@end

@implementation FTTableViewAdapterTests

- (void)setUp
{
    [super setUp];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"TableTest" bundle:[NSBundle bundleForClass:[self class]]];

    self.viewController = [storyboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    self.window.rootViewController = self.viewController;
    self.window.hidden = NO;
    self.window.rootViewController.view.frame = self.window.bounds;
}

#pragma mark Test Setup

- (void)testAdapterSetup
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    assertThat(adapter.tableView, is(self.viewController.tableView));
    assertThat(self.viewController.tableView.delegate, is(adapter));
    assertThat(self.viewController.tableView.dataSource, is(adapter));
}

#pragma mark Test Observation

- (void)testObserverRegistration
{
    FTTableViewAdapter *adapter = self.viewController.adapter;
    FTMutableArray *dataSource = [[FTMutableArray alloc] init];

    adapter.dataSource = dataSource;
    assertThat(dataSource.observers, contains(adapter, nil));

    adapter.dataSource = nil;
    assertThat(dataSource.observers, isNot(contains(adapter, nil)));
}

#pragma mark Delegate Forwarding

- (void)testDelegateForwarding
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    id<UITableViewDelegate> delegate = mockProtocol(@protocol(UITableViewDelegate));
    adapter.delegate = delegate;

    [adapter.tableView.delegate tableView:adapter.tableView
                  didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

    [verifyCount(delegate, times(1)) tableView:adapter.tableView didSelectRowAtIndexPath:anything()];
}

#pragma mark Test Cell & Header/Footer Preperation

- (void)testCellPreperation
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    [adapter forRowsMatchingPredicate:[NSPredicate predicateWithFormat:@"self < 10"]
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                             cell.tag = 1;
                         }];

    [adapter forRowsMatchingPredicate:nil // Default Cell
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                             cell.tag = 2;
                         }];

    FTMutableArray *dataSource = [[FTMutableArray alloc] init];
    [dataSource addObject:@(5)];
    [dataSource addObject:@(12)];

    adapter.dataSource = dataSource;

    UITableViewCell *cell = nil;

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(1));

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(2));
}

- (void)testSectionHeaderPreperation
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    [adapter forRowsMatchingPredicate:nil
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, NSNumber *value, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                             cell.tag = [value integerValue];
                         }];

    adapter.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    adapter.tableView.estimatedSectionHeaderHeight = 45;

    [adapter.tableView registerClass:[FTSectionHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"FTSectionHeaderFooterView"];

    [adapter forHeaderMatchingPredicate:nil
             useViewWithReuseIdentifier:@"FTSectionHeaderFooterView"
                           prepareBlock:^(FTSectionHeaderFooterView *view, id item, NSUInteger section, id<FTDataSource> dataSource) {
                               view.label.numberOfLines = 0;
                               view.label.text = @"Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi.";
                           }];

    FTMutableArray *dataSource = [[FTMutableArray alloc] init];
    [dataSource addObject:@(5)];
    [dataSource addObject:@(12)];

    adapter.dataSource = dataSource;

    CGRect rect = [adapter.tableView rectForHeaderInSection:0];
    assertThatDouble(rect.size.width, equalToDouble(200));
    assertThatDouble(rect.size.height, greaterThan(@(450)));
}

- (void)testSectionFooterPreperation
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    [adapter forRowsMatchingPredicate:nil
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, NSNumber *value, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                             cell.tag = [value integerValue];
                         }];

    adapter.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    adapter.tableView.estimatedSectionFooterHeight = 45;

    [adapter.tableView registerClass:[FTSectionHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"FTSectionHeaderFooterView"];

    [adapter forFooterMatchingPredicate:nil
             useViewWithReuseIdentifier:@"FTSectionHeaderFooterView"
                           prepareBlock:^(FTSectionHeaderFooterView *view, id item, NSUInteger section, id<FTDataSource> dataSource) {
                               view.label.numberOfLines = 0;
                               view.label.text = @"Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat.";
                           }];

    FTMutableArray *dataSource = [[FTMutableArray alloc] init];
    [dataSource addObject:@(5)];
    [dataSource addObject:@(12)];

    adapter.dataSource = dataSource;

    [adapter.tableView setNeedsLayout];
    [adapter.tableView layoutIfNeeded];

    FTSectionHeaderFooterView *footer = (FTSectionHeaderFooterView *)[adapter.tableView footerViewForSection:0];
    assertThat(footer, isA([FTSectionHeaderFooterView class]));
    assertThat(footer.label.text, startsWith(@"Lorem ipsum dolor sit amet,"));

    // On iOS 8 UITableView does not call `systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority:`
    // on the `UITableViewHeaderFooterView` if this is returned as a footer view (it gets called for the header view).

    if ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"9"]) {
        CGRect rect = [adapter.tableView rectForFooterInSection:0];
        assertThatDouble(rect.size.width, equalToDouble(200));
        assertThatDouble(rect.size.height, greaterThan(@(240)));
    }
}

#pragma mark Test Data Source Updates

- (void)testDataSourceUpdates
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    [adapter forRowsMatchingPredicate:nil
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, NSNumber *value, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                             cell.tag = [value integerValue];
                         }];

    FTMutableArray *dataSource = [[FTMutableArray alloc] init];
    [dataSource addObject:@(5)];
    [dataSource addObject:@(12)];

    adapter.dataSource = dataSource;

    [dataSource addObject:@(20)];

    UITableViewCell *cell = nil;

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(20));
}

#pragma mark Test Paging

- (void)testLoadItemsBeforeFirstItem
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    [adapter forRowsMatchingPredicate:nil
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, NSNumber *value, NSIndexPath *indexPath, id<FTDataSource> dataSource){
                         }];

    id<FTPagingDataSource> dataSource = mockProtocol(@protocol(FTPagingDataSource));
    [given([dataSource numberOfSections]) willReturnInteger:1];
    [given([dataSource numberOfItemsInSection:0]) willReturnInteger:3];
    [given([dataSource hasItemsBeforeFirstItem]) willReturnBool:YES];

    adapter.dataSource = dataSource;

    [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    [verifyCount(dataSource, times(1)) hasItemsBeforeFirstItem];
    [verifyCount(dataSource, times(1)) loadMoreItemsBeforeFirstItemCompletionHandler:anything()];
}

- (void)testLoadItemsAfterLastItem
{
    FTTableViewAdapter *adapter = self.viewController.adapter;

    [adapter forRowsMatchingPredicate:nil
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, NSNumber *value, NSIndexPath *indexPath, id<FTDataSource> dataSource){
                         }];

    id<FTPagingDataSource> dataSource = mockProtocol(@protocol(FTPagingDataSource));
    [given([dataSource numberOfSections]) willReturnInteger:1];
    [given([dataSource numberOfItemsInSection:0]) willReturnInteger:3];
    [given([dataSource hasItemsAfterLastItem]) willReturnBool:YES];

    adapter.dataSource = dataSource;

    [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];

    [verifyCount(dataSource, times(1)) hasItemsAfterLastItem];
    [verifyCount(dataSource, times(1)) loadMoreItemsAfterLastItemCompletionHandler:anything()];
}

#pragma mark Test Change Operation

- (void)testChangeOperation
{
    FTTableViewAdapter *adapter = self.viewController.adapter;
    [adapter forRowsMatchingPredicate:nil
           useCellWithReuseIdentifier:@"UITableViewCell"
                         prepareBlock:^(UITableViewCell *cell, FTTestItem *item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                             cell.tag = item.value;
                         }];

    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

    FTTestItem *item1 = ITEM(10);
    FTTestItem *item2 = ITEM(20);
    FTTestItem *item3 = ITEM(30);
    FTTestItem *item4 = ITEM(40);

    NSArray *items = @[ item1, item2, item3, item4 ];
    [set addObjectsFromArray:items];

    adapter.dataSource = set;

    [adapter.tableView setNeedsLayout];
    [adapter.tableView layoutIfNeeded];

    [set performBatchUpdate:^{
        // Move last item to the top and update all other items.
        item1.value = 25;
        item4.value = 0;
        NSArray *items = @[ item1, item2, item3, item4 ];
        [set addObjectsFromArray:items];
    }];

    UITableViewCell *cell = nil;

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(0));

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(20));

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(25));

    cell = [adapter.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(30));
}

@end
