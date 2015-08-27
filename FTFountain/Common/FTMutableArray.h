//
//  FTMutableArray.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 24.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

@interface FTMutableArray : NSMutableArray <FTDataSource, FTReverseDataSource>

@end
