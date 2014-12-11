//
//  FTSectinoDataSourceSpec.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#import <Specta/Specta.h>

#import "Fountain.h"

SpecBegin(FTSectionDataSource)

describe(@"FTSectionDataSource", ^{
    
    __block FTSectionDataSource *dataSource = nil;
    
    beforeEach(^{
        dataSource = [[FTSectionDataSource alloc] initWithComerator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [[obj1 valueForKey:@"value"] compare:[obj2 valueForKey:@"value"]];
        } identifer:^id<NSCopying>(NSDictionary *obj) {
            return [obj valueForKey:@"identifier"];
        }];
    });
    
    it(@"should exsits", ^{
        assertThat(dataSource, notNilValue());
    });
    
    context(@"reloading with section items", ^{
        
        beforeEach(^{
            waitUntil(^(DoneCallback done) {
                
                NSArray *items = @[
                                   @{@"identifier":@"1", @"value":@"a"},
                                   @{@"identifier":@"2", @"value":@"j"},
                                   @{@"identifier":@"3", @"value":@"b"},
                                   @{@"identifier":@"4", @"value":@"i"},
                                   @{@"identifier":@"5", @"value":@"c"},
                                   @{@"identifier":@"6", @"value":@"h"},
                                   @{@"identifier":@"7", @"value":@"d"},
                                   @{@"identifier":@"8", @"value":@"g"},
                                   @{@"identifier":@"9", @"value":@"e"},
                                   @{@"identifier":@"0", @"value":@"f"}
                ];
                
                [dataSource reloadWithInitialSectionItems:items
                                        completionHandler:^(BOOL success, NSError *error) {
                    assertThatBool(success, equalToBool(YES));
                    assertThat(error, nilValue());
                    done();
                }];
            });
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
            id item = @{@"identifier":@"6", @"value":@"h"};
            assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSetWithIndex:7]));
        });
        
        context(@"deleting an item from the data source", ^{
            
            beforeEach(^{
                [dataSource deleteSectionItems:@[@{@"identifier":@"5"}, @{@"identifier":@"8"}]];
            });
            
            it(@"shgould not contain the deleted item", ^{
                
                assertThatInteger([dataSource numberOfSections], equalToInteger(8));
                
                assertThat([[dataSource itemForSection:0] valueForKey:@"value"], equalTo(@"a"));
                assertThat([[dataSource itemForSection:1] valueForKey:@"value"], equalTo(@"b"));
                assertThat([[dataSource itemForSection:2] valueForKey:@"value"], equalTo(@"d"));
                assertThat([[dataSource itemForSection:3] valueForKey:@"value"], equalTo(@"e"));
                assertThat([[dataSource itemForSection:4] valueForKey:@"value"], equalTo(@"f"));
                assertThat([[dataSource itemForSection:5] valueForKey:@"value"], equalTo(@"h"));
                assertThat([[dataSource itemForSection:6] valueForKey:@"value"], equalTo(@"i"));
                assertThat([[dataSource itemForSection:7] valueForKey:@"value"], equalTo(@"j"));
                
                id item = @{@"identifier":@"5"};
                assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSet]));
                
                item = @{@"identifier":@"8"};
                assertThat([dataSource sectionsForItem:item], equalTo([NSIndexSet indexSet]));
            });
        });
        
    });
    
});

SpecEnd
