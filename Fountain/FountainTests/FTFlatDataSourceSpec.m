//
//  FTFlatDataSourceSpec.m
//  Fountain
//
//  Created by Tobias Kräntzer on 12.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#import <Specta/Specta.h>

#import "Fountain.h"

SpecBegin(FTFlatDataSource)

describe(@"FTFlatDataSource", ^{
    
    __block FTFlatDataSource *dataSource = nil;
    
    beforeEach(^{
        dataSource = [[FTFlatDataSource alloc] initWithComerator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [[obj1 valueForKey:@"value"] compare:[obj2 valueForKey:@"value"]];
        } identifier:^id<NSCopying>(NSDictionary *obj) {
            return [obj valueForKey:@"identifier"];
        }];
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
                
                NSArray *items = @[@{@"identifier":@"1", @"value":@"a"},
                                   @{@"identifier":@"2", @"value":@"j"},
                                   @{@"identifier":@"3", @"value":@"b"},
                                   @{@"identifier":@"4", @"value":@"i"},
                                   @{@"identifier":@"5", @"value":@"c"},
                                   @{@"identifier":@"6", @"value":@"h"},
                                   @{@"identifier":@"7", @"value":@"d"},
                                   @{@"identifier":@"8", @"value":@"g"},
                                   @{@"identifier":@"9", @"value":@"e"},
                                   @{@"identifier":@"0", @"value":@"f"}];
                
                [dataSource reloadWithItems:items
                          completionHandler:^(BOOL success, NSError *error) {
                              assertThatBool(success, equalToBool(YES));
                              assertThat(error, nilValue());
                              done();
                          }];
            });
        });
        
        it(@"should contain the items ordered by the comperator", ^{
            assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(10));
            
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
            
            NSUInteger idx = 0;
            for (NSString *value in [@"a b c d e f g h i j" componentsSeparatedByString:@" "]) {
                assertThat([[dataSource itemAtIndexPath:[sectionIndexPath indexPathByAddingIndex:idx]] valueForKey:@"value"], equalTo(value));
                idx++;
            }
        });
        
        it(@"should return the correct index path for an item", ^{
            id item = @{@"identifier":@"6", @"value":@"h"};
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
            assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:7], nil));
        });
        
        context(@"deleting an item from the data source", ^{
            
            beforeEach(^{
                [dataSource deleteItems:@[@{@"identifier":@"5"}, @{@"identifier":@"8"}]];
            });
            
            it(@"should not contain the deleted item anymore", ^{
                
                assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(8));
                
                NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
                
                NSUInteger idx = 0;
                for (NSString *value in [@"a b d e f h i j" componentsSeparatedByString:@" "]) {
                    assertThat([[dataSource itemAtIndexPath:[sectionIndexPath indexPathByAddingIndex:idx]] valueForKey:@"value"], equalTo(value));
                    idx++;
                }
                
                id item = @{@"identifier":@"5"};
                assertThat([dataSource indexPathsOfItem:item], hasCountOf(0));
                
                item = @{@"identifier":@"8"};
                assertThat([dataSource indexPathsOfItem:item], hasCountOf(0));
            });
        });
        
        context(@"inserting items into the data source", ^{
            
            beforeEach(^{
                [dataSource insertItems:@[@{@"identifier":@"10", @"value":@"c.1"},
                                          @{@"identifier":@"11", @"value":@"g.1"}]];
            });
            
            it(@"should contain the items at the correct position", ^{
                
                assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(12));
                
                NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
                
                id item = @{@"identifier":@"10"};
                assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:3], nil));
                
                item = @{@"identifier":@"11"};
                assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:8], nil));
            });
            
        });
        
        context(@"updating items in the data source", ^{
            
            beforeEach(^{
                [dataSource updateItems:@[@{@"identifier":@"5", @"value": @"a"},
                                          @{@"identifier":@"8", @"value":@"x"},
                                          @{@"identifier":@"2", @"value":@"j"}]];
            });
            
            it(@"should move the updated items to the correct position", ^{
                
                assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(10));
                
                id item;
                
                NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:0];
                
                item = @{@"identifier":@"5"};
                assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:0], nil));
                
                item = @{@"identifier":@"8"};
                assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:9], nil));
                
                item = @{@"identifier":@"2"};
                assertThat([dataSource indexPathsOfItem:item], contains([sectionIndexPath indexPathByAddingIndex:8], nil));
            });
            
        });
    });
    
});

SpecEnd
