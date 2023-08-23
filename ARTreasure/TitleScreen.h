//
//  TitleScreen.h
//  ARTreasure
//
//  Created by Koji Murata on 26/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TitleScreen : UIViewController

@property (weak, nonatomic) id parent;
@property (strong, nonatomic) IBOutlet SCNView *sceneView;
@property (nonatomic, strong) SKScene *spriteScene;

- (void)displayTitleScreen;

@end

NS_ASSUME_NONNULL_END
