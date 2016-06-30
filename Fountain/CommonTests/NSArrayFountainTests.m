//
//  NSArrayFountainTests.m
//  Fountain
//
//  Created by Tobias Kraentzer on 10.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "NSArray+Fountain.h"
#import <XCTest/XCTest.h>

@interface NSArrayFountainTests : XCTestCase

@end

@implementation NSArrayFountainTests

- (void)testSortingAscending
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ];

    NSArray *objects = @[ @(1), @(5), @(2), @(6), @(8), @(3), @(4), @(7) ];

    NSArray *sortedObjects = [NSArray ft_arrayBySortingObjects:[NSSet setWithArray:objects]
                                          usingSortDescriptors:sortDescriptors
                           orderAmbiguousObjectsByOrderInArray:@[]];

    XCTAssertEqualObjects(sortedObjects, [objects sortedArrayUsingDescriptors:sortDescriptors]);
}

- (void)testSortingDescending
{
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO] ];

    NSArray *objects = @[ @(1), @(5), @(2), @(6), @(8), @(3), @(4), @(7) ];

    NSArray *sortedObjects = [NSArray ft_arrayBySortingObjects:[NSSet setWithArray:objects]
                                          usingSortDescriptors:sortDescriptors
                           orderAmbiguousObjectsByOrderInArray:@[]];

    XCTAssertEqualObjects(sortedObjects, [objects sortedArrayUsingDescriptors:sortDescriptors]);
}

@end
