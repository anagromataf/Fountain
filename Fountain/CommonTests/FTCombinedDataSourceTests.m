//
//  FTCombinedDataSourceTests.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 03.09.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <Fountain/Fountain.h>
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#define IDX(item, section) [[NSIndexPath indexPathWithIndex:section] indexPathByAddingIndex:item]

@interface FTCombinedDataSourceTests : XCTestCase

@end

@implementation FTCombinedDataSourceTests

- (void)testInit
{
    FTMutableArray *dataSourceA = [FTMutableArray arrayWithObjects:@"a", @"b", @"c", @"d", nil];
    FTMutableArray *dataSourceB = [FTMutableArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", nil];
    FTMutableArray *dataSourceC = [FTMutableArray arrayWithObjects:@"x", @"y", @"z", nil];

    FTCombinedDataSource *dataSource = [[FTCombinedDataSource alloc] initWithDataSources:@[ dataSourceA, dataSourceB, dataSourceC ]];

    assertThatInteger([dataSource numberOfSections], equalToInteger(3));

    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(4));
    assertThatInteger([dataSource numberOfItemsInSection:1], equalToInteger(5));
    assertThatInteger([dataSource numberOfItemsInSection:2], equalToInteger(3));

    assertThat([dataSource itemAtIndexPath:IDX(0, 0)], equalTo(@"a"));
    assertThat([dataSource itemAtIndexPath:IDX(1, 1)], equalTo(@"2"));
    assertThat([dataSource itemAtIndexPath:IDX(2, 2)], equalTo(@"z"));
}

@end
