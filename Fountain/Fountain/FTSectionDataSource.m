//
//  FTSectionDataSource.m
//  Fountain
//
//  Created by Tobias Kräntzer on 10.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTSectionDataSource.h"

@interface FTSectionDataSource ()
@property (nonatomic, readonly) NSComparator comperator;
@property (nonatomic, readonly) FTSectionDataSourceSectionIdentifier identifier;

@property (nonatomic, readonly) NSMutableArray *sectionItems;
@property (nonatomic, readonly) NSMapTable *sectionItemItentifiers;

@property (nonatomic, readonly) NSHashTable *observers;
@end

@implementation FTSectionDataSource

#pragma mark Life-cycle

- (instancetype)initWithComerator:(NSComparator)comperator
                        identifer:(FTSectionDataSourceSectionIdentifier)identifier
{
    self = [super init];
    if (self) {
        _comperator = comperator;
        _identifier = identifier;
        
        _sectionItems = [[NSMutableArray alloc] init];
        _sectionItemItentifiers = [NSMapTable strongToWeakObjectsMapTable];
        
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    return [self.sectionItems count];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSArray *)indexPathsOfItem:(id)item
{
    return @[];
}

#pragma mark Getting Section Item

- (id)itemForSection:(NSInteger)section
{
    return [self.sectionItems objectAtIndex:section];
}

- (NSIndexSet *)sectionsForItem:(id)item
{
    id identifier = self.identifier(item);
    return [self.sectionItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [identifier isEqual:self.identifier(obj)];
    }];
}

#pragma mark Reload

- (void)reloadWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    [self reloadWithInitialSectionItems:[self.sectionItems copy]
                      completionHandler:completionHandler];
}

- (void)reloadWithInitialSectionItems:(NSArray *)sectionItems
                    completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    // Prepare the initial sections
    // ----------------------------
    
    [self.sectionItems removeAllObjects];
    [self.sectionItems addObjectsFromArray:sectionItems];
    [self.sectionItems sortUsingComparator:self.comperator];
    
    [self.sectionItemItentifiers removeAllObjects];
    [self.sectionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.sectionItemItentifiers setObject:obj forKey:self.identifier(obj)];
    }];
    
    // Tell all observers to relaod
    // ----------------------------
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        [observer reload];
    }
    
    
    // Call the completion handler
    // ---------------------------
    
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

#pragma mark Updating

- (void)deleteSectionItems:(NSArray *)sectionItems
{
    NSMutableIndexSet *sectionsToDelete = [[NSMutableIndexSet alloc] init];
    [sectionItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger index = [self.sectionItems indexOfObject:[self.sectionItemItentifiers objectForKey:self.identifier(obj)]];
        [sectionsToDelete addIndex:index];
    }];
    
    [self.sectionItems removeObjectsAtIndexes:sectionsToDelete];
}

#pragma mark Observer

@synthesize observers = _observers;
- (NSHashTable *)observers
{
    if (_observers == nil) {
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return _observers;
}

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers addObject:observer];
    [observer reload];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [self.observers removeObject:observer];
}


@end
