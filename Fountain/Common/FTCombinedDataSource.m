//
//  FTCombinedDataSource.m
//  Fountain
//
//  Created by Tobias Kraentzer on 01.09.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSourceObserver.h"

#import "FTCombinedDataSource.h"

@interface FTCombinedDataSource () <FTDataSourceObserver> {
    NSHashTable *_observers;
    NSMutableArray *_sectionRanges;

    NSUInteger _dataSourceChangeCallCount;
}

@end

@implementation FTCombinedDataSource

#pragma mark Life-cycle

- (instancetype)initWithDataSources:(NSArray *)dataSources
{
    self = [super init];
    if (self) {
        _dataSources = [dataSources copy];
        _observers = [NSHashTable weakObjectsHashTable];
        _sectionRanges = [[NSMutableArray alloc] init];

        NSUInteger offset = 0;
        for (id<FTDataSource> dataSource in _dataSources) {
            [dataSource addObserver:self];

            NSUInteger numberOfSections = [dataSource numberOfSections];
            [_sectionRanges addObject:[NSValue valueWithRange:NSMakeRange(offset, numberOfSections)]];

            offset += numberOfSections;
        }
    }
    return self;
}

#pragma mark Section Mapping

- (id<FTDataSource>)dataSourceOfSection:(NSUInteger)section
{
    NSUInteger dataSourceIndex = [_sectionRanges indexOfObjectPassingTest:^BOOL(NSValue *value, NSUInteger idx, BOOL *stop) {
        NSRange range = [value rangeValue];
        return NSLocationInRange(section, range);
    }];

    if (dataSourceIndex != NSNotFound) {
        return [_dataSources objectAtIndex:dataSourceIndex];
    } else {
        return nil;
    }
}

- (NSRange)sectionRangeOfDataSource:(id<FTDataSource>)dataSource
{
    NSUInteger dataSourceIndex = [_dataSources indexOfObject:dataSource];
    return [[_sectionRanges objectAtIndex:dataSourceIndex] rangeValue];
}

- (void)setSectionRange:(NSRange)range ofDataSource:(id<FTDataSource>)dataSource
{
    NSUInteger dataSourceIndex = [_dataSources indexOfObject:dataSource];
    [_sectionRanges replaceObjectAtIndex:dataSourceIndex withObject:[NSValue valueWithRange:range]];

    NSUInteger offset = NSMaxRange(range);

    dataSourceIndex++;
    while (dataSourceIndex < [_sectionRanges count]) {

        NSRange range = [[_sectionRanges objectAtIndex:dataSourceIndex] rangeValue];
        range.location = offset;
        [_sectionRanges replaceObjectAtIndex:dataSourceIndex withObject:[NSValue valueWithRange:range]];

        offset += range.length;

        dataSourceIndex++;
    }
}

- (NSUInteger)convertSection:(NSUInteger)section toDataSource:(id<FTDataSource>)dataSource
{
    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];
    if (NSLocationInRange(section, sectionRange)) {
        return section - sectionRange.location;
    } else {
        return NSNotFound;
    }
}

- (NSUInteger)convertSection:(NSUInteger)section fromDataSource:(id<FTDataSource>)dataSource
{
    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];
    return section + sectionRange.location;
}

- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath toDataSource:(id<FTDataSource>)dataSource
{
    NSParameterAssert([indexPath length] == 2);

    NSUInteger section = [self convertSection:[indexPath indexAtPosition:0] toDataSource:dataSource];
    if (section != NSNotFound) {
        NSUInteger indexes[] = {section, [indexPath indexAtPosition:1]};
        return [NSIndexPath indexPathWithIndexes:indexes length:2];
    } else {
        return nil;
    }
}

- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath fromDataSource:(id<FTDataSource>)dataSource
{
    NSParameterAssert([indexPath length] == 2);

    NSUInteger section = [self convertSection:[indexPath indexAtPosition:0] fromDataSource:dataSource];
    if (section != NSNotFound) {
        NSUInteger indexes[] = {section, [indexPath indexAtPosition:1]};
        return [NSIndexPath indexPathWithIndexes:indexes length:2];
    } else {
        return nil;
    }
}

#pragma mark Getting Item and Section Metrics

- (NSUInteger)numberOfSections
{
    NSUInteger numberOfSections = 0;
    for (id<FTDataSource> dataSource in _dataSources) {
        numberOfSections += [dataSource numberOfSections];
    }
    return numberOfSections;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    NSUInteger convertedSection = [self convertSection:section toDataSource:dataSource];

    return [dataSource numberOfItemsInSection:convertedSection];
}

#pragma mark Getting Items and Sections

- (id)sectionItemForSection:(NSUInteger)section
{
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    NSUInteger convertedSection = [self convertSection:section toDataSource:dataSource];

    return [dataSource sectionItemForSection:convertedSection];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([indexPath length] == 2);

    NSUInteger section = [indexPath indexAtPosition:0];

    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    NSIndexPath *convertedIndexPath = [self convertIndexPath:indexPath toDataSource:dataSource];

    return [dataSource itemAtIndexPath:convertedIndexPath];
}

#pragma mark Getting Section Indexes

- (NSIndexSet *)sectionsOfSectionItem:(id)sectionItem
{
    NSMutableIndexSet *sections = [[NSMutableIndexSet alloc] init];
    for (id<FTDataSource> dataSource in _dataSources) {
        if ([dataSource conformsToProtocol:@protocol(FTReverseDataSource)]) {
            id<FTReverseDataSource> reverseDataSource = (id<FTReverseDataSource>)dataSource;
            NSMutableIndexSet *dataSourceSections = [[reverseDataSource sectionsOfSectionItem:sectionItem] mutableCopy];
            NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];
            [dataSourceSections shiftIndexesStartingAtIndex:0 by:-1 * sectionRange.location];
            [sections addIndexes:dataSourceSections];
        }
    }
    return sections;
}

#pragma mark Getting Item Index Paths

- (NSArray *)indexPathsOfItem:(id)item
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (id<FTDataSource> dataSource in _dataSources) {
        if ([dataSource conformsToProtocol:@protocol(FTReverseDataSource)]) {
            id<FTReverseDataSource> reverseDataSource = (id<FTReverseDataSource>)dataSource;
            for (NSIndexPath *indexPath in [reverseDataSource indexPathsOfItem:item]) {
                [indexPaths addObject:[self convertIndexPath:indexPath fromDataSource:dataSource]];
            }
        }
    }
    return indexPaths;
}

#pragma mark Observer

- (NSArray *)observers
{
    return [_observers allObjects];
}

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [_observers addObject:observer];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [_observers removeObject:observer];
}

#pragma mark - FTMutableDataSource

#pragma mark Insertion

- (BOOL)canInsertItem:(id)item
{
    for (id<FTDataSource> dataSource in self.dataSources) {
        if ([dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
            id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)dataSource;
            if ([mutableDataSource canInsertItem:item]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSIndexPath *)insertItem:(id)item atProposedIndexPath:(NSIndexPath *)proposedIndexPath error:(NSError **)error
{
    NSUInteger section = [proposedIndexPath indexAtPosition:0];
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    if ([dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
        NSIndexPath *convertedIndexPath = [self convertIndexPath:proposedIndexPath toDataSource:dataSource];
        id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)dataSource;
        NSIndexPath *indexPath = [mutableDataSource insertItem:item atProposedIndexPath:convertedIndexPath error:error];
        return [self convertIndexPath:indexPath fromDataSource:dataSource];
    } else {
        return nil;
    }
}

#pragma mark Editing

- (BOOL)canEditItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = [indexPath indexAtPosition:0];
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    if ([dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
        NSIndexPath *convertedIndexPath = [self convertIndexPath:indexPath toDataSource:dataSource];
        id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)dataSource;
        return [mutableDataSource canEditItemAtIndexPath:convertedIndexPath];
    } else {
        return nil;
    }
}

#pragma mark Deletion

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = [indexPath indexAtPosition:0];
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    if ([dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
        NSIndexPath *convertedIndexPath = [self convertIndexPath:indexPath toDataSource:dataSource];
        id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)dataSource;
        return [mutableDataSource canDeleteItemAtIndexPath:convertedIndexPath];
    } else {
        return nil;
    }
}

- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath error:(NSError **)error
{
    NSUInteger section = [indexPath indexAtPosition:0];
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    if ([dataSource conformsToProtocol:@protocol(FTMutableDataSource)]) {
        NSIndexPath *convertedIndexPath = [self convertIndexPath:indexPath toDataSource:dataSource];
        id<FTMutableDataSource> mutableDataSource = (id<FTMutableDataSource>)dataSource;
        return [mutableDataSource deleteItemAtIndexPath:convertedIndexPath error:error];
    } else {
        return nil;
    }
}

#pragma mark - FTMovableItemsDataSource

- (BOOL)canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = [indexPath indexAtPosition:0];
    id<FTDataSource> dataSource = [self dataSourceOfSection:section];
    if ([dataSource conformsToProtocol:@protocol(FTMovableItemsDataSource)]) {
        NSIndexPath *convertedIndexPath = [self convertIndexPath:indexPath toDataSource:dataSource];
        id<FTMovableItemsDataSource> movableItemsDataSource = (id<FTMovableItemsDataSource>)dataSource;
        return [movableItemsDataSource canMoveItemAtIndexPath:convertedIndexPath];
    } else {
        return NO;
    }
}

- (NSIndexPath *)targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath
                                       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    NSUInteger sourceSection = [sourceIndexPath indexAtPosition:0];
    id<FTDataSource> sourceDataSource = [self dataSourceOfSection:sourceSection];

    NSUInteger destinationSection = [proposedDestinationIndexPath indexAtPosition:0];
    id<FTDataSource> destinationDataSource = [self dataSourceOfSection:destinationSection];

    if (sourceDataSource == destinationDataSource) {
        if ([sourceDataSource conformsToProtocol:@protocol(FTMovableItemsDataSource)]) {
            id<FTMovableItemsDataSource> movableItemsDataSource = (id<FTMovableItemsDataSource>)sourceDataSource;
            NSIndexPath *convertedSourceIndexPath = [self convertIndexPath:sourceIndexPath toDataSource:movableItemsDataSource];
            NSIndexPath *convertedProposedDestinationIndexPath = [self convertIndexPath:proposedDestinationIndexPath toDataSource:movableItemsDataSource];
            NSIndexPath *targetIndexPath = [movableItemsDataSource targetIndexPathForMoveFromItemAtIndexPath:convertedSourceIndexPath toProposedIndexPath:convertedProposedDestinationIndexPath];
            return [self convertIndexPath:targetIndexPath fromDataSource:sourceDataSource];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

- (BOOL)moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
                toIndexPath:(NSIndexPath *)destinationIndexPath
                      error:(NSError **)error
{
    NSUInteger sourceSection = [sourceIndexPath indexAtPosition:0];
    id<FTDataSource> sourceDataSource = [self dataSourceOfSection:sourceSection];

    NSUInteger destinationSection = [destinationIndexPath indexAtPosition:0];
    id<FTDataSource> destinationDataSource = [self dataSourceOfSection:destinationSection];

    if (sourceDataSource == destinationDataSource) {
        if ([sourceDataSource conformsToProtocol:@protocol(FTMovableItemsDataSource)]) {
            id<FTMovableItemsDataSource> movableItemsDataSource = (id<FTMovableItemsDataSource>)sourceDataSource;
            NSIndexPath *convertedSourceIndexPath = [self convertIndexPath:sourceIndexPath toDataSource:movableItemsDataSource];
            NSIndexPath *convertedDestinationIndexPath = [self convertIndexPath:destinationIndexPath toDataSource:movableItemsDataSource];
            return [movableItemsDataSource moveItemAtIndexPath:convertedSourceIndexPath toIndexPath:convertedDestinationIndexPath error:error];
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

#pragma mark - FTDataSourceObserver

#pragma mark Reload

- (void)dataSourceWillReset:(id<FTDataSource>)dataSource
{
    [self dataSourceWillChange:dataSource];
}

- (void)dataSourceDidReset:(id<FTDataSource>)dataSource
{
    NSInteger numberOfSections = [dataSource numberOfSections];

    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];
    NSRange newSectionRange = NSMakeRange(sectionRange.location, numberOfSections);

    NSInteger diff = numberOfSections - sectionRange.length;

    NSIndexSet *insertedSections = nil;
    NSIndexSet *deletedSections = nil;
    NSIndexSet *changedSections = nil;

    NSRange changedRange = NSIntersectionRange(sectionRange, newSectionRange);
    changedSections = [NSIndexSet indexSetWithIndexesInRange:changedRange];

    if (diff > 0) {
        NSRange insertedRange = NSMakeRange(NSMaxRange(sectionRange), newSectionRange.length - sectionRange.length);
        insertedSections = [NSIndexSet indexSetWithIndexesInRange:insertedRange];
    } else if (diff < 0) {
        NSRange deletedRange = NSMakeRange(NSMaxRange(newSectionRange), sectionRange.length - newSectionRange.length);
        deletedSections = [NSIndexSet indexSetWithIndexesInRange:deletedRange];
    }

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([deletedSections count] > 0 && [observer respondsToSelector:@selector(dataSource:didDeleteSections:)]) {
            [observer dataSource:self didDeleteSections:deletedSections];
        }

        if ([insertedSections count] > 0 && [observer respondsToSelector:@selector(dataSource:didInsertSections:)]) {
            [observer dataSource:self didInsertSections:insertedSections];
        }

        if ([changedSections count] > 0 && [observer respondsToSelector:@selector(dataSource:didChangeSections:)]) {
            [observer dataSource:self didChangeSections:changedSections];
        }
    }

    [self setSectionRange:newSectionRange ofDataSource:dataSource];

    [self dataSourceDidChange:dataSource];
}

#pragma mark Begin End Updates

- (void)dataSourceWillChange:(id<FTDataSource>)dataSource
{
    if (_dataSourceChangeCallCount == 0) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
                [observer dataSourceWillChange:self];
            }
        }
    }

    _dataSourceChangeCallCount++;
}

- (void)dataSourceDidChange:(id<FTDataSource>)dataSource
{
    _dataSourceChangeCallCount--;

    if (_dataSourceChangeCallCount == 0) {
        for (id<FTDataSourceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
                [observer dataSourceDidChange:self];
            }
        }
    }
}

#pragma mark Manage Sections

- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)dataSourceSections
{
    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];
    sectionRange.length += [dataSourceSections count];
    [self setSectionRange:sectionRange ofDataSource:dataSource];

    NSMutableIndexSet *sections = [dataSourceSections mutableCopy];
    [sections shiftIndexesStartingAtIndex:0 by:sectionRange.location];

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didInsertSections:)]) {
            [observer dataSource:self didInsertSections:sections];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)dataSourceSections
{
    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];
    sectionRange.length -= [dataSourceSections count];
    [self setSectionRange:sectionRange ofDataSource:dataSource];

    NSMutableIndexSet *sections = [dataSourceSections mutableCopy];
    [sections shiftIndexesStartingAtIndex:0 by:sectionRange.location];

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didDeleteSections:)]) {
            [observer dataSource:self didDeleteSections:sections];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeSections:(NSIndexSet *)dataSourceSections
{
    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];

    NSMutableIndexSet *sections = [dataSourceSections mutableCopy];
    [sections shiftIndexesStartingAtIndex:0 by:sectionRange.location];

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didChangeSections:)]) {
            [observer dataSource:self didChangeSections:sections];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)dataSourceSection toSection:(NSInteger)newDataSourceSection
{
    NSRange sectionRange = [self sectionRangeOfDataSource:dataSource];

    NSInteger section = dataSourceSection + sectionRange.location;
    NSInteger newSection = newDataSourceSection + sectionRange.location;

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didMoveSection:toSection:)]) {
            [observer dataSource:self didMoveSection:section toSection:newSection];
        }
    }
}

#pragma mark Manage Items

- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)sectionIndexPaths
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSIndexPath *indexPath in sectionIndexPaths) {
        [indexPaths addObject:[self convertIndexPath:indexPath fromDataSource:dataSource]];
    }

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
            [observer dataSource:self didInsertItemsAtIndexPaths:indexPaths];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)sectionIndexPaths
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSIndexPath *indexPath in sectionIndexPaths) {
        [indexPaths addObject:[self convertIndexPath:indexPath fromDataSource:dataSource]];
    }

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
            [observer dataSource:self didDeleteItemsAtIndexPaths:indexPaths];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didChangeItemsAtIndexPaths:(NSArray *)sectionIndexPaths
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSIndexPath *indexPath in sectionIndexPaths) {
        [indexPaths addObject:[self convertIndexPath:indexPath fromDataSource:dataSource]];
    }

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didChangeItemsAtIndexPaths:)]) {
            [observer dataSource:self didChangeItemsAtIndexPaths:indexPaths];
        }
    }
}

- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)sectionIndexPath toIndexPath:(NSIndexPath *)newSectionIndexPath
{
    NSIndexPath *indexPath = [self convertIndexPath:sectionIndexPath fromDataSource:dataSource];
    NSIndexPath *newIndexPath = [self convertIndexPath:newSectionIndexPath fromDataSource:dataSource];

    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)]) {
            [observer dataSource:self didMoveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
        }
    }
}

@end
