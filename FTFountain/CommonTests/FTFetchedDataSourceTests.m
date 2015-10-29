//
//  FTFetchedDataSourceTests.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 24.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

#import "FTFountain.h"

#import "FTEntity.h"
#import "FTEntityClusterComperator.h"

#define IDX(item, section) [[NSIndexPath indexPathWithIndex:section] indexPathByAddingIndex:item]

@interface FTFetchedDataSourceTests : XCTestCase
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSPersistentStore *store;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation FTFetchedDataSourceTests

- (void)setUp
{
    [super setUp];

    self.model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:[self class]] ]];
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    self.store = [self.coordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                configuration:nil
                                                          URL:nil
                                                      options:nil
                                                        error:nil];
    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.context.persistentStoreCoordinator = self.coordinator;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark Tests

- (void)testFetchObjectsWithCompletion
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(10, 0)] value], equalTo(@(10)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(20, 0)] value], equalTo(@(20)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(30, 0)] value], equalTo(@(30)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(40, 0)] value], equalTo(@(40)));
    
    XCTestExpectation *expectFilter = [self expectationWithDescription:@"Expect Filtered Objects"];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"value >= 20"];
    [dataSource filterResultWithPredicate:filterPredicate completion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFilter fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    assertThat(dataSource.filterPredicate, equalTo(filterPredicate));
    
    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(70));
}

- (void)testFetchObjects
{
    [self seedContext];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];
    
    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];
    
    BOOL success = NO;
    NSError *error = nil;
    
    success = [dataSource fetchObject:&error];
    assertThatBool(success, isTrue());
    
    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"value >= 20"];
    success = [dataSource filterResultWithPredicate:filterPredicate error:&error];
    assertThatBool(success, isTrue());
    assertThat(dataSource.filterPredicate, equalTo(filterPredicate));
    
    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(70));
    
    success = [dataSource filterResultWithPredicate:nil error:&error];
    assertThatBool(success, isTrue());
    assertThat(dataSource.filterPredicate, nilValue());
    
    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));
}

- (void)testDeleteObject
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    FTEntity *object = [dataSource itemAtIndexPath:IDX(30, 0)];
    [self.context deleteObject:object];

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(89));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(29, 0)] value], equalTo(@(29)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(30, 0)] value], equalTo(@(31)));
}

- (void)testAddMatchingObject
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    FTEntity *object = [[FTEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
    object.value = @200;
    object.flag = @YES;

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(91));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(90, 0)] value], equalTo(@(200)));
}

- (void)testAddNotMatchingObject
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    FTEntity *object = [[FTEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
    object.value = @200;
    object.flag = @NO;

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));
}

- (void)testUpdateObject_Removal
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    FTEntity *object = [dataSource itemAtIndexPath:IDX(30, 0)];
    object.flag = @NO;

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(89));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(29, 0)] value], equalTo(@(29)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(30, 0)] value], equalTo(@(31)));
}

- (void)testUpdateObject_Insertion
{
    NSArray *objects = [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    FTEntity *object = [objects lastObject];
    object.flag = @YES;

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(91));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(90, 0)] value], equalTo(@(99)));
}

- (void)testUpdateObject_Move
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    FTEntity *object = [dataSource itemAtIndexPath:IDX(30, 0)];
    object.value = @200;

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(30, 0)] value], equalTo(@(31)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(89, 0)] value], equalTo(@(200)));
}

- (void)testOtherEntity
{
    [self seedContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(1));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(90));

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [dataSource addObserver:observer];

    NSEntityDescription *otherEntity = [NSEntityDescription entityForName:@"OtherEntity" inManagedObjectContext:self.context];
    __unused NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:otherEntity insertIntoManagedObjectContext:self.context];

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to save context: %@", [error localizedDescription]);

    [verifyCount(observer, times(0)) dataSourceWillChange:dataSource];
    [verifyCount(observer, times(0)) dataSourceDidChange:dataSource];
}

- (void)testClustering
{
    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10)]];
    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(30, 8)]];
    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(54, 12)]];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate
                                                                              clusterComperator:[[FTEntityClusterComperator alloc] init]];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(3));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(10));
    assertThatInteger([dataSource numberOfItemsInSection:1], equalToInteger(8));
    assertThatInteger([dataSource numberOfItemsInSection:2], equalToInteger(12));

    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(0, 0)] value], equalTo(@(0)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(0, 1)] value], equalTo(@(30)));
    assertThat([(FTEntity *)[dataSource itemAtIndexPath:IDX(0, 2)] value], equalTo(@(54)));
}

- (void)testUpdateCluster
{
    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10)]];
    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(30, 8)]];
    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(54, 12)]];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES] ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flag == YES"];

    FTFetchedDataSource *dataSource = [[FTFetchedDataSource alloc] initWithManagedObjectContext:self.context
                                                                                         entity:entity
                                                                                sortDescriptors:sortDescriptors
                                                                                      predicate:predicate
                                                                              clusterComperator:[[FTEntityClusterComperator alloc] init]];

    XCTestExpectation *expectFetch = [self expectationWithDescription:@"Expect Fetched Objects"];

    [dataSource fetchObjectsWithCompletion:^(BOOL success, NSError *error) {
        assertThatBool(success, isTrue());
        [expectFetch fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    assertThatInteger([dataSource numberOfSections], equalToInteger(3));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(10));
    assertThatInteger([dataSource numberOfItemsInSection:1], equalToInteger(8));
    assertThatInteger([dataSource numberOfItemsInSection:2], equalToInteger(12));

    id<FTDataSourceObserver> observer = mockProtocol(@protocol(FTDataSourceObserver));
    [dataSource addObserver:observer];

    [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(42, 4)]];

    assertThatInteger([dataSource numberOfSections], equalToInteger(2));
    assertThatInteger([dataSource numberOfItemsInSection:0], equalToInteger(10));
    assertThatInteger([dataSource numberOfItemsInSection:1], equalToInteger(24));

    [verifyCount(observer, times(1)) dataSourceWillReset:dataSource];
    [verifyCount(observer, times(1)) dataSourceDidReset:dataSource];
}

#pragma mark Seed Context

- (NSArray *)seedContext
{
    return [self seedContextWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 100)]];
}

- (NSArray *)seedContextWithIndexes:(NSIndexSet *)indexes
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSMutableArray *objects = [[NSMutableArray alloc] init];

    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        FTEntity *object = [[FTEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
        object.value = @(idx);
        object.flag = @(idx < 90);

        [objects addObject:object];
    }];

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to seed context: %@", [error localizedDescription]);

    return objects;
}

@end
