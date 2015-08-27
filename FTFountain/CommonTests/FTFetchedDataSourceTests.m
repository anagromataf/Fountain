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

#import "FTEntity.h"

#import "FTFountain.h"

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

#pragma mark Seed Context

- (NSArray *)seedContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < 100; i++) {

        FTEntity *object = [[FTEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
        object.value = @(i);
        object.flag = @(i < 90);

        [objects addObject:object];
    }

    NSError *error = nil;
    BOOL success = [self.context save:&error];
    XCTAssertTrue(success, @"Failed to seed context: %@", [error localizedDescription]);

    return objects;
}

@end
