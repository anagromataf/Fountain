//
//  NSSortDescriptorFountainTests.m
//  Fountain
//
//  Created by Tobias Kraentzer on 10.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "NSSortDescriptor+Fountain.h"
#import <XCTest/XCTest.h>

@interface NSSortDescriptorFountainTests : XCTestCase

@end

@implementation NSSortDescriptorFountainTests

- (void)testComperatorAscending
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ];

    NSArray *objects = @[ @(1), @(5), @(2), @(6), @(8), @(3), @(4), @(7) ];

    NSComparator comperator = [NSSortDescriptor ft_comperatorUsingSortDescriptors:sortDescriptors];
    NSArray *sortedObjects = [objects sortedArrayUsingComparator:comperator];

    XCTAssertEqualObjects(sortedObjects, [objects sortedArrayUsingDescriptors:sortDescriptors]);
}

- (void)testComperatorDescending
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO] ];

    NSArray *objects = @[ @(1), @(5), @(2), @(6), @(8), @(3), @(4), @(7) ];

    NSComparator comperator = [NSSortDescriptor ft_comperatorUsingSortDescriptors:sortDescriptors];
    NSArray *sortedObjects = [objects sortedArrayUsingComparator:comperator];

    XCTAssertEqualObjects(sortedObjects, [objects sortedArrayUsingDescriptors:sortDescriptors]);
}

@end
