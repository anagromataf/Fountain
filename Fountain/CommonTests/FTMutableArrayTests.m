//
//  FTMutableArrayTests.m
//  Fountain
//
//  Created by Tobias Kraentzer on 24.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import <Fountain/Fountain.h>

#define IDX(item, section) [[NSIndexPath indexPathWithIndex:section] indexPathByAddingIndex:item]

@interface FTMutableArrayTests : XCTestCase

@end

@implementation FTMutableArrayTests

#pragma mark Test Life-cycle

- (void)testInit
{
    FTMutableArray *array = [[FTMutableArray alloc] init];

    assertThat(array, instanceOf([FTMutableArray class]));

    assertThat(array, hasCountOf(0));
}

- (void)testInitWithObjects
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @(0), @(2), @(3) ]];

    assertThat(array, instanceOf([FTMutableArray class]));

    assertThat(array, hasCountOf(3));
    assertThat(array, contains(@(0), @(2), @(3), nil));
}

#pragma mark Test Secure Coding

- (void)testCoding
{
    assertThatBool([FTMutableArray supportsSecureCoding], isTrue());

    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:array];
    FTMutableArray *unarchivedArray = [NSKeyedUnarchiver unarchiveObjectWithData:archive];

    assertThat(unarchivedArray, instanceOf([FTMutableArray class]));

    assertThat(unarchivedArray, hasCountOf(8));
    assertThat(unarchivedArray, contains(@0, @1, @2, @3, @4, @5, @6, @7, nil));

    assertThat(unarchivedArray.observers, hasCountOf(0));
}

#pragma mark Test Copying

- (void)testCopying
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    FTMutableArray *copiedArray = [array copy];

    assertThat(copiedArray, instanceOf([FTMutableArray class]));

    assertThat(copiedArray, hasCountOf(8));
    assertThat(copiedArray, contains(@0, @1, @2, @3, @4, @5, @6, @7, nil));

    assertThat(copiedArray.observers, hasCountOf(0));
}

#pragma mark Test Mutable Copying

- (void)testMutableCopying
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    FTMutableArray *copiedArray = [array mutableCopy];

    assertThat(copiedArray, instanceOf([FTMutableArray class]));

    assertThat(copiedArray, hasCountOf(8));
    assertThat(copiedArray, contains(@0, @1, @2, @3, @4, @5, @6, @7, nil));

    assertThat(copiedArray.observers, hasCountOf(0));
}

#pragma mark Test Managing Observers

- (void)testManagingObservers
{
    FTMutableArray *array = [FTMutableArray array];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));

    assertThat([array observers], hasCountOf(0));

    [array addObserver:observer];

    assertThat([array observers], hasCountOf(1));
    assertThat([array observers], contains(observer, nil));

    [array removeObserver:observer];

    assertThat([array observers], hasCountOf(0));
}

#pragma mark Test Adding Objects

- (void)testAddObject
{
    FTMutableArray *array = [FTMutableArray array];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    [array addObject:@(0)];

    [verifyCount(observer, times(1)) dataSourceWillChange:array];
    [verifyCount(observer, times(1)) dataSourceDidChange:array];
    [verifyCount(observer, times(1)) dataSource:array didInsertItemsAtIndexPaths:@[ IDX(0, 0) ]];
}

- (void)testAddObjects
{
    FTMutableArray *array = [FTMutableArray array];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    [array addObjectsFromArray:@[ @(0), @(2), @(3) ]];

    [verifyCount(observer, times(1)) dataSourceWillChange:array];
    [verifyCount(observer, times(1)) dataSourceDidChange:array];
    [verifyCount(observer, times(1)) dataSource:array didInsertItemsAtIndexPaths:@[ IDX(0, 0) ]];
    [verifyCount(observer, times(1)) dataSource:array didInsertItemsAtIndexPaths:@[ IDX(1, 0) ]];
    [verifyCount(observer, times(1)) dataSource:array didInsertItemsAtIndexPaths:@[ IDX(2, 0) ]];
}

#pragma mark Test Remove Objects

- (void)testRemoveObject
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @(0), @(2), @(3) ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    [array removeObject:@(2)];

    [verifyCount(observer, times(1)) dataSourceWillChange:array];
    [verifyCount(observer, times(1)) dataSourceDidChange:array];
    [verifyCount(observer, times(1)) dataSource:array didDeleteItemsAtIndexPaths:@[ IDX(1, 0) ]];
}

- (void)testRemoveLastObject
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @(0), @(2), @(3) ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    [array removeLastObject];

    [verifyCount(observer, times(1)) dataSourceWillChange:array];
    [verifyCount(observer, times(1)) dataSourceDidChange:array];
    [verifyCount(observer, times(1)) dataSource:array didDeleteItemsAtIndexPaths:@[ IDX(2, 0) ]];
}

#pragma mark Test Replace Objects

- (void)testReplaceObjectsAtIndexes
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];
    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [array addObserver:observer];

    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
    [indexes addIndex:2];
    [indexes addIndex:4];
    [indexes addIndex:6];

    [array replaceObjectsAtIndexes:indexes withObjects:@[ @20, @40, @60 ]];

    [verifyCount(observer, times(1)) dataSourceWillChange:array];
    [verifyCount(observer, times(1)) dataSourceDidChange:array];

    [verifyCount(observer, times(1)) dataSource:array didChangeItemsAtIndexPaths:@[ IDX(2, 0) ]];
    [verifyCount(observer, times(1)) dataSource:array didChangeItemsAtIndexPaths:@[ IDX(4, 0) ]];
    [verifyCount(observer, times(1)) dataSource:array didChangeItemsAtIndexPaths:@[ IDX(6, 0) ]];

    assertThat([array itemAtIndexPath:IDX(2, 0)], equalTo(@20));
    assertThat([array itemAtIndexPath:IDX(4, 0)], equalTo(@40));
    assertThat([array itemAtIndexPath:IDX(6, 0)], equalTo(@60));
}

#pragma mark Test Getting Metrics

- (void)testGetMetrics
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThatUnsignedLong([array numberOfSections], equalToUnsignedLong(1));
    assertThatUnsignedLong([array numberOfItemsInSection:0], equalToUnsignedLong(8));
}

#pragma mark Test Getting Items

- (void)testGetSectionItem
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThat([array sectionItemForSection:0], nilValue());
}

- (void)testGetItemAtIndexPath
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @3, @4, @5, @6, @7 ]];

    assertThat([array itemAtIndexPath:IDX(2, 0)], equalTo(@2));
    assertThat([array itemAtIndexPath:IDX(4, 0)], equalTo(@4));
    assertThat([array itemAtIndexPath:IDX(6, 0)], equalTo(@6));
}

#pragma mark Test Reverse Data Source

- (void)testSectionIndexes
{
    FTMutableArray *array = [FTMutableArray array];

    assertThat([array sectionsOfSectionItem:@"xxx"], equalTo([NSIndexSet indexSet]));
}

- (void)testItemIndexPaths
{
    FTMutableArray *array = [FTMutableArray arrayWithArray:@[ @0, @1, @2, @0, @4, @0, @0, @7 ]];

    assertThat([array indexPathsOfItem:@0], equalTo(@[ IDX(0, 0), IDX(3, 0), IDX(5, 0), IDX(6, 0) ]));
}

@end
