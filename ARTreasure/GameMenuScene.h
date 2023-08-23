//
//  GameMenuScene.h
//  ARTreasure
//
//  Created by Koji Murata on 26/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GameMenuScene : UIViewController

typedef void(^completion)(BOOL finished);
@property NSInteger currentStage;
@property (strong, nonatomic) IBOutlet SCNView *sceneView;
@property (weak, nonatomic) SCNNode *sky;
@property (weak, nonatomic) id parent;
@property (weak, nonatomic) SCNNode *stageViewerCam;

- (IBAction)startPlay:(id)sender;
- (void)panTo:(CGFloat)xPos;
- (void)resetPanPosition;

@end

NS_ASSUME_NONNULL_END
