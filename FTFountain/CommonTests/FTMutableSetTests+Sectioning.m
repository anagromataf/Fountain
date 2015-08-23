//
//  FTMutableSetTests+Sectioning.m
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

@interface FTMutableSetTests_Sectioning : XCTestCase

@end

@implementation FTMutableSetTests_Sectioning

- (void)testAddItems
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    FTMutableSetClusterComperator clusterComperator = ^BOOL(FTTestItem *first __strong, FTTestItem *second __strong) {
        return second.value - first.value < 10;
    };

    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:sortDescriptors
                                                clusterComperator:clusterComperator];

    // Adding items to the set. The items
    // 1 to 5 should be in the first section,
    // 16 to 20 in the second,
    // and 32 and 33 in the third,

    [set performBatchUpdates:^{
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

    // TODO: Verify calling of the observer
}

- (void)testCombineClusterByAddingItems
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    FTMutableSetClusterComperator clusterComperator = ^BOOL(FTTestItem *first __strong, FTTestItem *second __strong) {
        return second.value - first.value < 10;
    };

    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:sortDescriptors
                                                clusterComperator:clusterComperator];

    [set performBatchUpdates:^{
        NSArray *items = @[ ITEM(10),
                            ITEM(25) ];
        [set addObjectsFromArray:items];
    }];

    assertThatInteger([set numberOfSections], equalToInteger(2));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(1));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(1));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(25));

    [set addObject:ITEM(17)];

    assertThatInteger([set numberOfSections], equalToInteger(1));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(3));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(17));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(25));

    // TODO: Verify calling of the observer
}

- (void)testDevideClusterByRemovingItem
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    FTMutableSetClusterComperator clusterComperator = ^BOOL(FTTestItem *first __strong, FTTestItem *second __strong) {
        return second.value - first.value < 10;
    };

    FTMutableSet *set = [[FTMutableSet alloc] initSortDescriptors:sortDescriptors
                                                clusterComperator:clusterComperator];

    NSArray *items = @[ ITEM(10),
                        ITEM(25),
                        ITEM(17) ];

    [set addObjectsFromArray:items];

    assertThatInteger([set numberOfSections], equalToInteger(1));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(3));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(1, 0)] value], equalToInteger(17));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(2, 0)] value], equalToInteger(25));

    [set removeObject:items[2]];

    assertThatInteger([set numberOfSections], equalToInteger(2));

    assertThatInteger([set numberOfItemsInSection:0], equalToInteger(1));
    assertThatInteger([set numberOfItemsInSection:1], equalToInteger(1));

    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 0)] value], equalToInteger(10));
    assertThatInteger([(FTTestItem *)[set itemAtIndexPath:IDX(0, 1)] value], equalToInteger(25));

    // TODO: Verify calling of the observer
}

@end
