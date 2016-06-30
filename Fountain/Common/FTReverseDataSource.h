//
//  FTReverseDataSource.h
//  Fountain
//
//  Created by Tobias Kräntzer on 18.07.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSource.h"

/** The FTReverseDataSource protocol is adopted by an object that provides a reverse lookup of section items and items to get the corisponding section index numbers or item index paths.
 
    Because a data source can return the same item by different index paths, a reverse data source can return several index paths for an item (same applies to sections).
 */
@protocol FTReverseDataSource <FTDataSource>

#pragma mark Getting Section Indexes

/** Ask the reverse data source to return the sections for the given object.
 
    The returned index set can be emty, in cases the object is not a section item of the data source.
 
    @param sectionItem An object for which the index number are requested.
    @return An index set with the index numbers for the sections.
 */
- (NSIndexSet *)sectionsOfSectionItem:(id)sectionItem;

#pragma mark Getting Item Index Paths

/** Ask the reverse data source to return the index paths for the given object.
 
    The returned array can be emty, in cases the object is not an item of the data source.
 
    @param item An object fir wich the index paths are requested.
    @return An array of index paths for the items.
 */
- (NSArray *)indexPathsOfItem:(id)item;

@end
