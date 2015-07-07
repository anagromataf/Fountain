//
//  FTCollectionViewAdapter.h
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FTDataSource.h"

typedef void (^FTCollectionViewAdapterCellPrepareBlock)(id cell, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource);
typedef void (^FTCollectionViewAdapterSupplementaryViewPrepareBlock)(id view, id item, NSIndexPath *indexPath, id<FTDataSource> dataSource);

@interface FTCollectionViewAdapter : NSObject

#pragma mark Life-cycle
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

#pragma mark Delegate
@property (nonatomic, weak) id<UICollectionViewDelegate> delegate;

#pragma mark Collection View
@property (nonatomic, readonly) UICollectionView *collectionView;

#pragma mark Data Source
@property (nonatomic, strong) id<FTDataSource> dataSource;

#pragma mark Paging
@property (nonatomic, assign) BOOL shouldLoadNextPage;

#pragma mark Prepare Handler

- (void)forItemsKindOfClass:(Class)aClass
 useCellWithReuseIdentifier:(NSString *)reuseIdentifier
               prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock;

- (void)forItemsConformingToProtocol:(Protocol *)aProtocol
          useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                        prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock;

- (void)forItemsMatchingPredicate:(NSPredicate *)predicate
       useCellWithReuseIdentifier:(NSString *)reuseIdentifier
                     prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock;

- (void)forSupplementaryViewsOfKind:(NSString *)kind
                  matchingPredicate:(NSPredicate *)predicate
         useViewWithReuseIdentifier:(NSString *)reuseIdentifier
                       prepareBlock:(FTCollectionViewAdapterCellPrepareBlock)prepareBlock;

@end
