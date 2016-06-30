//
//  FTDataSourceObserver.h
//  Fountain
//
//  Created by Tobias Kräntzer on 18.07.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTDataSource;

/** FTDataSource uses the methods defined in this protocol to notify the observers about changes of the data source.
 */
@protocol FTDataSourceObserver <NSObject>
@optional

#pragma mark Reload

/** Notifies the receiver that a data source is about to reset.
 
    After receiving this method, the state of the data source is undefined until dataSourceDidReset: has been called.
 
    @param dataSource The data source that sent this message.
 */
- (void)dataSourceWillReset:(id<FTDataSource>)dataSource;

/** Notifies the receiver that a data source has completed resetting.
 
    After receiving this method, the metrics and items have to be queried again.
 
    @param dataSource The data source that sent this message.
 */
- (void)dataSourceDidReset:(id<FTDataSource>)dataSource;

#pragma mark Begin End Updates

/** Notifies the receiver that a data source is about to start processing of one or more changes.
    
    @param dataSource The data source that sent this message.
 */
- (void)dataSourceWillChange:(id<FTDataSource>)dataSource;

/** Notifies the receiver that a data source has completed processing of one or more changes.
 
    @param dataSource The data source that sent this message.
 */
- (void)dataSourceDidChange:(id<FTDataSource>)dataSource;

#pragma mark Manage Sections

/** Notifies the receiver that a data source has inserted sections.
 
    @param dataSource The data source that sent this message.
    @param sections An index set that specifies the sections that have been inserted in the data source. If a section already exists at the specified index location, it is moved down one index location.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didInsertSections:(NSIndexSet *)sections;

/** Notifies the receiver that a data source has deleted sections.
 
    @param dataSource The data source that sent this message.
    @param sections An index set that specifies the sections that have been deleted from the data source. If a section exists after the specified index location, it is moved up one index location.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didDeleteSections:(NSIndexSet *)sections;

/** Notifies the receiver that a data source has changed sections.
 
    @param dataSource The data source that sent this message.
    @param sections An index set identifying the sections that have been changed.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didChangeSections:(NSIndexSet *)sections;

/** Notifies the receiver that a data source has moved a section.
 
    @param dataSource The data source that sent this message.
    @param section The index of the section that has been moved.
    @param newSection The index in the data source that is the destination of the move for the section. The existing section at that location slides up or down to an adjoining index position to make room for it.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection;

#pragma mark Manage Items

/** Notifies the receiver that a data source has inserted items.
 
    @param dataSource The data source that sent this message.
    @param indexPaths An array of NSIndexPath objects, each representing an item index and section index that together identify an item in the data source.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths;

/** Notifies the receiver that a data source has deleted items.
 
    @param dataSource The data source that sent this message.
    @param indexPaths An array of NSIndexPath objects, each representing an item index and section index that together identify an item in the data source.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didDeleteItemsAtIndexPaths:(NSArray *)indexPaths;

/** Notifies the receiver that a data source has changed items.
 
    @param dataSource The data source that sent this message.
    @param indexPaths An array of NSIndexPath objects, each representing an item index and section index that together identify an item in the data source.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didChangeItemsAtIndexPaths:(NSArray *)indexPaths;

/** Notifies the receiver that a data source hjas moved an item.
 
    @param dataSource The data source that sent this message.
    @param indexPath An index path identifying the item to move.
    @param newIndexPath An index path identifying the position that is the destination of the item at indexPath. The existing item at that location slides up or down to an adjoining index position to make room for it.
 */
- (void)dataSource:(id<FTDataSource>)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

@end
