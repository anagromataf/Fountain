//
//  FTMutableSetTests.m
//  Fountain
//
//  Created by Tobias Kraentzer on 16.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <Fountain/Fountain.h>
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import "FTTestItem.h"

#define IDX(item, section) [[NSIndexPath indexPathWithIndex:section] indexPathByAddingIndex:item]

@interface FTMutableSetTests : XCTestCase

@end

@implementation FTMutableSetTests

#pragma mark Test Life-cycle

- (void)testInit
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];

    assertThat(set, instanceOf([FTMutableSet class]));

    assertThat(set, hasCountOf(0));
}

- (void)testInitWithObjects
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];

    assertThat(set, instanceOf([FTMutableSet class]));

    assertThat(set, hasCountOf(3));
    assertThat(set, contains(@(0), @(2), @(3), nil));
}

- (void)testInitWithDublicates
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @(0), @(2), @(3), @(2) ]];

    assertThat(set, instanceOf([FTMutableSet class]));

    assertThat(set, hasCountOf(3));
    assertThat(set, contains(@(0), @(2), @(3), nil));
}

- (void)testInitWithSortDescriptors
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ];
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:sortDescriptors];

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

    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

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
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

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
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

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
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set performBatchUpdate:^{
        [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];
    }];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
}

#pragma mark Test Adding Objects

- (void)testAddObjects
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set performBatchUpdate:^{
        [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];
    }];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didInsertItemsAtIndexPaths:@[ IDX(0, 0), IDX(1, 0), IDX(2, 0) ]];
}

- (void)testAddObjectsEmtySection
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] includeEmptySections:NO];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set performBatchUpdate:^{
        [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];
    }];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didInsertSections:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark Test Remove Objects

- (void)testRemoveObject
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @(0), @(2), @(3) ]];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set removeObject:@(2)];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didDeleteItemsAtIndexPaths:@[ IDX(1, 0) ]];
}

- (void)testRemoveObjectEmptySection
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] includeEmptySections:NO];
    [set addObjectsFromArray:@[ @(2) ]];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set removeObject:@(2)];

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];
    [verifyCount(observer, times(1)) dataSource:set didDeleteSections:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark Test Update Object

- (void)testUpdateObject
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

    NSArray *items = @[ ITEM(10), ITEM(20), ITEM(30), ITEM(40), ITEM(50), ITEM(60) ];
    [set addObjectsFromArray:items];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item = items[1];
    item.value = 45;

    [set performBatchUpdate:^{
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

- (void)testUpdateObjectEmptySection
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ] includeEmptySections:YES];

    NSArray *items = @[ ITEM(10), ITEM(20), ITEM(30), ITEM(40), ITEM(50), ITEM(60) ];
    [set addObjectsFromArray:items];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item = items[1];
    item.value = 45;

    [set performBatchUpdate:^{
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

- (void)testUpdateEmptySetWithAmbiguousSortOrder
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:sortDescriptors];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item1 = ITEM(3);
    FTTestItem *item2 = ITEM(5);
    FTTestItem *item3 = ITEM(5);
    FTTestItem *item4 = ITEM(5);

    NSSet *itemsSet = [NSSet setWithObjects:item1, item2, item3, item4, nil];

    [set performBatchUpdate:^{
        [set unionSet:itemsSet];
    }];

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(3));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(5));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(5));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(3, 0)] value], equalToInteger(5));

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];

    // The actual order of indexes does not matter, the only requirement is,
    // that they differ from each another.

    HCArgumentCaptor *indexPathsCaptor = [[HCArgumentCaptor alloc] init];
    [verifyCount(observer, times(1)) dataSource:set didInsertItemsAtIndexPaths:(id)indexPathsCaptor];

    NSArray *indexPathsOfInsertedObjects = [indexPathsCaptor value];

    // Expecting 4 inserted objects
    assertThat(indexPathsOfInsertedObjects, hasCountOf(4));
    assertThat(indexPathsOfInsertedObjects, containsInAnyOrder(IDX(0, 0), IDX(1, 0), IDX(2, 0), IDX(3, 0), nil));
}

- (void)testUpdateWithAmbiguousSortOrder
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:sortDescriptors];

    FTTestItem *item1 = ITEM(3);
    FTTestItem *item2 = ITEM(5);

    [set performBatchUpdate:^{
        NSSet *itemsSet = [NSSet setWithObjects:item1, item2, nil];
        [set unionSet:itemsSet];
    }];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item3 = ITEM(5);
    [set addObject:item3];

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(3));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(5));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(5));

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];

    // The actual order of indexes does not matter, the only requirement is,
    // that they differ from each another.

    HCArgumentCaptor *indexPathsCaptor = [[HCArgumentCaptor alloc] init];
    [verifyCount(observer, times(1)) dataSource:set didInsertItemsAtIndexPaths:(id)indexPathsCaptor];

    NSArray *indexPathsOfInsertedObjects = [indexPathsCaptor value];

    // Expecting 1 inserted objects
    assertThat(indexPathsOfInsertedObjects, hasCountOf(1));
    assertThat(indexPathsOfInsertedObjects, containsInAnyOrder(IDX(1, 0), nil));
}

- (void)testMoveItemUp
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

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
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

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

- (void)testMoveItemWithAmbiguousSortOrder
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ]];

    NSArray *items = @[ ITEM(10), ITEM(20), ITEM(30), ITEM(40), ITEM(50), ITEM(60) ];
    [set addObjectsFromArray:items];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    FTTestItem *item = items[1];
    item.value = 10;

    [set performBatchUpdate:^{
        [set addObject:item];     // 20 -> 10
        [set addObject:items[0]]; // 10
    }];

    // Expected values:
    // 10, 10, 30, 40, 50, 60

    [verifyCount(observer, times(1)) dataSourceWillChange:set];
    [verifyCount(observer, times(1)) dataSourceDidChange:set];

    // Expecting no change in the order of the items
    [verifyCount(observer, times(0)) dataSource:set didMoveItemAtIndexPath:anything() toIndexPath:anything()];
}

#pragma mark Test Getting Metrics

- (void)testGetMetrics
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThatUnsignedLong([set numberOfSections], equalToUnsignedLong(1));
    assertThatUnsignedLong([set numberOfItemsInSection:0], equalToUnsignedLong(8));
}

#pragma mark Test Getting Items

- (void)testGetSectionItem
{
    FTMutableSet *set = [FTMutableSet setWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThat([set sectionItemForSection:0], nilValue());
}

- (void)testGetItemAtIndexPath
{
    FTMutableSet *set = [[FTMutableSet alloc] initWithSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
    [set addObjectsFromArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThat([set itemAtIndexPath:IDX(2, 0)], equalTo(@2));
    assertThat([set itemAtIndexPath:IDX(4, 0)], equalTo(@4));
    assertThat([set itemAtIndexPath:IDX(6, 0)], equalTo(@6));
}

@end
