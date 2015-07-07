//
//  FTComposedDataSourceSpec.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <Specta/Specta.h>

#import "Fountain.h"

@interface TestSectionDataSource : FTComposedDataSource
@end

SpecBegin(FTComposedDataSource)

    describe(@"FTComposedDataSource", ^{

        __block FTDynamicDataSource *sections = nil;
        __block FTComposedDataSource *dataSource = nil;

        beforeEach(^{
            sections = [[FTDynamicDataSource alloc] initWithComerator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
                return [[obj1 valueForKey:@"value"] compare:[obj2 valueForKey:@"value"]];
            }];

            dataSource = [[TestSectionDataSource alloc] initWithSectionDataSource:sections];
        });

        it(@"should exsits", ^{
            assertThat(dataSource, notNilValue());
        });

        context(@"reloading with section items", ^{

            __block id observer = nil;

            beforeEach(^{

                observer = mockProtocol(@protocol(FTDataSourceObserver));
                [dataSource addObserver:observer];

                waitUntil(^(DoneCallback done) {

                    NSArray *items = @[
                        @{ @"identifier" : @"1",
                           @"value" : @"a",
                           @"items" : @[ @"1", @"2", @"3", @"4", @"5" ] },
                        @{ @"identifier" : @"2",
                           @"value" : @"j",
                           @"items" : @[ @"A", @"B", @"C" ] },
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
                           @"value" : @"g",
                           @"items" : @[ @"x", @"y", @"z" ] },
                        @{ @"identifier" : @"9",
                           @"value" : @"e" },
                        @{ @"identifier" : @"0",
                           @"value" : @"f" }
                    ];

                    [sections reloadWithItems:items
                            completionHandler:^(BOOL success, NSError *error) {
                                assertThatBool(success, equalToBool(YES));
                                assertThat(error, nilValue());
                                done();
                            }];
                });
            });

            afterEach(^{
                [dataSource removeObserver:observer];
                observer = nil;
            });

            it(@"have called the observer to reload", ^{
                [verifyCount(observer, times(2)) dataSourceDidReload:dataSource];
            });

            it(@"should contain the section items ordered by the comperator", ^{
                assertThatInteger([dataSource numberOfSections], equalToInteger(10));

                assertThat([[dataSource itemForSection:0] valueForKey:@"value"], equalTo(@"a"));
                assertThat([[dataSource itemForSection:1] valueForKey:@"value"], equalTo(@"b"));
                assertThat([[dataSource itemForSection:2] valueForKey:@"value"], equalTo(@"c"));
                assertThat([[dataSource itemForSection:3] valueForKey:@"value"], equalTo(@"d"));
                // ...
                assertThat([[dataSource itemForSection:9] valueForKey:@"value"], equalTo(@"j"));
            });

            it(@"should return the correct section for an section item", ^{
                id item = @{ @"identifier" : @"6",
                             @"value" : @"h" };
                assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:7]));
            });

            context(@"deleting an item from the data source", ^{

                beforeEach(^{
                    [sections deleteItems:@[ @{ @"identifier" : @"5" }, @{ @"identifier" : @"8" } ]];
                });

                it(@"should not contain the deleted items", ^{

                    assertThatInteger([dataSource numberOfSections], equalToInteger(8));

                    assertThat([[dataSource itemForSection:0] valueForKey:@"value"], equalTo(@"a"));
                    assertThat([[dataSource itemForSection:1] valueForKey:@"value"], equalTo(@"b"));
                    assertThat([[dataSource itemForSection:2] valueForKey:@"value"], equalTo(@"d"));
                    assertThat([[dataSource itemForSection:3] valueForKey:@"value"], equalTo(@"e"));
                    assertThat([[dataSource itemForSection:4] valueForKey:@"value"], equalTo(@"f"));
                    assertThat([[dataSource itemForSection:5] valueForKey:@"value"], equalTo(@"h"));
                    assertThat([[dataSource itemForSection:6] valueForKey:@"value"], equalTo(@"i"));
                    assertThat([[dataSource itemForSection:7] valueForKey:@"value"], equalTo(@"j"));

                    id item = @{ @"identifier" : @"5" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSet]));

                    item = @{ @"identifier" : @"8" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSet]));
                });

                it(@"should have called the observer", ^{

                    [verifyCount(observer, times(1)) dataSourceWillChange:anything()];
                    [verifyCount(observer, times(1)) dataSourceDidChange:anything()];

                    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
                    [indexes addIndex:2];
                    [indexes addIndex:6];

                    [verifyCount(observer, times(1)) dataSource:anything() didDeleteSections:indexes];
                });
            });

            context(@"inserting items to the data source", ^{

                beforeEach(^{
                    [sections insertItems:@[ @{ @"identifier" : @"10",
                                                @"value" : @"c.1" },
                                             @{ @"identifier" : @"11",
                                                @"value" : @"g.1" } ]];
                });

                it(@" should contain the item at the correct position", ^{

                    assertThatInteger([dataSource numberOfSections], equalToInteger(12));

                    id item = @{ @"identifier" : @"10" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:3]));

                    item = @{ @"identifier" : @"11" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:8]));

                });

                it(@"should have called the observer", ^{

                    [verifyCount(observer, times(1)) dataSourceWillChange:anything()];
                    [verifyCount(observer, times(1)) dataSourceDidChange:anything()];

                    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
                    [indexes addIndex:3];
                    [indexes addIndex:8];

                    [verifyCount(observer, times(1)) dataSource:anything() didInsertSections:indexes];
                });

            });

            context(@"updating items in the data source", ^{

                beforeEach(^{
                    [sections updateItems:@[ @{ @"identifier" : @"5",
                                                @"value" : @"a" },
                                             @{ @"identifier" : @"8",
                                                @"value" : @"x",
                                                @"items" : @[ @"x", @"y", @"z" ] },
                                             @{ @"identifier" : @"2",
                                                @"value" : @"j" } ]];
                });

                it(@"should move the updated items to the correct position", ^{

                    assertThatInteger([dataSource numberOfSections], equalToInteger(10));

                    id item;

                    item = @{ @"identifier" : @"5" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:0]));

                    item = @{ @"identifier" : @"8" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:9]));

                    item = @{ @"identifier" : @"2" };
                    assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:8]));
                });

                it(@"should have called the observer", ^{

                    [verifyCount(observer, times(1)) dataSourceWillChange:anything()];
                    [verifyCount(observer, times(1)) dataSourceDidChange:anything()];

                    [verifyCount(observer, times(1)) dataSource:anything() didMoveSection:2 toSection:0];
                    [verifyCount(observer, times(1)) dataSource:anything() didMoveSection:6 toSection:9];
                });

                it(@"should have moved the items in the data sources", ^{

                    assertThatInteger([dataSource numberOfItemsInSection:6], equalToInteger(0));
                    assertThatInteger([dataSource numberOfItemsInSection:9], equalToInteger(3));

                    assertThat([dataSource itemAtIndexPath:[[NSIndexPath indexPathWithIndex:9] indexPathByAddingIndex:2]], equalTo(@"z"));
                });
            });

            context(@"using a test data source", ^{

                it(@"should use the items passed via the section items for its sections", ^{

                    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(5));
                    assertThatInteger([dataSource numberOfItemsInSection:1], equalToInteger(0));
                    assertThatInteger([dataSource numberOfItemsInSection:9], equalToInteger(3));

                    assertThat([dataSource itemAtIndexPath:[[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:2]], equalTo(@"3"));
                    assertThat([dataSource itemAtIndexPath:[[NSIndexPath indexPathWithIndex:9] indexPathByAddingIndex:1]], equalTo(@"B"));
                });

            });

            context(@"changes in a data source of a section", ^{

                beforeEach(^{
                    [observer reset];

                    FTDynamicDataSource *section = (FTDynamicDataSource *)[dataSource dataSourceForSection:3];
                    [section insertItems:@[ @"u", @"v" ]];
                });

                fit(@"should be forwared to the observer", ^{

                    assertThatInteger([dataSource numberOfItemsInSection:3], equalToInteger(2));

                    [verifyCount(observer, times(1)) dataSourceWillChange:anything()];
                    [verifyCount(observer, times(1)) dataSourceDidChange:anything()];

                    NSIndexPath *section = [NSIndexPath indexPathWithIndex:3];
                    NSArray *indexPaths = @[ [section indexPathByAddingIndex:0],
                                             [section indexPathByAddingIndex:1] ];

                    [verifyCount(observer, times(1)) dataSource:anything() didInsertItemsAtIndexPaths:indexPaths];
                });
            });

            context(@"reloading in a data source of a section", ^{

                beforeEach(^{
                    [observer reset];

                    FTDynamicDataSource *section = (FTDynamicDataSource *)[dataSource dataSourceForSection:3];
                    [section reloadWithItems:@[ @"u", @"v" ]
                           completionHandler:^(BOOL success, NSError *error){

                           }];
                });

                fit(@"should be forwared to the observer", ^{

                    assertThatInteger([dataSource numberOfItemsInSection:3], equalToInteger(2));

                    [verifyCount(observer, times(1)) dataSourceWillChange:anything()];
                    [verifyCount(observer, times(1)) dataSourceDidChange:anything()];

                    [verifyCount(observer, times(1)) dataSource:anything() didReloadSections:[NSIndexSet indexSetWithIndex:3]];
                });
            });
        });

    });

SpecEnd

    @implementation TestSectionDataSource

    - (id<FTDataSource>)createDataSourceWithSectionItem : (NSDictionary *)sectionItem
{
    FTDynamicDataSource *dataSource = [[FTDynamicDataSource alloc] initWithComerator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];

    NSArray *items = [NSArray arrayWithArray:[sectionItem objectForKey:@"items"]];

    [dataSource reloadWithItems:items
              completionHandler:^(BOOL success, NSError *error){

              }];

    return dataSource;
}

@end
