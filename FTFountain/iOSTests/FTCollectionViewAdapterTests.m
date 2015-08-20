//
//  FTCollectionViewAdapterTests.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 13.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import "FTFountain.h"
#import "FTFountainiOS.h"

#import "FTTestCollectionViewController.h"

@interface FTCollectionViewAdapterTests : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) FTTestCollectionViewController *viewController;
@end

@implementation FTCollectionViewAdapterTests

- (void)setUp
{
    [super setUp];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CollectionTest" bundle:[NSBundle bundleForClass:[self class]]];

    self.viewController = [storyboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    self.window.rootViewController = self.viewController;
    self.window.hidden = NO;
    self.window.rootViewController.view.frame = self.window.bounds;
}

#pragma mark Test Setup

- (void)testAdapterSetup
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;

    assertThat(adapter.collectionView, is(self.viewController.collectionView));
    assertThat(self.viewController.collectionView.delegate, is(adapter));
    assertThat(self.viewController.collectionView.dataSource, is(adapter));
}

#pragma mark Test Observation

- (void)testObserverRegistration
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;
    FTMutableArray *dataSource = [[FTMutableArray alloc] init];

    adapter.dataSource = dataSource;
    assertThat(dataSource.observers, contains(adapter, nil));

    adapter.dataSource = nil;
    assertThat(dataSource.observers, isNot(contains(adapter, nil)));
}

#pragma mark Delegate Forwarding

- (void)testDelegateForwarding
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;

    id<UICollectionViewDelegate> delegate = mockProtocol(@protocol(UICollectionViewDelegate));
    adapter.delegate = delegate;

    [adapter.collectionView.delegate collectionView:adapter.collectionView
                           didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

    [verifyCount(delegate, times(1)) collectionView:adapter.collectionView didSelectItemAtIndexPath:anything()];
}

#pragma mark Test Cell Preperation

- (void)testPreperation
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;

    [adapter forItemsMatchingPredicate:[NSPredicate predicateWithFormat:@"self < 10"]
            useCellWithReuseIdentifier:@"UICollectionViewCell"
                          prepareBlock:^(UICollectionViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                              cell.tag = 1;
                          }];

    [adapter forItemsMatchingPredicate:nil // Default Cell
            useCellWithReuseIdentifier:@"UICollectionViewCell"
                          prepareBlock:^(UICollectionViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                              cell.tag = 2;
                          }];

    [adapter forSupplementaryViewsOfKind:UICollectionElementKindSectionHeader
                       matchingPredicate:nil
              useViewWithReuseIdentifier:@"header"
                            prepareBlock:^(UICollectionReusableView *view,
                                           id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                                view.tag = 10;
                            }];

    FTMutableArray *dataSource = [[FTMutableArray alloc] init];
    [dataSource addObject:@(5)];
    [dataSource addObject:@(12)];

    adapter.dataSource = dataSource;

    [adapter.collectionView setNeedsLayout];
    [adapter.collectionView layoutIfNeeded];

    UICollectionViewCell *cell = nil;

    cell = [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(1));

    cell = [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(2));

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_8_4 // visibleSupplementaryViewsOfKind Is only avalilable in iOS 9
    NSArray *visibleSupplementaryView = [adapter.collectionView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionHeader];
    assertThat(visibleSupplementaryView, hasCountOf(1));

    UICollectionReusableView *headerView = [visibleSupplementaryView firstObject];
    assertThatInteger(headerView.tag, equalToInteger(10));
#else
    NSArray *tags = [adapter.collectionView valueForKeyPath:@"subviews.tag"];
    assertThat(tags, hasItem(@(10)));
#endif
}

#pragma mark Test Data Source Updates

- (void)testDataSourceUpdates
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;

    [adapter forItemsMatchingPredicate:nil
            useCellWithReuseIdentifier:@"UICollectionViewCell"
                          prepareBlock:^(UICollectionViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                              cell.tag = [item integerValue];
                          }];

    [adapter forSupplementaryViewsOfKind:UICollectionElementKindSectionHeader
                       matchingPredicate:nil
              useViewWithReuseIdentifier:@"header"
                            prepareBlock:^(UICollectionReusableView *view,
                                           id item, NSIndexPath *indexPath, id<FTDataSource> dataSource){
                            }];

    FTMutableArray *dataSource = [[FTMutableArray alloc] init];
    [dataSource addObject:@(5)];
    [dataSource addObject:@(12)];

    adapter.dataSource = dataSource;

    [adapter.collectionView setNeedsLayout];
    [adapter.collectionView layoutIfNeeded];

    [dataSource performBatchUpdates:^{
        [dataSource addObject:@(20)];
    }];

    [adapter.collectionView setNeedsLayout];
    [adapter.collectionView layoutIfNeeded];

    UICollectionViewCell *cell = nil;

    cell = [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cell, notNilValue());
    assertThatInteger(cell.tag, equalToInteger(20));
}

#pragma mark Test Paging

- (void)testLoadItemsBeforeFirstItem
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;

    [adapter forItemsMatchingPredicate:nil
            useCellWithReuseIdentifier:@"UICollectionViewCell"
                          prepareBlock:^(UICollectionViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                              cell.tag = [item integerValue];
                          }];

    [adapter forSupplementaryViewsOfKind:UICollectionElementKindSectionHeader
                       matchingPredicate:nil
              useViewWithReuseIdentifier:@"header"
                            prepareBlock:^(UICollectionReusableView *view,
                                           id item, NSIndexPath *indexPath, id<FTDataSource> dataSource){
                            }];

    id<FTPagingDataSource> dataSource = mockProtocol(@protocol(FTPagingDataSource));
    [given([dataSource numberOfSections]) willReturnInteger:1];
    [given([dataSource numberOfItemsInSection:0]) willReturnInteger:3];
    [given([dataSource hasItemsBeforeFirstItem]) willReturnBool:YES];

    adapter.dataSource = dataSource;

    [adapter.collectionView setNeedsLayout];
    [adapter.collectionView layoutIfNeeded];

    [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    [verifyCount(dataSource, times(1)) hasItemsBeforeFirstItem];
    [verifyCount(dataSource, times(1)) loadMoreItemsBeforeFirstItemCompletionHandler:anything()];
}

- (void)testLoadItemsAfterLastItem
{
    FTCollectionViewAdapter *adapter = self.viewController.adapter;

    [adapter forItemsMatchingPredicate:nil
            useCellWithReuseIdentifier:@"UICollectionViewCell"
                          prepareBlock:^(UICollectionViewCell *cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource) {
                              cell.tag = [item integerValue];
                          }];

    [adapter forSupplementaryViewsOfKind:UICollectionElementKindSectionHeader
                       matchingPredicate:nil
              useViewWithReuseIdentifier:@"header"
                            prepareBlock:^(UICollectionReusableView *view,
                                           id item, NSIndexPath *indexPath, id<FTDataSource> dataSource){
                            }];

    id<FTPagingDataSource> dataSource = mockProtocol(@protocol(FTPagingDataSource));
    [given([dataSource numberOfSections]) willReturnInteger:1];
    [given([dataSource numberOfItemsInSection:0]) willReturnInteger:3];
    [given([dataSource hasItemsAfterLastItem]) willReturnBool:YES];

    adapter.dataSource = dataSource;

    [adapter.collectionView setNeedsLayout];
    [adapter.collectionView layoutIfNeeded];

    [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [adapter.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];

    [verifyCount(dataSource, times(1)) hasItemsAfterLastItem];
    [verifyCount(dataSource, times(1)) loadMoreItemsAfterLastItemCompletionHandler:anything()];
}

@end
