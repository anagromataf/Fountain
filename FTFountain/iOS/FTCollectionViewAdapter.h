//
//  FTCollectionViewAdapter.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 13.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FTFountain.h"

typedef void (^FTCollectionViewAdapterCellPrepareBlock)(id cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource);

@interface FTCollectionViewAdapter : NSObject

#pragma mark Life-cycle
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

#pragma mark Collection View
@property (nonatomic, readonly) UICollectionView *collectionView;

#pragma mark Delegate
@property (nonatomic, weak) id<UICollectionViewDelegate> delegate;

#pragma mark Data Source
@property (nonatomic, strong) id<FTDataSource> dataSource;

#pragma mark Reload Behaviour
@property (nonatomic, assign) BOOL shouldSkipReloadOfUpdatedItems;
@property (nonatomic, assign) BOOL reloadMovedItems;

#pragma mark Editing
@property (nonatomic, getter=isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark User-driven Change
- (void)performUserDrivenChange:(void (^)())block;

#pragma mark Prepare Handler
- (void)forItemsMatchingPredicate:(NSPredicate *)predicate
       useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                     prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock;

- (void)forSupplementaryViewsOfKind:(NSString *)kind
                  matchingPredicate:(NSPredicate *)predicate
         useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                       prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock;

@end
