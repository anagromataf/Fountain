//
//  FTSectionHeaderFooterView.m
//  Fountain
//
//  Created by Tobias Kraentzer on 12.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTSectionHeaderFooterView.h"

@implementation FTSectionHeaderFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.numberOfLines = 0;
        [self.contentView addSubview:_label];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:@{ @"label" : _label }]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:@{ @"label" : _label }]];
    }
    return self;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGSize size = [super systemLayoutSizeFittingSize:targetSize
                       withHorizontalFittingPriority:horizontalFittingPriority
                             verticalFittingPriority:verticalFittingPriority];

    return size;
}

@end
