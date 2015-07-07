//
//  FTStaticDataSourceSpec.m
//  Fountain
//
//  Created by Tobias Kraentzer on 13.04.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#import <Specta/Specta.h>

#import "Fountain.h"

SpecBegin(FTStaticDataSource)

    describe(@"FTStaticDataSource", ^{

        __block FTStaticDataSource *dataSource = nil;

        beforeEach(^{
            dataSource = [[FTStaticDataSource alloc] init];
        });

        it(@"should exist", ^{
            assertThat(dataSource, notNilValue());
        });

        it(@"should always have exactly one section", ^{
            assertThatInteger([dataSource numberOfSections], equalToInteger(1));
        });

        context(@"reloading with section items", ^{

            beforeEach(^{
                waitUntil(^(DoneCallback done) {

                    NSArray *items = @[ @{ @"identifier" : @"1",
                                           @"value" : @"a" },
                                        @{ @"identifier" : @"2",
                                           @"value" : @"j" },
                                        @{ @"identifier" : @"3",
                                           @"value" : @"b" },
                                        @{ @"identifier" : @"4",
                                           @"value" : @"i" },
                                        @{ @"identifier" : @"5",
                                           @"value" : @"c" },
                                        @{ @"identifier" : @"6",
                                           @"value" : @"h" },
                                        @{ @"identifier" : @"7",
                                           @"value" : @"d" },
                                        @{ @"identifier" : @"8",
                                           @"value" : @"g" },
                                        @{ @"identifier" : @"9",
                                           @"value" : @"e" },
                                        @{ @"identifier" : @"0",
                                           @"value" : @"f" } ];

                    [dataSource reloadWithItems:items
                              completionHandler:^(BOOL success, NSError *error) {
                                  assertThatBool(success, equalToBool(YES));
                                  assertThat(error, nilValue());
                                  done();
                              }];
                });
            });

            it(@"should contain the items", ^{
                assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(10));

                NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];

                NSUInteger idx = 0;
                for (NSString *value in [@"a j bj i c h d g e f" componentsSeparatedByString:@" "]) {
                    assertThat([[dataSource itemAtIndexPath:[sectionIndexPath indexPathByAddingIndex:idx]] valueForKey:@"value"], equalTo(value));
                    idx++;
                }
            });

            it(@"should return the correct index path for an item", ^{
                id item = @{ @"identifier" : @"1",
                             @"value" : @"a" };
                NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
                assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:7], nil));
            });
        });
    });

SpecEnd
