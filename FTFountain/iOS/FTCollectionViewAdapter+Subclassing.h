//
//  FTCollectionViewAdapter+Subclassing.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 13.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTCollectionViewAdapter.h"

@interface FTCollectionViewAdapter (Subclassing)

- (void)itemPreperationForItemAtIndexPath:(NSIndexPath *)indexPath
                                withBlock:(void (^)(NSString *reuseIdentifier,
                                                    FTCollectionViewAdapterCellPrepareBlock prepareBlock,
                                                    id item))block;

- (void)preperationForSupplementaryViewOfKind:(NSString *)kind
                                  atIndexPath:(NSIndexPath *)indexPath
                                    withBlock:(void (^)(NSString *reuseIdentifier,
                                                        FTCollectionViewAdapterCellPrepareBlock prepareBlock,
                                                        id item))block;

@end
