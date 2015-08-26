//
//  FTMutableSetTests.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 16.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import "FTTestItem.h"

#import "FTFountain.h"

#define IDX(item, section) [[NSIndexPath indexPathWithIndex:section] indexPathByAddingIndex:item]

@interface FTMutableSetTests : XCTestCase

@end

@implementation FTMutableSetTests

#pragma mark Test Life-cycle

- (void)testInit
{
    FTMutableSet *set = [[FTMutableSet alloc] init];

    assertThat(set, instanceOf([FTMutableSet class]));

    assertThat(set, hasCountOf(0));
}

- (void)testInitWithObjects
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @(0), @(2), @(3) ]];

    assertThat(set, instanceOf([FTMutableSet class]));

    assertThat(set, hasCountOf(3));
    assertThat(set, contains(@(0), @(2), @(3), nil));
}

- (void)testInitWithDublicates
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @(0), @(2), @(3), @(2) ]];

    assertThat(set, instanceOf([FTMutableSet class]));

    assertThat(set, hasCountOf(3));
    assertThat(set, contains(@(0), @(2), @(3), nil));
}

- (void)testInitWithSortDescriptors
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ];
    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:sortDescriptors];

    [set addObjectsFromArray:@[ @(0), @(7), @(5), @(2) ]];

    assertThat([set itemAtIndexPath:IDX(0, 0)], equalTo(@0));
    assertThat([set itemAtIndexPath:IDX(1, 0)], equalTo(@2));
    assertThat([set itemAtIndexPath:IDX(2, 0)], equalTo(@5));
    assertThat([set itemAtIndexPath:IDX(3, 0)], equalTo(@7));
}

#pragma mark Test Secure Coding

- (void)testCoding
{
    assertThatBool([FTMutableSet supportsSecureCoding], isTrue());

    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:set];
    FTMutableArray *unarchivedSet = [NSKeyedUnarchiver unarchiveObjectWithData:archive];

    assertThat(unarchivedSet, instanceOf([FTMutableSet class]));

    assertThat(unarchivedSet, hasCountOf(8));
    assertThat(unarchivedSet, contains(@0, @1, @2, @3, @4, @5, @6, @7, nil));

    assertThat(unarchivedSet.observers, hasCountOf(0));
}

#pragma mark Test Copying

- (void)testCopying
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTMutableArray *copiedSet = [set copy];

    assertThat(copiedSet, instanceOf([FTMutableSet class]));

    assertThat(copiedSet, hasCountOf(8));
    assertThat(copiedSet, contains(@0, @1, @2, @3, @4, @5, @6, @7, nil));

    assertThat(copiedSet.observers, hasCountOf(0));
}

#pragma mark Test Mutable Copying

- (void)testMutableCopying
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTMutableSet *copiedSet = [set mutableCopy];

    assertThat(copiedSet, instanceOf([FTMutableSet class]));

    assertThat(copiedSet, hasCountOf(8));
    assertThat(copiedSet, contains(@0, @1, @2, @3, @4, @5, @6, @7, nil));

    assertThat(copiedSet.observers, hasCountOf(0));
}

#pragma mark Test Managing Observers

- (void)testManagingObservers
{
    FTMutableSet *set = [FTMutableSet set];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));

    assertThat([set observers], hasCountOf(0));

    [set addObserver:observer];

    assertThat([set observers], hasCountOf(1));
    assertThat([set observers], contains(observer, nil));

    [set removeObserver:observer];

    assertThat([set observers], hasCountOf(0));
}

#pragma mark Test Batch Updates

- (void)testBatchUpdates
{
    FTMutableSet *set = [FTMutableSet set];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set performBatchUpdates:^{
        [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];
    }];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
}

#pragma mark Test Adding Objects

- (void)testAddObjects
{
    FTMutableSet *set = [FTMutableSet set];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set performBatchUpdates:^{
        [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];
    }];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didInsertItemsAtIndexPaths:@[ IDX(0, 0), IDX(1, 0), IDX(2, 0) ]];
}

#pragma mark Test Remove Objects

- (void)testRemoveObject
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @(0), @(2), @(3) ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set removeObject:@(2)];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didDeleteItemsAtIndexPaths:@[ IDX(1, 0) ]];
}

#pragma mark Test Update Object

- (void)testUpdateObject
{
    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

    NSArray *items = @[ ITEM(10), ITEM(20), ITEM(30), ITEM(40), ITEM(50), ITEM(60) ];
    [set addObjectsFromArray:items];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item = items[1];
    item.value = 45;

    [set performBatchUpdates:^{
        [set addObject:item];
        [set addObject:items[0]];
    }];

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(30));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(3, 0)] value], equalToInteger(45));

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didChangeItemsAtIndexPaths:@[ IDX(0, 0) ]];
    [verifyCount(observer, times(1)) dataSource:set didMoveItemAtIndexPath:IDX(1, 0) toIndexPath:IDX(3, 0)];
}

- (void)testMoveItemUp
{
    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

    NSArray *items = @[ ITEM(10), ITEM(20), ITEM(30), ITEM(40), ITEM(50), ITEM(60) ];
    [set addObjectsFromArray:items];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item = items[1];
    item.value = 45;

    [set addObject:item];

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(3, 0)] value], equalToInteger(45));

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didMoveItemAtIndexPath:IDX(1, 0) toIndexPath:IDX(3, 0)];
}

- (void)testMoveItemDown
{
    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

    NSArray *items = @[ ITEM(10), ITEM(20), ITEM(30), ITEM(40), ITEM(50), ITEM(60) ];
    [set addObjectsFromArray:items];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item = items[4];
    item.value = 15;

    [set addObject:item];

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(15));

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didMoveItemAtIndexPath:IDX(4, 0) toIndexPath:IDX(1, 0)];
}

#pragma mark Test Getting Metrics

- (void)testGetMetrics
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThatInt([set numberOfSections], equalToInt(1));
    assertThatInt([set numberOfItemsInSection:0], equalToInt(8));
}

#pragma mark Test Getting Items

- (void)testGetSectionItem
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThat([set sectionItemForSection:0], nilValue());
}

- (void)testGetItemAtIndexPath
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThat([set itemAtIndexPath:IDX(2, 0)], equalTo(@2));
    assertThat([set itemAtIndexPath:IDX(4, 0)], equalTo(@4));
    assertThat([set itemAtIndexPath:IDX(6, 0)], equalTo(@6));
}

@end
