//
//  FTMovableItemsDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 03.08.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "FTMutableDataSource.h"

@protocol FTMovableItemsDataSource <FTMutableDataSource>
- (BOOL)canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath
                                       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;
- (BOOL)moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
                toIndexPath:(NSIndexPath *)destinationIndexPath
                      error:(NSError **)error;
@end
