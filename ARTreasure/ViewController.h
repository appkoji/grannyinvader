//
//  ViewController.h
//  ARTreasure
//
//  Created by Koji Murata on 19/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>
#import <ARKit/ARKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController : UIViewController

typedef void(^completion)(BOOL finished);

@property (weak, nonatomic) id parent;

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (nonatomic, strong) SKScene *spriteScene;
@property (nonatomic, strong) ARWorldTrackingConfiguration *arCongifuration;

// for configured stage
@property (strong, nonatomic) NSDictionary *dat;
@property (strong, nonatomic) NSDictionary *stageConfig;
@property (strong, nonatomic) NSArray *atkSeq;
//
@property (strong, nonatomic) SCNNode *bossFumina;
@property (strong, nonatomic) SCNNode *sky;
@property (strong, nonatomic) SCNNode *blackBGNode;
@property (strong, nonatomic) SCNNode *currentStage;
//
@property (nonatomic, strong) ARWorldMap *currentWorldMap;
@property (nonatomic, strong) ARAnchor *playerDefinedAnchor;
//
@property (nonatomic, strong) NSArray <CAAnimation *> *animations;
@property (nonatomic, strong) CAAnimationGroup *pulseAnim;
//
@property (strong, nonatomic) NSString *selectedStage;

//
@property (strong, nonatomic) IBOutlet UIVisualEffectView *hpDisplayView;
@property (strong, nonatomic) IBOutlet UIProgressView *hpBar;
@property float currentHP;
//

@property BOOL isMultiplayer;
@property BOOL isHost;
@property BOOL isBoss;
@property BOOL canPlay;
@property CGPoint screenCenter;

@property NSInteger playerLife;

// for multiplayer mode
@property NSInteger numberOfFuminasTapped;
@property NSMutableArray *receivedScores;

@property (strong, nonatomic) IBOutlet UIView *objectPosConfirmDisp;
@property (strong, nonatomic) IBOutlet UIButton *opcNo;
@property (strong, nonatomic) IBOutlet UIButton *opcYes;
//@property (strong, nonatomic) IBOutlet UIButton *pauseBtn;
@property (strong, nonatomic) IBOutlet UILabel *systemDisplayLabel;

- (IBAction)opcAction:(id)sender;
- (IBAction)pauseAction:(id)sender;

- (void)showSystemLabelWith:(NSString *)str;

- (void)showPostGameOptions;
- (void)displayGameCreditAfterGameCompletion;

- (void)prepareToRunStage;
- (void)pauseSceneReturnAction:(NSInteger)idx;

- (SCNNode *)node:(NSString *)nodeName;
- (SCNNode *)getNodeContainingName:(NSString *)nodeName withinNode:(SCNNode *)sampleNode;
- (CAAnimation *)loadSCNAnimation:(NSString *)animName repeat:(float)repeatCount speed:(float)spd;

- (void)shake:(SCNNode *)node rate:(float)rate repeat:(float)repeat;
- (void)playSFX:(NSString *)name;

- (void)fadeToCam:(SCNNode *)camera fadeDuration:(float)dur completion:(completion)completionBlock;
- (void)panCamera:(NSString *)camName :(float)duration;
- (void)fadeSceneToColor:(UIColor *)clr duration:(float)duration;

@end
