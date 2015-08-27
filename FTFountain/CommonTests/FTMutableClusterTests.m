//
//  FTMutableClusterTests+Clustering.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 17.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import "FTFountain.h"

#import "FTTestItem.h"

#define IDX(item, section) [[NSIndexPath indexPathWithIndex:section] indexPathByAddingIndex:item]

@interface FTTestClusterComperator : FTClusterComperator

@end

@interface FTMutableClusterTests_Clustering : XCTestCase

@end

@implementation FTMutableClusterTests_Clustering

- (void)testAddItems
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];

    FTMutableClusterSet *set = [[FTMutableClusterSet alloc] initSortDescriptors:sortDescriptors
                                                                     comperator:[[FTTestClusterComperator alloc] init]];

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    // Adding items to the set. The items
    // 1 to 5 should be in the first section,
    // 16 to 20 in the second,
    // and 32 and 33 in the third,

    [set performBatchUpdate:^{
        NSArray *items = @[
            ITEM(1),
            ITEM(2),
            ITEM(3),
            ITEM(5),
            ITEM(16),
            ITEM(19),
            ITEM(20),
            ITEM(32),
            ITEM(33)
        ];
        [set addObjectsFromArray:items];
    }];

    assertThatInteger([set numberOfSections], equalToInteger(3));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(4));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(3));
    assertThatInteger([set numberOfItemsInSection:2], equalToInteger(2));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(1));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(2));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(3));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(3, 0)] value], equalToInteger(5));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(16));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 1)] value], equalToInteger(19));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 1)] value], equalToInteger(20));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 2)] value], equalToInteger(32));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 2)] value], equalToInteger(33));

    [verifyCount(observer, times(1)) dataSourceWillReset:set];
    [verifyCount(observer, times(1)) dataSourceDidReset:set];
}

- (void)testCombineClusterByAddingItems
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];

    FTMutableClusterSet *set = [[FTMutableClusterSet alloc] initSortDescriptors:sortDescriptors
                                                                     comperator:[[FTTestClusterComperator alloc] init]];

    [set performBatchUpdate:^{
        NSArray *items = @[ ITEM(10),
                            ITEM(25) ];
        [set addObjectsFromArray:items];
    }];

    assertThatInteger([set numberOfSections], equalToInteger(2));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(1));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(1));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(25));

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set addObject:ITEM(17)];

    assertThatInteger([set numberOfSections], equalToInteger(1));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(3));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(17));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(25));

    [verifyCount(observer, times(1)) dataSourceWillReset:set];
    [verifyCount(observer, times(1)) dataSourceDidReset:set];
}

- (void)testDevideClusterByRemovingItem
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];

    FTMutableClusterSet *set = [[FTMutableClusterSet alloc] initSortDescriptors:sortDescriptors
                                                                     comperator:[[FTTestClusterComperator alloc] init]];

    NSArray *items = @[ ITEM(10),
                        ITEM(25),
                        ITEM(17) ];

    [set addObjectsFromArray:items];

    assertThatInteger([set numberOfSections], equalToInteger(1));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(3));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(17));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(25));

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    [set removeObject:items[2]];

    assertThatInteger([set numberOfSections], equalToInteger(2));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(1));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(1));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(25));

    [verifyCount(observer, times(1)) dataSourceWillReset:set];
    [verifyCount(observer, times(1)) dataSourceDidReset:set];
}

- (void)testUpdateItem
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];

    FTMutableClusterSet *set = [[FTMutableClusterSet alloc] initSortDescriptors:sortDescriptors
                                                                     comperator:[[FTTestClusterComperator alloc] init]];

    // Adding items to the set. The items
    // 1 to 5 should be in the first section,
    // 16 to 20 in the second,
    // and 32 and 33 in the third,

    NSArray *items = @[
        ITEM(1),
        ITEM(2),
        ITEM(3),
        ITEM(5),
        ITEM(16),
        ITEM(19),
        ITEM(20),
        ITEM(32),
        ITEM(33)
    ];

    [set performBatchUpdate:^{
        [set addObjectsFromArray:items];
    }];

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(4));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(3));
    assertThatInteger([set numberOfItemsInSection:2], equalToInteger(2));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(1));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(2));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(3));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(3, 0)] value], equalToInteger(5));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(16));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 1)] value], equalToInteger(19));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 1)] value], equalToInteger(20));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 2)] value], equalToInteger(32));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 2)] value], equalToInteger(33));

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [set addObserver:observer];

    assertThatInteger([set numberOfSections], equalToInteger(3));

    FTTestItem *item = items[2];
    item.value = 27;

    [set addObject:item];

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(3));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(6));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(1));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(2));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(5));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(16));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 1)] value], equalToInteger(19));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 1)] value], equalToInteger(20));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(3, 1)] value], equalToInteger(27));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(4, 1)] value], equalToInteger(32));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(5, 1)] value], equalToInteger(33));

    [verifyCount(observer, times(1)) dataSourceWillReset:set];
    [verifyCount(observer, times(1)) dataSourceDidReset:set];
}

@end

@implementation FTTestClusterComperator

- (BOOL)compareObject:(FTTestItem *)object1 toObject:(FTTestItem *)object2
{
    return labs(object1.value - object2.value) < 10;
}

@end
