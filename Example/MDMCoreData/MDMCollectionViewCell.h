//
//  MDMCollectionViewCell.h
//  MDMCoreData
//
//  Created by Matt Glover on 11/05/2014.
//  Copyright (c) 2014 Matthew Morey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MDMCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@end
