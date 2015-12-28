//
//  FTDataSource.h
//  FTFountain
//
//  Created by Tobias Kräntzer on 18.07.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTDataSourceObserver;

/** The FTDataSource protocol is adopted by an object that provides a interface to a collection of items which are grouped into sections.
    
    Sections in the data source are identified by their index number, and items are identified by their index number within a section. The mapping of sections and items to their index numbers is implementation specific. It is only required that the mapping of sections and items to their index numbers is deterministic.
 
    If a data source changes this mapping (e.g., by inserting an item, moving a section or deleting an item) it has to notify all its observers about this changes. Observers implementing the FTDataSourceObserver protocol can react to those changes an update for example the user interface.
 
    @note Methods declared in FTDataSource defining the minimal required interface and must all be implemented by a class conforming to it.
 */
@protocol FTDataSource <NSObject>

#pragma mark Getting Item and Section Metrics

/** Ask the data source to return the number of sections.
 
    @return The number of sections in the data source.
 */
- (NSUInteger)numberOfSections;

/** Ask the data source to return the number of items in a given section.
 
    @param section An index number identifying a section in the data source.
    @return The number of items in section.
 */
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

#pragma mark Getting Items and Sections

/** Ask the data source for a section item for a section.
 
    Data sources can provide special items for sections. Such section items can for example be used to summarise the content of a section. Section items are optional and implementation specific.
 
    @param section An index number identifying a section in the data source.
    @return A section item identified by the given section.
 */
- (id)sectionItemForSection:(NSUInteger)section;

/** Ask the data source for the item at a given index path.
    
    Items in a data source are addressed by an index path where the first index identifies the section and the second index the item in that section.
 
    @param indexPath An index path locating an item in the data source.
    @return An item identified by the given index path.
 */
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Observer

/** Returns all observers observing the data source.
 
    A data source must hold a weak reference to the observer. This can be achieved, if the observers are kept in a weak NSHashTable.
 
    @return An array of all currently registerd observers.
 */
- (NSArray *)observers;

/** Adds an object as an observer for the data source.
 
    @param observer The observer to add. Mustnot be nil.
 */
- (void)addObserver:(id<FTDataSourceObserver>)observer;

/** Removes an object as an observer for the data source.
 
    @param observer The observer to remove. Mustnot be nil.
 */
- (void)removeObserver:(id<FTDataSourceObserver>)observer;

@end
