//
//  Fountain.h
//  Fountain
//
//  Created by Tobias Kräntzer on 18.07.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

@import Foundation;

#import <Availability.h>

//! Project version number for Fountain.
FOUNDATION_EXPORT double FountainVersionNumber;

//! Project version string for Fountain.
FOUNDATION_EXPORT const unsigned char FountainVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Fountain/PublicHeader.h>

#import <Fountain/FTCombinedDataSource.h>
#import <Fountain/FTDataSource.h>
#import <Fountain/FTDataSourceObserver.h>
#import <Fountain/FTFetchedDataSource.h>
#import <Fountain/FTFutureItemsDataSource.h>
#import <Fountain/FTMutableArray.h>
#import <Fountain/FTMutableClusterSet.h>
#import <Fountain/FTMutableDataSource.h>
#import <Fountain/FTMutableSet.h>
#import <Fountain/FTObserverProxy.h>
#import <Fountain/FTPagingDataSource.h>
#import <Fountain/FTReverseDataSource.h>

#if TARGET_OS_IOS
#import <Fountain/FountainiOS.h>
#elif TARGET_OS_OSX
#import <Fountain/FountainOSX.h>
#endif
