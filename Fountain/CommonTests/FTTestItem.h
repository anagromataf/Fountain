//
//  FTTestItem.h
//  Fountain
//
//  Created by Tobias Kraentzer on 23.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ITEM(value) [[FTTestItem alloc] initWithValue:value]

@interface FTTestItem : NSObject
- (instancetype)initWithValue:(NSInteger)value;
@property (nonatomic, assign) NSInteger value;
@end
