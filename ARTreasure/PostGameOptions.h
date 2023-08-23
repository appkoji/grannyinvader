//
//  PostGameOptions.h
//  ARTreasure
//
//  Created by Koji Murata on 15/08/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostGameOptions : UIViewController

@property (weak, nonatomic) id parent;
@property BOOL isLastBoss;

@end

NS_ASSUME_NONNULL_END
