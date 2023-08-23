//
//  ViewController.m
//  ARTreasure
//
//  Created by Koji Murata on 19/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//
/*
 App Title:
 EN: AR Granny / ARオバサン
 */
#define InRadian(degrees)((M_PI * degrees)/180)

#import <GameKit/GameKit.h>
#import "ViewController.h"
#import "DialogController.h"
#import "TitleScreen.h"
#import "GameMenuScene.h"
#import "PauseMenu.h"
#import "PostGameOptions.h"
#import "MainParent.h"

@interface ViewController () <ARSCNViewDelegate, SCNPhysicsContactDelegate, SKSceneDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *tapEllipse;
@property (strong, nonatomic) IBOutlet UIImageView *screenBorder;
@property (strong, nonatomic) IBOutlet UILabel *playerLifeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *glassOverlay;
@property (strong, nonatomic) IBOutlet UILabel *gameoverDisp;

@property (nonatomic, strong) SCNNode *fuminaNode;
@property (nonatomic, strong) SCNNode *ARCamera;
@property (strong, nonatomic) SCNNode *arIndicator;

@property (strong, nonatomic) SCNNode *collisionCube;

@property (strong, nonatomic) UIImage *reflect;
@property (strong, nonatomic) UIImage *alphaGradient;
@property (strong, nonatomic) UIImage *targetMarkA;
@property (strong, nonatomic) UIImage *targetMarkB;
@property (strong, nonatomic) IBOutlet UIImageView *targetMarkDisplay;

@property NSInteger numberOfFumina;
@property NSInteger currentTappedFuminas;
@property NSInteger bossBattleCount;
@property NSInteger playerState; // 0: normal 1: damaged 2: finished
@property NSInteger enemyState; // 0: normal 1: shooting 2: deceased

@property BOOL planeDetected;

@property NSTimer *hpTimer;

@property (strong, nonatomic) DialogController *dialogController;
@property (strong, nonatomic) TitleScreen *ts;
@property (strong, nonatomic) GameMenuScene *gameMenu;
@property (strong, nonatomic) PauseMenu *pauseMenu;
@property (strong, nonatomic) IBOutlet UIButton *pauseBtn;

@property BOOL gameIsActive;
@property BOOL isPlaneDetectionMode;
@property BOOL isFuminaFiring;
@property BOOL isInstructionalStage;
@property BOOL isDamaged;

@property (strong, nonatomic) SKAction *sfxFire;
@property (strong, nonatomic) SKAction *fmnShout;
@property (strong, nonatomic) SKAction *mazyHit;

@property (strong, nonatomic) SCNAction *fmnJump;

@end

@implementation ViewController

- (void)showSystemLabelWith:(NSString *)str {
    //
     dispatch_async(dispatch_get_main_queue(), ^{
         [self->_systemDisplayLabel.layer removeAllAnimations];
         [self->_systemDisplayLabel.layer setOpacity:0.0];
         [self->_systemDisplayLabel setHidden:NO];
         //
         [self->_systemDisplayLabel setText:str];
         //
         [self->_systemDisplayLabel.layer setOpacity:1.0];
         [UIView animateWithDuration:1.0 delay:3.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
             [self->_systemDisplayLabel.layer setOpacity:0.0];
         } completion:^(BOOL finished) {
             
         }];
     });
    //
}

- (void)displayTapIndicator {
    
}

// update

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    
    __block NSInteger currentTag;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //
        //check if app is in plane detection mode...
        if (self.isPlaneDetectionMode == YES) {
            
            [self.currentStage setHidden:YES];
            
            // when parent does not have worldmap stored
            ARHitTestResult *hitTestResult = [self.sceneView hitTest:self.screenCenter types:ARHitTestResultTypeExistingPlaneUsingGeometry|ARHitTestResultTypeEstimatedHorizontalPlane].firstObject;
            
            //check if hitTestResult <plane> becomes available and detected
            if (!hitTestResult) {
                //no plane detected
                self.planeDetected = NO;
                [self.tapEllipse setHidden:YES];
                [self.arIndicator setHidden:YES];
            } else {
                [self.arIndicator setHidden:NO];
                if (self.planeDetected == NO) {
                    [self playSFX:@"ARDetected"];
                    AudioServicesPlaySystemSound(1519);
                    [[self.dialogController skNode:@"deviceMove"] runAction:[SKAction fadeAlphaTo:0.0 duration:1.0]];
                    // this is the time to display tap indicator
                    [self.tapEllipse setHidden:NO];
                    [self performSelectorOnMainThread:@selector(showSystemLabelWith:) withObject:NSLocalizedString(@"startAR", nil) waitUntilDone:NO];
                }
                self.planeDetected = YES;
            }
            self.arIndicator.transform = SCNMatrix4FromMat4(hitTestResult.worldTransform);
            [self.arIndicator setEulerAngles:SCNVector3Make(InRadian(-90), 0, 0)];
            
        }
        
        currentTag = self.view.tag;
        
        if (self->_gameIsActive == YES && currentTag == 1) {
            
            __block BOOL isCheating = NO;
            
            // check if camera is hitting structures
            NSArray <SCNPhysicsContact *> *contacts = [self.sceneView.scene.physicsWorld contactTestWithBody:self->_collisionCube.physicsBody options:@{SCNPhysicsTestCollisionBitMaskKey : @(2)}];
            
            [contacts enumerateObjectsUsingBlock:^(SCNPhysicsContact * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
                //
                [self->_currentStage enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                    if ([contact.nodeB.name containsString:@"struct"] && [contact.nodeB isEqual:child] && ![child.name containsString:@"fireNode"]) {
                        [self performSelectorOnMainThread:@selector(showSystemLabelWith:) withObject:NSLocalizedString(@"noCheating", nil) waitUntilDone:NO];
                        isCheating = YES;
                        *stop = YES;
                    }
                    if ([contact.nodeB.name containsString:@"frustumFMN"] && [contact.nodeB isEqual:child] && ![child.name containsString:@"fireNode"]) {
                        //get parent of the frustum
                        NSString *fmn = contact.nodeB.parentNode.name;
                        if ([fmn containsString:@"Fumina"] && contact.nodeB.parentNode.opacity == 1.0) {
                            if ([fmn containsString:@"pw2"]) {
                                [self fumina:contact.nodeB.parentNode didUseMove:@"fireBall"]; //赤いフミナの炎は遅め...
                            } else {
                                [self fumina:contact.nodeB.parentNode didUseMove:@"fireBall0"]; //赤いフミナの炎は遅め...
                            }
                        }
                        //*stop = YES;
                    }
                    //frustumFMN
                    if ([contact.nodeB.name containsString:@"fireBall"] && contact.nodeB.accessibilityValue && self.targetMarkDisplay.isHidden == NO) {
                        [contact.nodeB setAccessibilityValue:nil];
                        [self handleGameOver:@"fireBall"];
                    } if ([contact.nodeB.name containsString:@"bossFireBall"] && contact.nodeB.accessibilityValue && self.targetMarkDisplay.isHidden == NO) {
                        [contact.nodeB setAccessibilityValue:nil];
                        [self handleGameOver:@"bossFireBall"];
                    }
                }];
            }];
            
            if (isCheating == YES) {
                // hide fumina instantly
                [[renderer scene].rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                    if ([child.name containsString:@"Fumina"]) {
                        [child setHidden:YES];
                    }
                }];
                if (self->_currentStage.presentationNode.opacity > 0.0) {
                    [self->_currentStage setOpacity:0.0];
                }
            } else {
                if (self->_currentStage.presentationNode.opacity < 1.0) {
                    [self->_currentStage setOpacity:1.0];
                    [[renderer scene].rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                        if ([child.name containsString:@"Fumina"]) {
                            [child setHidden:NO];
                        }
                    }];
                }
            }
            
            //
            [self->_sky setPosition:self.ARCamera.worldPosition];
            [self->_blackBGNode setPosition:self.ARCamera.worldPosition];
            
            
        }
    });
    
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __block BOOL isWithinTarget = false;
        NSArray *tapHitResults = [self.sceneView hitTest:self.screenCenter options:@{SCNHitTestOptionSearchMode : @0}];
        [tapHitResults enumerateObjectsUsingBlock:^(SCNHitTestResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.node.name containsString:@"Fumina"] && obj.node.presentationNode.opacity == 1.0) {
                isWithinTarget = true;
            }
        }];
        if (isWithinTarget == true) {
            [self.targetMarkDisplay setImage:self.targetMarkB];
            if (self.screenBorder.hidden == YES) {
                AudioServicesPlaySystemSound(1519);
                [self.screenBorder setHidden:NO];
            }
        } else {
            [self.targetMarkDisplay setImage:self.targetMarkA];
            [self.screenBorder setHidden:YES];
        }
    });
    
}

- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene {
    
    [scene.children enumerateObjectsUsingBlock:^(SKNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userData objectForKey:@"positionLock"]) {
            NSString *nodeName = (NSString *)[obj.userData objectForKey:@"positionLock"];
            SCNNode *nodeToLockItsPosition = [self node:nodeName];
            SCNVector3 plp = [self.sceneView projectPoint:nodeToLockItsPosition.worldPosition];
            [obj setPosition:CGPointMake(plp.x, scene.size.height-plp.y)];
            NSLog(@"nodeToLock tsPos %@ name %@ position 3D:%f z:%f", nodeToLockItsPosition, nodeName, nodeToLockItsPosition.worldPosition.y, plp.y);
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        if (self.gameIsActive == YES && self.sceneView.isPlaying == YES) {
            [self.hpDisplayView setHidden:NO];
            self.currentHP += 0.1;
            if (self.currentHP < 100) {
                float val = self.currentHP/100.00f;
                [self.hpBar setProgress:val animated:YES];
            } else {
                [self.hpBar setProgress:1.0 animated:YES];
            }
            
            if (self.currentHP > 120) {
                //temporarily hide display bar to ensure concentrated game play without pressur
                [UIView animateWithDuration:0.3 animations:^{
                    [self.hpDisplayView setAlpha:0.0];
                    [self.hpDisplayView setTransform:CGAffineTransformMakeTranslation(0, -50)];
                }];
            } else {
                [UIView animateWithDuration:0.3 animations:^{
                    [self.hpDisplayView setAlpha:1.0];
                    [self.hpDisplayView setTransform:CGAffineTransformMakeTranslation(0, 0)];
                }];
            }
            
        } else {
            [self.hpDisplayView setHidden:YES];
        }
        //
    });
    
}


// special powers / functions
- (void)fumina:(SCNNode *)fumina didUseMove:(NSString *)moveName {
    
    //check fumina's state
    if (fumina.accessibilityValue) {
        return;
    }
    
    // Fumina Actions should run in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        // fireBall must be run only when others are not shooting it...
        if (self.isFuminaFiring == true) {
            return;
        }
        
        // setup
        [fumina setAccessibilityValue:moveName];
        
        // Execute fumina actions...
        self.isFuminaFiring = true;
        [self.spriteScene runAction:self.fmnShout];
        
        // fumina must jump
        if (self.fmnJump == nil) {
            SCNAction *jump = [SCNAction moveByX:0 y:0 z:0.2 duration:0.1];
            self.fmnJump = [SCNAction sequence:@[jump, jump.reversedAction]];
        }
        
        [fumina runAction:self.fmnJump];
        
        // Change facial expression
        SCNMaterial *face = [fumina.geometry materialWithName:@"Face"];
        [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.5, 0.0)];
        
        if ([moveName isEqualToString:@"fireBall"]) {
            
            // this particular fumina will start throwing fire ball towards the camera
            SCNNode *tempFireBallCopy = [self node:@"fireBall"];
            
            SCNNode *fireBall = [tempFireBallCopy clone];
            fireBall.geometry = [tempFireBallCopy.geometry copy];
            fireBall.geometry.firstMaterial = [tempFireBallCopy.geometry.firstMaterial copy];
            
            [fireBall removeAllParticleSystems];
            [fireBall addParticleSystem:[tempFireBallCopy.particleSystems.firstObject copy]];
            SCNVector3 fBallOrigScale = fireBall.scale;
            [fireBall setScale:SCNVector3Zero];
            
            [self.sceneView.scene.rootNode addChildNode:fireBall];
            
            SCNParticleSystem *particle = fireBall.particleSystems.firstObject;
            
            [fireBall setOpacity:0.5];
            [particle setBirthRate:10];
            
            // fumina will shout the moment this move is activated
            SCNAction *halfSecWait = [SCNAction waitForDuration:0.1f];
            SCNAction *scaleFb = [SCNAction scaleTo:fBallOrigScale.x duration:0.2f];
            SCNAction *block = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [node setPosition:fumina.worldPosition];
                [node runAction:[SCNAction fadeOpacityTo:1.0 duration:0.5f]];
            }];
            //
            SCNAction *block1 = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [particle setBirthRate:40];
                [self playSFX:@"fire"];
                [fireBall setAccessibilityValue:@"inUse"];
                [fumina setAccessibilityValue:nil];
                self.isFuminaFiring = false;
            }];
            //
            SCNAction *fireBallFlight = [SCNAction moveTo:self.collisionCube.worldPosition duration:0.6f];
            SCNAction *mAcGroup = [SCNAction group:@[block1,fireBallFlight]];
            //
            SCNAction *eraseFireball = [SCNAction fadeOpacityTo:0.0 duration:0.2];
            SCNAction *block1Completion = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [self deleteNode:fireBall];
                [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.0, 0.0)];
            }];
            //
            
            SCNAction *actionSeq = [SCNAction sequence:@[scaleFb,block,mAcGroup,eraseFireball,block1Completion,halfSecWait]];
            [fireBall runAction:actionSeq];
            
        }
        
        // fireBall1
        if ([moveName isEqualToString:@"fireBall0"]) {
            
            // this particular fumina will start throwing fire ball towards the camera
            SCNNode *tempFireBallCopy = [self node:@"fireBall"];
            
            SCNNode *fireBall = [tempFireBallCopy clone];
            fireBall.geometry = [tempFireBallCopy.geometry copy];
            fireBall.geometry.firstMaterial = [tempFireBallCopy.geometry.firstMaterial copy];
            
            [fireBall removeAllParticleSystems];
            [fireBall addParticleSystem:[tempFireBallCopy.particleSystems.firstObject copy]];
            SCNVector3 fBallOrigScale = fireBall.scale;
            [fireBall setScale:SCNVector3Zero];
            
            [self.sceneView.scene.rootNode addChildNode:fireBall];
            
            SCNParticleSystem *particle = fireBall.particleSystems.firstObject;
            
            [fireBall setOpacity:0.5];
            [particle setBirthRate:10];
            
            // fumina will shout the moment this move is activated
            SCNAction *halfSecWait = [SCNAction waitForDuration:0.3f];
            SCNAction *scaleFb = [SCNAction scaleTo:fBallOrigScale.x duration:0.2f];
            SCNAction *block = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [node setPosition:fumina.worldPosition];
                [node runAction:[SCNAction fadeOpacityTo:1.0 duration:0.5f]];
            }];
            //
            SCNAction *block1 = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [particle setBirthRate:40];
                [self playSFX:@"fire"];
                [fireBall setAccessibilityValue:@"inUse"];
                self.isFuminaFiring = false;
            }];
            //
            SCNAction *fireBallFlight = [SCNAction moveTo:self.collisionCube.worldPosition duration:1.5f];
            SCNAction *mAcGroup = [SCNAction group:@[block1,fireBallFlight]];
            //
            SCNAction *eraseFireball = [SCNAction fadeOpacityTo:0.0 duration:0.2];
            SCNAction *block1Completion = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [fumina setAccessibilityValue:nil];
                [self deleteNode:fireBall];
                [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.0, 0.0)];
            }];
            //
            
            SCNAction *actionSeq = [SCNAction sequence:@[scaleFb,block,mAcGroup,eraseFireball,block1Completion,halfSecWait]];
            
            [fireBall runAction:actionSeq];
            
        }
        
        // bossFireBall - onlyApplies to boss
        if ([moveName isEqualToString:@"bossFireBall"]) {
            
            // this particular fumina will start throwing fire ball towards the camera
            SCNNode *tempFireBallCopy = [self node:@"bossFireBall"];
            
            SCNNode *fireBall = [tempFireBallCopy clone];
            
            NSLog(@"fireBall used orig:%@ copied:%@", tempFireBallCopy, fireBall);
            
            fireBall.geometry = [tempFireBallCopy.geometry copy];
            fireBall.geometry.firstMaterial = [tempFireBallCopy.geometry.firstMaterial copy];
            
            [fireBall removeAllParticleSystems];
            [fireBall addParticleSystem:[tempFireBallCopy.particleSystems.firstObject copy]];
            
            SCNVector3 fBallOrigScale = fireBall.scale;
            [fireBall setScale:SCNVector3Zero];
            
            [self.sceneView.scene.rootNode addChildNode:fireBall];
            
            SCNParticleSystem *particle = fireBall.particleSystems.firstObject;
            
            [fireBall setOpacity:0.0];
            [particle setBirthRate:10];
            
            // fumina will shout the moment this move is activated
            //
            //SCNAction *halfSecWait = [SCNAction waitForDuration:0.1f];
            SCNAction *scaleFb = [SCNAction scaleTo:fBallOrigScale.x duration:0.2f];
            SCNAction *block = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                if ([fumina isEqual:self->_bossFumina]) {
                    SCNNode *bossFuminasHead = [self->_bossFumina childNodeWithName:@"HeadCenter" recursively:YES];
                    [node setPosition:bossFuminasHead.worldPosition];
                } else {
                    [node setPosition:fumina.worldPosition];
                }
                [node runAction:[SCNAction fadeOpacityTo:1.0 duration:0.5f]];
            }];
            //
            SCNAction *block1 = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [particle setBirthRate:40];
                [self playSFX:@"fire"];
                [fireBall setAccessibilityValue:@"inUse"];
                [fumina setAccessibilityValue:nil];
                self.isFuminaFiring = false;
            }];
            //
            SCNAction *fireBallFlight = [SCNAction moveTo:self.collisionCube.worldPosition duration:0.6f];
            SCNAction *mAcGroup = [SCNAction group:@[block1,fireBallFlight]];
            //
            SCNAction *eraseFireball = [SCNAction fadeOpacityTo:0.0 duration:0.2];
            SCNAction *block1Completion = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                [self deleteNode:fireBall];
                [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.0, 0.0)];
            }];
            //
            //
            
            SCNAction *actionSeq = [SCNAction sequence:@[scaleFb,block,mAcGroup,eraseFireball,block1Completion]];
            [fireBall runAction:actionSeq];
            
            // run action on fumina
            
        }
        
        if ([moveName isEqualToString:@"bossFireBall2"]) {
            
            // this particular fumina will start throwing fire ball towards the camera
            SCNNode *tempFireBallCopy = [self node:@"fireBall"];
            
            [fumina setAccessibilityValue:nil];
            
            SCNNode *fireBall = [tempFireBallCopy clone];
            [fireBall setScale:SCNVector3Make(1.0, 1.0, 1.0)];
            fireBall.geometry = [tempFireBallCopy.geometry copy];
            fireBall.geometry.firstMaterial = [tempFireBallCopy.geometry.firstMaterial copy];
            [fireBall removeAllParticleSystems];// remove first before assigning...
            [fireBall addParticleSystem:[tempFireBallCopy.particleSystems.firstObject copy]];
            SCNVector3 fBallOrigScale = fireBall.scale;
            [fireBall setScale:SCNVector3Zero];
            
            [self.sceneView.scene.rootNode addChildNode:fireBall];
            
            SCNParticleSystem *particle = fireBall.particleSystems.firstObject;
            
            [fireBall setOpacity:0.0];
            [particle setBirthRate:0];
            
            SCNNode *bossFuminasHead = [self.bossFumina childNodeWithName:@"HeadCenter" recursively:YES];
            [fireBall setPosition:bossFuminasHead.worldPosition];
            
            // fumina will shout the moment this move is activated
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.3f];
            [fireBall setScale:fBallOrigScale];
            [fireBall setOpacity:1.0];
            [particle setBirthRate:100];
            [SCNTransaction commit];
            //
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // start throwing fireball towards camera
                [self playSFX:@"fire"];
                [fireBall setAccessibilityValue:@"inUse"];
                self.isFuminaFiring = false;
                
                [SCNTransaction begin];
                [SCNTransaction setCompletionBlock:^{
                    [self deleteNode:fireBall];
                }];
                [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
                [SCNTransaction setAnimationDuration:0.4f];
                [fireBall setWorldPosition:self.ARCamera.worldPosition];
                [SCNTransaction commit];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SCNTransaction begin];
                    [SCNTransaction setCompletionBlock:^{
                        [fireBall setAccessibilityValue:nil];
                    }];
                    [SCNTransaction setAnimationDuration:0.2f];
                    [fireBall setOpacity:0.0];
                    [particle setBirthRate:0];
                    [SCNTransaction commit];
                });
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.0, 0.0)];
                });
                //
            });
        }
        
    });
    

}


// persistent moves (action that starts from beginning until caught)
- (void)fuminaPersistentAction:(SCNNode *)fumina {
    
    if ([fumina.name containsString:@"hs1"]) {
        // hide/show at standard speed
        SCNAction *show = [SCNAction moveBy:SCNVector3Make(0, 0, +0.1) duration:1.0f];
        SCNAction *show2 = [show reversedAction];
        SCNAction *wait = [SCNAction waitForDuration:2.0];
        SCNAction *seq = [SCNAction sequence:@[show,wait,show2,wait]];
        // add hs1 action
        [fumina runAction:[SCNAction repeatActionForever:seq]];
    }
    
}

// configured moves (action that move programatically)
- (void)bossFuminaMoves:(NSDictionary *)configuredMoves {
    
    float delay = 0.0;
    
    //setup
    if ([configuredMoves objectForKey:@"bossDefaultAnim"]) {
        NSInteger idx = [[configuredMoves objectForKey:@"bossDefaultAnim"] integerValue];
        [_bossFumina addAnimation:[_animations objectAtIndex:idx] forKey:@"tired_upset"];
    }
    
    //fadeToAudio
    if ([configuredMoves objectForKey:@"fadeToAudio"]) {
        NSArray *cmd = [[configuredMoves objectForKey:@"fadeToAudio"] componentsSeparatedByString:@"|"];
        [self.parent fadeAudio:cmd.firstObject fadeDuration:[cmd.lastObject floatValue]];
    }
    
    // sprite: spriteAction
    if ([configuredMoves objectForKey:@"spriteAction"]) {
        
        // main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *spriteActions = [configuredMoves objectForKey:@"spriteAction"];
            [spriteActions enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull actionCmd, NSUInteger idx, BOOL * _Nonnull stop) {
                [self.dialogController skNodeAction:actionCmd];
            }];
        });
        
    }
    
    // scene
    if ([configuredMoves objectForKey:@"nodeAction"]) {
        
        NSDictionary *nodeAction = [configuredMoves objectForKey:@"nodeAction"];
        SCNNode *node = [self node:[nodeAction objectForKey:@"node"]];
        
        float delay = 0.0;
        if ([nodeAction objectForKey:@"delay"]) {
            delay = [[nodeAction objectForKey:@"delay"] floatValue];
        }
        
        int bRate = 0.0;
        if ([nodeAction objectForKey:@"particleBirthRate"]) {
            bRate = [[nodeAction objectForKey:@"particleBirthRate"] intValue];
        }
        float opacity = 0.0;
        if ([nodeAction objectForKey:@"opacity"]) {
            opacity = [[nodeAction objectForKey:@"opacity"] floatValue];
        }
        float duration = 0.0;
        if ([nodeAction objectForKey:@"duration"]) {
            duration = [[nodeAction objectForKey:@"duration"] floatValue];
        }
        
        if ([nodeAction objectForKey:@"sfx"]) {
            [self playSFX:[nodeAction objectForKey:@"sfx"]];
        }
        
        
        SCNAction *delayAction = [SCNAction waitForDuration:delay];
        
        [node.particleSystems.firstObject setBirthRate:bRate];
        [node runAction:[SCNAction sequence:@[delayAction,[SCNAction fadeOpacityTo:opacity duration:duration]]]];
        
    }
    
    //increase phase, when game becomes more fun
    if ([configuredMoves objectForKey:@"setPhase"]) {
        
        [self playSFX:@"battleCymbal"];
        
        delay += 2.5;
        
        [self.view setBackgroundColor:[UIColor whiteColor]];
        
        [UIView animateWithDuration:0.5f animations:^{
            [self.sceneView setAlpha:0.01];
        } completion:^(BOOL finished) {
            
            //
            SCNNode *phaseStructure = [self node:(NSString *)[configuredMoves objectForKey:@"setPhase"]];
            __block SCNNode *mainBuildingBase;
            
            //hide all structure based node
            [self->_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                if ([node.name containsString:@"BuildingBase"]) {
                    mainBuildingBase = node;
                    *stop = YES;
                }
            }];
            NSLog(@"mainBuildingBase %@", mainBuildingBase);
            // unhide only the selected phase aanta no oshiri wa totemo koosaee dess
            // setting geometry
            [mainBuildingBase setGeometry:nil];
            [mainBuildingBase setGeometry:phaseStructure.geometry];
            //
            [UIView animateWithDuration:1.5f animations:^{
                [self.sceneView setAlpha:1.0];
            }];
        }];
    }
    
    // managing sequence actions for boss node itself
    NSArray *action = [configuredMoves objectForKey:@"action"];
    SCNVector3 originalPos = SCNVector3Zero;
    __block NSMutableArray *actionSequece = [NSMutableArray new];
    
    [action enumerateObjectsUsingBlock:^(NSString * _Nonnull cmdStr, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSArray *cmd = [cmdStr componentsSeparatedByString:@"|"];
        
        SCNAction *currentAction;
        
        //main cmd
        if ([cmd.firstObject isEqualToString:@"move"]) {
            float duration = [cmd.lastObject floatValue];
            currentAction = [SCNAction moveByX:0 y:0 z:0.35 duration:duration];
        }
        //main cmd
        if ([cmd.firstObject isEqualToString:@"back"]) {
            float duration = [cmd.lastObject floatValue];
            currentAction = [SCNAction moveTo:originalPos duration:duration];
        }
        if ([cmd.firstObject isEqualToString:@"wait"]) {
            float duration = [cmd.lastObject floatValue];
            currentAction = [SCNAction waitForDuration:duration];
        }
        if ([cmd.firstObject isEqualToString:@"bossMove"]) {
            float duration = [cmd.lastObject floatValue];
            currentAction = [SCNAction waitForDuration:duration];
            //boss will open its flame during this phase
            
            SCNNode *flameNode = [self node:@"bossFlame-fireNode-vfx-yMove"];
            //open fire
            [flameNode setOpacity:1.0];
            
        }
        if ([cmd.firstObject isEqualToString:@"attack"]) {
            NSInteger atkIndex = [cmd.lastObject integerValue];
            // attack action that throws attack
            SCNAction *attackAction = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                // attack while rotating
                CGFloat rotation = [self pointAngleFrom:self->_bossFumina.presentationNode.worldPosition to:self.ARCamera.presentationNode.worldPosition];
                SCNAction *rotateAction = [SCNAction rotateToX:self->_bossFumina.eulerAngles.x y:self->_bossFumina.eulerAngles.y z:InRadian(rotation) duration:0.25f shortestUnitArc:YES];
                [node runAction:rotateAction];
                // throw animation attack
                if (atkIndex == 1) {
                    // fast
                    [self->_bossFumina addAnimation:self->_animations[2] forKey:@"atk"];
                    [self fumina:self->_bossFumina didUseMove:@"bossFireBall2"];
                } else {
                    // slow
                    [self->_bossFumina addAnimation:self->_animations[2] forKey:@"atk"];
                    [self fumina:self->_bossFumina didUseMove:@"bossFireBall2"];
                }
            }];
            // after shooting, hide as quick as possible
            SCNAction *wait = [SCNAction waitForDuration:0.2f];
            currentAction = [SCNAction sequence:@[attackAction, wait]];
        }
        // cmd for sub boss characters
        [actionSequece addObject:currentAction];
    }];
    
    
    
    // managing base fuminas
    if ([configuredMoves objectForKey:@"minorAction"]) {
        //
        [(NSArray *)[configuredMoves objectForKey:@"minorAction"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull minorAction, NSUInteger idx, BOOL * _Nonnull stop) {
            // sub fumina node name
            SCNNode *fuminaNode = [self node:[minorAction objectForKey:@"name"]];
            [fuminaNode setHidden:NO];
            // create actions
            float preDelay = 0.0;
            SCNAction *preDelayAction;
            if ([minorAction objectForKey:@"preDelay"]) {
                preDelay = [[minorAction objectForKey:@"preDelay"] floatValue];
                preDelayAction = [SCNAction waitForDuration:preDelay];
            }
            
            NSMutableArray *cmActionSeq = [NSMutableArray new];
            NSArray *cmActions = [[minorAction objectForKey:@"seq"] componentsSeparatedByString:@"|"];
            //load designed actions
            [cmActions enumerateObjectsUsingBlock:^(NSString * _Nonnull cmActionSub, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *cmaCmd = [cmActionSub componentsSeparatedByString:@":"];
                NSString *cmd = [cmaCmd firstObject];
                float dur = [cmaCmd.lastObject floatValue];
                SCNAction *cmaAction;
                if ([cmd isEqualToString:@"wait"]) {
                    cmaAction = [SCNAction waitForDuration:dur];
                } if ([cmd isEqualToString:@"move"]) {
                    cmaAction = [SCNAction moveByX:0 y:0 z:0.07 duration:dur];
                }  if ([cmd isEqualToString:@"atk"]) {
                    cmaAction = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                        
                        // attack while rotating
                        CGFloat rotation = [self pointAngleFrom:node.presentationNode.worldPosition to:self.ARCamera.presentationNode.worldPosition];
                        SCNAction *rotateAction = [SCNAction rotateToX:node.eulerAngles.x y:node.eulerAngles.y z:InRadian(rotation) duration:0.25f shortestUnitArc:YES];
                        [node runAction:rotateAction];
                        
                        [self fumina:node didUseMove:@"fireBall"]; //bossFireBall
                    }];
                } if ([cmd isEqualToString:@"back"]) {
                    cmaAction = [SCNAction moveTo:SCNVector3Zero duration:dur];
                }
                // add them
                [cmActionSeq addObject:cmaAction];
            }];
            //
            SCNAction *attackAction = [SCNAction repeatActionForever:[SCNAction sequence:cmActionSeq]];
            if (preDelayAction) {
                //run after preDelayAction
                [fuminaNode runAction:preDelayAction completionHandler:^{
                    [fuminaNode runAction:attackAction];
                }];
            } else {
                //begin action immediately
                [fuminaNode runAction:attackAction];
            }
        }];
        
    } else {
        // if no minor action, just hide it to avoid mistake hit
        [_currentStage enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
            if ([child.name containsString:@"FuminaOW"]) {
                [child setHidden:YES];
            }
        }];
    }
    
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //combine and play actions
        if (actionSequece.count > 0) {
            SCNAction *seq = [SCNAction sequence:actionSequece];
            [self->_bossFumina runAction:[SCNAction repeatActionForever:seq]];
            [actionSequece removeAllObjects];
            actionSequece = nil; // deinit
        }
        
        // managing game base actions, start moving, or start rotating to a certain angle.
        if ([configuredMoves objectForKey:@"baseAction"]) {
            
            NSArray *baseAction = [[configuredMoves objectForKey:@"baseAction"] componentsSeparatedByString:@"|"];
            NSString *func = [baseAction firstObject];
            NSString *param = [baseAction lastObject];
            
            SCNAction *currentAction;
            
            // rotate clockWise
            if ([func isEqualToString:@"rotateC"]) {
                currentAction = [SCNAction rotateByX:0 y:0.5 z:0 duration:[param floatValue]];
            }
            // rotate counter clockWise
            if ([func isEqualToString:@"rotateCC"]) {
                currentAction = [SCNAction rotateByX:0 y:-0.5 z:0 duration:[param floatValue]];
            }
            // translate left right
            if ([func isEqualToString:@"move"]) {
                SCNAction *move = [SCNAction moveByX:0.5 y:0 z:0 duration:[param floatValue]];
                currentAction = [SCNAction sequence:@[move, [move reversedAction]]];
            }
            
            //always repeat action with reverse.
            [self->_currentStage runAction:[SCNAction repeatActionForever:currentAction]];
            
        }
        
        self->_canPlay = YES;
    });
    
}

// loading views
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _gameIsActive = false;
    _canPlay = false;
    _isMultiplayer = false;
    _isHost = false;
    _numberOfFumina = 0;
    _isPlaneDetectionMode = false;
    _isFuminaFiring = false;

    
    _dat = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"logic" ofType:@"plist"]];
    
    //pre-register animation to always run animation at needed time;
    _animations = @[[self loadSCNAnimation:@"atk" repeat:0 speed:1.0],[self loadSCNAnimation:@"upset" repeat:3 speed:2.0],[self loadSCNAnimation:@"atk" repeat:0 speed:1.5],[self loadSCNAnimation:@"upset" repeat:HUGE_VALF speed:0.5],[self loadSCNAnimation:@"paused" repeat:HUGE_VALF speed:1.0]];
    
    [_targetMarkDisplay setHidden:YES];
    
    [self.sceneView setContentScaleFactor:1.f];
    
    _sfxFire = [self prepareSFX:@"electro"];
    _fmnShout = [self prepareSFX:@"fuminaShout"];
    _mazyHit = [self prepareSFX:@"mazyHit"];
    
    // load and set scene from file
    SCNScene *scene = [SCNScene sceneNamed:@"World.dae"];
    self.sceneView.scene = scene;
    
    // load textures that will be used multiple_times throughout apps life cycle
    _reflect = [UIImage imageNamed:@"glass"];
    _alphaGradient = [UIImage imageNamed:@"alphaGradient"];
    _targetMarkA = [UIImage imageNamed:@"targetMark"];
    _targetMarkB = [UIImage imageNamed:@"targetMark2"];
    
    // load external class
    _dialogController = [self.storyboard instantiateViewControllerWithIdentifier:@"DialogController"];
    _dialogController.parent = self;
    _dialogController.dialogs = [_dat objectForKey:@"dialogs"];
     
    _ts = [self.storyboard instantiateViewControllerWithIdentifier:@"TitleScreen"];
    _ts.parent = self;
    
    [UIApplication sharedApplication].idleTimerDisabled = true;
    
    [self.view setTag:100]; // first time ever launching the app
    [self.sceneView setAlpha:0.01f];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.screenCenter = [self.view center];
    self.isInstructionalStage = false;
    
    // setup scene to prepare for game use
    _sceneView.delegate = self;
    _sceneView.scene.physicsWorld.contactDelegate = self;
    
    // sprite scene setup
    _spriteScene = [SKScene sceneWithSize:self.sceneView.frame.size];
    self.sceneView.overlaySKScene = _spriteScene;
    _spriteScene.delegate = self;
    [_spriteScene setPaused:NO];
    
    NSLog(@"Default ARWorld Camera %@", _sceneView.pointOfView);
    _ARCamera = _sceneView.pointOfView;
    //
    CABasicAnimation *scalePulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scalePulse.duration = 1.5;
    scalePulse.fromValue = [NSNumber numberWithFloat:0.5];
    scalePulse.toValue = [NSNumber numberWithFloat:1.5];
    scalePulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CAKeyframeAnimation *opacityPulse = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityPulse.values = @[@0,@1.0, @0.1, @0];
    opacityPulse.keyTimes = @[@0.0,@0.2,@0.8,@1.0];
    opacityPulse.duration = 1.5f;
    
    _pulseAnim = [CAAnimationGroup animation];
    [_pulseAnim setDuration:1.5];
    [_pulseAnim setRepeatCount:HUGE_VALF];
    [_pulseAnim setAutoreverses:NO];
    _pulseAnim.animations = @[scalePulse, opacityPulse];
    
    [_tapEllipse.layer addAnimation:_pulseAnim forKey:@"dialogPulse"];
    [_tapEllipse setHidden:YES];
    //
    _arIndicator = [self node:@"arDetectionIndicator"];
    //
    _blackBGNode = [self node:@"blackoutBG"];
    [_blackBGNode.geometry.firstMaterial setReadsFromDepthBuffer:NO];
    [_blackBGNode setRenderingOrder:-6];
    [_blackBGNode setOpacity:0.0];
    
    // register collisionCube to detect collision between camera and structures <avoids cheating by going through walls>
    _collisionCube = [_sceneView.scene.rootNode childNodeWithName:@"CollisionCube" recursively:YES];
    [_collisionCube setOpacity:0.0];
    _collisionCube.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:[SCNBox boxWithWidth:0.01 height:0.01 length:0.01 chamferRadius:0.0] options:nil]];
    _collisionCube.physicsBody.categoryBitMask = 2;
    //
    [_ARCamera addChildNode:_collisionCube];
    //
    [_systemDisplayLabel.layer setMasksToBounds:YES];
    [_systemDisplayLabel.layer setCornerRadius:8.0f];
    //
    [_hpDisplayView.layer setMasksToBounds:YES];
    [_hpDisplayView.layer setCornerRadius:20.0];
    [_hpBar.layer setCornerRadius:5.0];
    [_hpBar.layer setMasksToBounds:YES];
    //
    self.currentHP = 100;
    
    // remove unnecessary stages
    [self.sceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        if ([child.name containsString:@"Stage_"]) {
            if ([child.name isEqualToString:self.selectedStage]) {
                
                if ([child.name containsString:@"MultiPlayer_0"]) {
                    // this is a first stage requiring instruction for the player
                    self.isInstructionalStage = true;
                    //
                }
                
            } else {
                // remove unnecessary stages from parent node
                [child removeFromParentNode];
            }
        }
    }];
    
    [[self node:@"Intro"] removeFromParentNode];
    
    NSLog(@"current scene config %@", self.sceneView.scene.rootNode);
    
    // configure scene
    UIImage *texFire = [UIImage imageNamed:@"tex-fire"];
    UIImage *flameTransparent = [UIImage imageNamed:@"tex-flameTransparent"];
    UIColor *white = [UIColor whiteColor];
    
    [self.sceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        //
        if (child.light) {
            [child removeFromParentNode];
            [child setLight:nil];
        }
        if (child.geometry) {
            
            [child.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull mat, NSUInteger idx, BOOL * _Nonnull stop) {
                // set transparent
                if ([mat.name containsString:@"CChar"]) {
                    [mat.reflective setContents:self.reflect];
                    [mat.reflective setIntensity:0.3f];
                }
                if ([mat.name containsString:@"GradientTex"]) {
                    [mat.reflective setContents:self.reflect];
                    [mat.reflective setIntensity:0.1f];
                    [mat.emission setContents:white];
                    [mat.emission setIntensity:0.0];
                }
                // set single layer
                [mat setTransparencyMode:SCNTransparencyModeSingleLayer];
                //
                if ([child.name containsString:@"vfx"]) {
                    [mat setBlendMode:SCNBlendModeAdd];
                    [mat setDoubleSided:YES];
                    [mat setWritesToDepthBuffer:NO];
                    [child setRenderingOrder:3];
                    [child setOpacity:0.0];
                }
                //
                if ([mat.name containsString:@"LightAbsorption"]) {
                    [mat.diffuse setMappingChannel:0];
                    [mat.transparent setMappingChannel:1];
                    [mat.transparent setContents:[UIImage imageNamed:@"tex-flameTransparent"]];
                }
                if ([mat.name containsString:@"flame"]) {
                    [mat setBlendMode:SCNBlendModeAdd];
                    [mat setDoubleSided:YES];
                    [mat setWritesToDepthBuffer:NO];
                    [child setRenderingOrder:3];
                    [child setOpacity:0.0];
                    [mat.diffuse setMappingChannel:0];
                    [mat.diffuse setContents:texFire];
                    [mat.transparent setMappingChannel:1];
                    [mat.transparent setContents:flameTransparent];
                    NSString *cvShader = @"_geometry.texcoords[0].y += 2*u_time;"
                                        @"_geometry.texcoords[1].y -= 1.5*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
                if ([child.name containsString:@"xmove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].x += 1.5*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
                if ([child.name containsString:@"yMove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].y += 4*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
                if ([child.name containsString:@"ymMove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].y += 1*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
            }];
            // detect if geometry has
            if ([child.name containsString:@"struct"]) {
                child.physicsBody = [SCNPhysicsBody kinematicBody];
                child.physicsBody.categoryBitMask = 2;
                child.physicsBody.physicsShape = [SCNPhysicsShape shapeWithNode:child options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}];
            }
            if ([child.name containsString:@"Phase"]) {
                [child setHidden:YES];
            }
            
        }
        if ([child.name containsString:@"Sphere"]) {
            [child setOpacity:0.0];
        }
        // hide stage
        if ([child.name containsString:@"Stage"]) {
            [child setOpacity:0.0];
        }
        
        // hide clonable objects
        if ([child.name containsString:@"playerDetectFrustum"]) {
            [child setOpacity:0.0];
        }
        
        // configure cameras
        if (child.camera) {
            //HDR setting
            
            [child.camera setWantsHDR:YES];
            
            [child.camera setAverageGray:0.2];
            [child.camera setWhitePoint:1.0];
            
            //adaptation
            [child.camera setWantsExposureAdaptation:NO];
            
            //exposure
            [child.camera setMinimumExposure:0.0];
            [child.camera setMaximumExposure:0.5];
            [child.camera setExposureOffset:0.2];
            
            //bloom
            //[child.camera setBloomIntensity:0.2];
            //[child.camera setBloomThreshold:0.5];
            //[child.camera setBloomBlurRadius:3.5];
            
            //
            [child.camera setSaturation:1.1];
            [child.camera setContrast:0.1];
            
        }
        
    }];
    
    [_sky setRenderingOrder:-5];
    [[self node:@"Sphere2"] setRenderingOrder:-4];
    // configure sphere
    
    
    
    // add physics body to fireBall
    SCNNode *fireBall = [self node:@"fireBall"];
    fireBall.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:[SCNSphere sphereWithRadius:0.03f] options:nil]];
    fireBall.physicsBody.categoryBitMask = 2;
    [self addParticle:@"fireBall" toNode:fireBall];
    
    SCNNode *bossFireBall = [self node:@"bossFireBall"];
    bossFireBall.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:[SCNSphere sphereWithRadius:0.05f] options:nil]];
    bossFireBall.physicsBody.categoryBitMask = 2;
    [self addParticle:@"bossFireBall" toNode:bossFireBall];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    // start game session
    [_spriteScene setSize:self.view.bounds.size];
    
    [_screenBorder.layer setBorderColor:[UIColor colorWithRed:0.97 green:0.73 blue:0.0 alpha:1.0].CGColor];
    [_screenBorder.layer setBorderWidth:5.0];
    [_screenBorder.layer setCornerRadius:40];
    
    [_screenBorder setHidden:YES];
    //
    
}


// When game session prepares at this state
- (void)prepareToRunStage {
    
    _isMultiplayer = YES;
    
    // set to default ARCamera
    [self.sceneView setPointOfView:_ARCamera];
    
    // begin ARWorldTracking
    [self beginARWorldTracking];
    
    // preset parameters
    _playerLife = 5;
    NSInteger level = [[self.selectedStage componentsSeparatedByString:@"_"].lastObject integerValue];
    
    // find its sibling
    _currentStage = [self node:self.selectedStage];
    
    // prepare stage
    //[self.sceneView.scene.rootNode addChildNode:_currentStage];
    [_currentStage setEulerAngles:SCNVector3Make(InRadian(-90), 0, 0)];
    
    // spin AR Indicator
    SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:0.5 duration:(0.2)]];
    [rotate setTimingMode:SCNActionTimingModeEaseInEaseOut];
    [[_arIndicator childNodeWithName:@"theIndicator" recursively:YES] runAction:rotate forKey:@"spin"];
    
    _isPlaneDetectionMode = YES;
    
    if (_arIndicator.opacity < 1.0) {
        [_arIndicator setOpacity:1.0];
        [_arIndicator setScale:SCNVector3Make(1.0, 1.0, 1.0)];
    }
    
    [_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node setOpacity:1.0];
        [node setHidden:NO];
        //read data for all children nodes
        [node setPaused:NO];
        
        if ([node.name containsString:@"vfx"]) {
            [node setOpacity:0.0];
        }
        if ([node.name containsString:@"stage"]) {
            [node setOpacity:0.0];
        }
    }];
    
    _sky = [_sceneView.scene.rootNode childNodeWithName:@"Sphere" recursively:YES];
    
    // check if this stage is boss Stage
    if ([[_dat objectForKey:@"gameStage"] objectForKey:self.selectedStage]) {
        [[self node:@"Sphere2"] setOpacity:1.0];
        _stageConfig = [[_dat objectForKey:@"gameStage"] objectForKey:self.selectedStage];
        if ([_stageConfig objectForKey:@"isBoss"]) {
            _isBoss = YES;
        }
        if ([_stageConfig objectForKey:@"attackSequence"]) {
            _atkSeq = [_stageConfig objectForKey:@"attackSequence"];
        }
        // add boss to its worldPosition
        if ([_stageConfig objectForKey:@"bossPosition"]) {
            
            // load fumina from file as new instance
            NSString *bossFilePath = [NSString stringWithFormat:@"art.scnassets/%@.dae",(NSString *)[_stageConfig objectForKey:@"bossFileName"]];
            SCNScene *fuminaScene = [SCNScene sceneNamed:bossFilePath];
            _bossFumina = [fuminaScene.rootNode childNodeWithName:@"root" recursively:YES];
            [[_bossFumina childNodeWithName:@"tapCube" recursively:YES] setOpacity:0.0];
            
            // set its position
            SCNNode *bossAxis = [self node:(NSString *)[_stageConfig objectForKey:@"bossPosition"]];
            NSLog(@"bossAxis added <setup> %@", bossAxis);
            
            [bossAxis addChildNode:_bossFumina]; //add
            [_bossFumina setEulerAngles:SCNVector3Make(InRadian(90), _bossFumina.eulerAngles.y, _bossFumina.eulerAngles.z)]; //Y-UP
            [_bossFumina setScale:SCNVector3Make(0.04, 0.04, 0.04)];
            [_bossFumina setCastsShadow:YES];
            
            //go through preset.
            [_bossFumina enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                //
                if (child.geometry) {
                    [child.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull mat, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([mat.name containsString:@"vfx"]) {
                            [mat setBlendMode:SCNBlendModeAdd];
                            [mat setDoubleSided:YES];
                            [mat setWritesToDepthBuffer:NO];
                            [child setRenderingOrder:3];
                            [child setOpacity:0.0];
                        }
                    }];
                }
            }];
            
        }
        
        if ([_stageConfig objectForKey:@"rendering"]) {
            NSArray *renderings = [_stageConfig objectForKey:@"rendering"];
            [renderings enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull cmd, NSUInteger idx, BOOL * _Nonnull stop) {
                
                SCNNode *node = [self node:[cmd objectForKey:@"node"]];
                
                if ([cmd objectForKey:@"addParticle"]) {
                    [node removeAllParticleSystems]; // only one particle at the time
                    NSString *particleName = [cmd objectForKey:@"addParticle"];
                    [self addParticle:particleName toNode:node];
                }
                if ([cmd objectForKey:@"particleBirthRate"]) {
                    NSInteger particleBRate = [[cmd objectForKey:@"particleBirthRate"] integerValue];
                    [node.particleSystems.firstObject setBirthRate:particleBRate];
                }
                
            }];
        }
    }
    
    // count number of fuminas
    _numberOfFuminasTapped = 0; //applies for multiplayer mode
    _currentTappedFuminas = 0;
    _numberOfFumina = 0;
    
    // pre configurate the stage
    [_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if ([node.name containsString:@"Fumina"]) {
            // give Fumina an identifier : e.g fmn-1-0
            [node setAccessibilityLabel:[NSString stringWithFormat:@"fmn-%ld-%ld",level,self->_numberOfFumina]];
            NSLog(@"Fumina identified %@", node.accessibilityLabel);
            //
            [node setOpacity:1.0];
            // find fumina that requires frustum for player detection
            if ([node.name containsString:@"fireBall"]) {
                SCNNode *frustum = [self copyNode:[self node:@"playerDetectFrustum"]];
                [frustum setName:@"frustumFMN"];
                [frustum setPosition:SCNVector3Zero];
                // add physics body
                frustum.physicsBody = [SCNPhysicsBody kinematicBody];
                frustum.physicsBody.categoryBitMask = 2;
                frustum.physicsBody.physicsShape = [SCNPhysicsShape shapeWithNode:frustum options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}];
                //add to fumina's position
                [node addChildNode:frustum];
            }
            //
            self->_numberOfFumina++;
        }
        // move gears in this state <activate gear>
        if ([node.name containsString:@"zGearCW"] && node.hasActions == NO) {
            CGFloat scale = (node.scale.x+node.scale.y+node.scale.z)/3;
            if ([node.parentNode.name containsString:@"zGear"]) {
                scale = scale*0.5;
            }
            SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:0.5 duration:(1.0)*scale]];
            [node runAction:rotate];
        } if ([node.name containsString:@"zGearCC"] && node.hasActions == NO) {
            CGFloat scale = (node.scale.x+node.scale.y+node.scale.z)/3;
            SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:-0.5 duration:(1.0)*scale]];
            [node runAction:rotate];
        }
        // hide phases
        if ([node.name containsString:@"structPhase"]) {
            [node setOpacity:0.0];
        }
    }];
    
    if (_isBoss == YES) {
        _numberOfFumina--;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //
        __block ARAnchor *stageAnchor;
        
        [self.arCongifuration.initialWorldMap.anchors enumerateObjectsUsingBlock:^(ARAnchor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name containsString:@"stage"]) {
                stageAnchor = obj;
            }
        }];
        
        if (stageAnchor) {
            
            self.arIndicator.simdTransform = stageAnchor.transform;
            [self.arIndicator setEulerAngles:SCNVector3Make(InRadian(-90), 0, 0)];
            self.playerDefinedAnchor = stageAnchor;
            
            // go straight to game if has stage
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.isPlaneDetectionMode = NO;
                [self.arIndicator setHidden:NO];// display
                [[self.arIndicator childNodeWithName:@"theIndicator" recursively:YES] removeAllActions];
                
                SCNAction *jump = [SCNAction moveByX:0 y:0.15 z:0 duration:0.25f];
                [jump setTimingMode:SCNActionTimingModeEaseOut];
                [self.view setTag:1];
                
                [self playSFX:@"positionConfirm"];
                [self.arIndicator runAction:[SCNAction sequence:@[jump, [jump reversedAction]]] completionHandler:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.view setTag:2];
                        [self displayOpc];
                    });
                }];
                
            });
            
        } else {
            [self.parent playAudio:@"instructionTheme"];
            [self.dialogController skNodeAction:[[self.dat objectForKey:@"spriteSequence"] objectForKey:@"displayARConfig"]];
        }
        
        //
        [self.sky setOpacity:0.0];
        [UIView animateWithDuration:0.9f animations:^{
            [self.sceneView setAlpha:1.0f];
            //NSLog(@"currentStage %@ alpha %f hidden %d", self->_currentStage, self->_currentStage.opacity, self->_currentStage.isHidden);
            self.view.tag = 10;
        }];
        //
    });
    
}

- (void)beginARWorldTracking {
    // this method should only run once.
    if (!self.arCongifuration) {
        //
        self.arCongifuration = [ARWorldTrackingConfiguration new];
        //
    }
    if ([self.parent userWorldMap] && [self.parent userAnchor]) {
        //
        [self.parent setUserWorldMap:nil];
        [self.parent setUserAnchor:nil];
        //
    }
    //
    [self.arCongifuration setPlaneDetection:ARPlaneDetectionHorizontal];
    [self.sceneView.session runWithConfiguration:self.arCongifuration];
    //
    [_sky setOpacity:0.0];
    [_sky setHidden:YES];
    [_currentStage setOpacity:0.0];
    [_currentStage setHidden:YES];
    [self.sceneView setDebugOptions:ARSCNDebugOptionShowFeaturePoints];
    //
}

- (void)setSelectedStage:(NSString *)world :(NSInteger)level {
    
    // preset
    _currentStage = nil;
    _playerLife = 5;
    
    // hide all stages root
    
    //
    NSString *selectedStage = [NSString stringWithFormat:@"Stage_%@_%ld", world, (long)level];
    _currentStage = [self node:selectedStage];
    [self.sceneView.scene.rootNode addChildNode:_currentStage];
    [_currentStage setEulerAngles:SCNVector3Make(InRadian(-90), 0, 0)];
    
    //
    SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:0.5 duration:(0.2)]];
    [rotate setTimingMode:SCNActionTimingModeEaseInEaseOut];
    [[_arIndicator childNodeWithName:@"theIndicator" recursively:YES] runAction:rotate forKey:@"spin"];
    //
    _isPlaneDetectionMode = YES;
    
    [_dialogController skNodeAction:[[_dat objectForKey:@"spriteSequence"] objectForKey:@"displayARConfig"]];
    if (_arIndicator.opacity < 1.0) {
        [_arIndicator setOpacity:1.0];
        [_arIndicator setScale:SCNVector3Make(1.0, 1.0, 1.0)];
    }
    //
    [_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node setOpacity:1.0];
        [node setHidden:NO];
        //read data for all children nodes
        //NSLog(@"currentStage %@ <%@>", node.name, node.description);
        [node setPaused:NO];
        
        if ([node.name containsString:@"vfx"]) {
            [node setOpacity:0.0];
        }
        if ([node.name containsString:@"stage"]) {
            [node setOpacity:0.0];
        }
        
    }];
    
    // check if this stage is boss Stage
    if ([[_dat objectForKey:@"gameStage"] objectForKey:selectedStage]) {
        NSLog(@"configured game stage %@", selectedStage);
        _stageConfig = [[_dat objectForKey:@"gameStage"] objectForKey:selectedStage];
        if ([_stageConfig objectForKey:@"isBoss"]) {
            _isBoss = YES;
        }
        if ([_stageConfig objectForKey:@"attackSequence"]) {
            _atkSeq = [_stageConfig objectForKey:@"attackSequence"];
        }
        // add boss to its worldPosition
        if ([_stageConfig objectForKey:@"bossPosition"]) {
            
            // load fumina from file as new instance
            NSString *bossFilePath = [NSString stringWithFormat:@"art.scnassets/%@.dae",(NSString *)[_stageConfig objectForKey:@"bossFileName"]];
            SCNScene *fuminaScene = [SCNScene sceneNamed:bossFilePath];
            _bossFumina = [fuminaScene.rootNode childNodeWithName:@"root" recursively:YES];
            [[_bossFumina childNodeWithName:@"tapCube" recursively:YES] setOpacity:0.0];
            
            // set its position
            SCNNode *bossAxis = [self node:(NSString *)[_stageConfig objectForKey:@"bossPosition"]];
            
            NSLog(@"bossAxis added <setup> %@", bossAxis);
            
            [bossAxis addChildNode:_bossFumina]; //add
            [_bossFumina setEulerAngles:SCNVector3Make(InRadian(90), _bossFumina.eulerAngles.y, _bossFumina.eulerAngles.z)]; //Y-UP
            [_bossFumina setScale:SCNVector3Make(0.04, 0.04, 0.04)];
            [_bossFumina setCastsShadow:YES];
            
            //go through preset.
            [_bossFumina enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                //
                if (child.geometry) {
                    [child.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull mat, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([mat.name containsString:@"vfx"]) {
                            [mat setBlendMode:SCNBlendModeAdd];
                            [mat setDoubleSided:YES];
                            [mat setWritesToDepthBuffer:NO];
                            [child setRenderingOrder:3];
                            [child setOpacity:0.0];
                        }
                    }];
                }
            }];
        }
        
        if ([_stageConfig objectForKey:@"rendering"]) {
            NSArray *renderings = [_stageConfig objectForKey:@"rendering"];
            [renderings enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull cmd, NSUInteger idx, BOOL * _Nonnull stop) {
                
                SCNNode *node = [self node:[cmd objectForKey:@"node"]];
                
                if ([cmd objectForKey:@"addParticle"]) {
                    [node removeAllParticleSystems]; // only one particle at the time
                    NSString *particleName = [cmd objectForKey:@"addParticle"];
                    [self addParticle:particleName toNode:node];
                }
                if ([cmd objectForKey:@"particleBirthRate"]) {
                    NSInteger particleBRate = [[cmd objectForKey:@"particleBirthRate"] integerValue];
                    [node.particleSystems.firstObject setBirthRate:particleBRate];
                }
                
            }];
        }
    }
    
    // count number of fuminas
    _numberOfFuminasTapped = 0; //applies for multiplayer mode
    _currentTappedFuminas = 0;
    _numberOfFumina = 0;
    
    // pre configurate the stage
    [_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if ([node.name containsString:@"Fumina"]) {
            // give Fumina an identifier : e.g fmn-1-0
            [node setAccessibilityLabel:[NSString stringWithFormat:@"fmn-%ld-%ld",level,self->_numberOfFumina]];
            NSLog(@"Fumina identified %@", node.accessibilityLabel);
            //
            [node setOpacity:1.0];
            // find fumina that requires frustum for player detection
            if ([node.name containsString:@"fireBall"]) {
                SCNNode *frustum = [self copyNode:[self node:@"playerDetectFrustum"]];
                [frustum setName:@"frustumFMN"];
                [frustum setPosition:SCNVector3Zero];
                // add physics body
                frustum.physicsBody = [SCNPhysicsBody kinematicBody];
                frustum.physicsBody.categoryBitMask = 2;
                frustum.physicsBody.physicsShape = [SCNPhysicsShape shapeWithNode:frustum options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}];
                //add to fumina's position
                [node addChildNode:frustum];
            }
            //
            self->_numberOfFumina++;
        }
        // move gears in this state <activate gear>
        if ([node.name containsString:@"zGearCW"] && node.hasActions == NO) {
            CGFloat scale = (node.scale.x+node.scale.y+node.scale.z)/3;
            SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:0.5 duration:(1.0)*scale]];
            [node runAction:rotate];
        } if ([node.name containsString:@"zGearCC"] && node.hasActions == NO) {
            CGFloat scale = (node.scale.x+node.scale.y+node.scale.z)/3;
            SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:-0.5 duration:(1.0)*scale]];
            [node runAction:rotate];
        }
        // hide phases
        if ([node.name containsString:@"structPhase"]) {
            [node setOpacity:0.0];
        }
    }];
    
    if (_isBoss == YES) {
        _numberOfFumina--;
        if (_numberOfFumina == 0) {
            _numberOfFumina = 1;
        }
    }
    
    NSLog(@"setSelectedStage passed");
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if (self.view.tag == 10) {
        // add set its position to scene
        ARHitTestResult *hitTestResult = [self.sceneView hitTest:self.screenCenter types:ARHitTestResultTypeExistingPlaneUsingGeometry|ARHitTestResultTypeEstimatedHorizontalPlane].firstObject;
        if (!hitTestResult) {
            return;
        }
        
        //let the triangle face player
        AudioServicesPlaySystemSound(1519);
        [_tapEllipse setHidden:YES];
        [_tapEllipse.layer removeAllAnimations];
        [_tapEllipse setImage:NULL];
        [_tapEllipse removeFromSuperview];
        
        [[self.arIndicator childNodeWithName:@"theIndicator" recursively:YES] removeAllActions];
        [[self.arIndicator childNodeWithName:@"theIndicator" recursively:YES] setEulerAngles:SCNVector3Make(0, 0, 0)];
        CGFloat angle = [self pointAngleFrom:_arIndicator.position to:_ARCamera.position];
        [_arIndicator setEulerAngles:SCNVector3Make(_arIndicator.eulerAngles.x, GLKMathDegreesToRadians(angle), _arIndicator.eulerAngles.z)];
        
        //
        _isPlaneDetectionMode = NO;
        
        // remove device move instruction
        [_dialogController deleteSKNode:[_dialogController skNode:@"deviceMove"]];
        
        //
        [self playSFX:@"positionConfirm"];
        
        // jump indicator
        [[_arIndicator childNodeWithName:@"theIndicator" recursively:YES] removeAllActions];
        SCNAction *jump = [SCNAction moveByX:0 y:0.15 z:0 duration:0.25f];
        [jump setTimingMode:SCNActionTimingModeEaseOut];
        
        //
        [_arIndicator runAction:[SCNAction sequence:@[jump, [jump reversedAction]]] completionHandler:^{
            ARAnchor *anchor = [[ARAnchor alloc] initWithName:@"stage" transform:self.arIndicator.simdTransform];
            [self.sceneView.session addAnchor:anchor];
        }];
        
    } else {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (self.gameIsActive == YES && self.canPlay == YES) {
                
                // animate targetMarkDisplay
                self.targetMarkDisplay.transform = CGAffineTransformMakeScale(1.5, 1.5);
                
                [UIView animateWithDuration:0.5 animations:^{
                    self.targetMarkDisplay.transform = CGAffineTransformMakeScale(1.0, 1.0);
                }];
                
                NSArray *tapHitResults = [self.sceneView hitTest:self.screenCenter options:@{SCNHitTestOptionSearchMode : @0}];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    
                    [self.spriteScene runAction:self.sfxFire];
                    
                });
                
                [tapHitResults enumerateObjectsUsingBlock:^(SCNHitTestResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    //
                    if ([obj.node.name containsString:@"Fumina"] && obj.node.presentationNode.opacity == 1.0) {
                        
                        // haptic feedback
                        AudioServicesPlaySystemSound(1519);
                        
                        if ([obj.node.name containsString:@"dSpot"]) {
                            
                            [self.dialogController deleteSKNode:[self.dialogController skNode:@"target"]];
                            self.currentTappedFuminas = 0;
                            self.canPlay = NO;
                            // hurt boss fumina for few seconds,
                            [self.bossFumina removeAllActions];
                            [self.currentStage removeAllActions];
                            [self playSFX:@"bossHurt"];
                            
                            [self.bossFumina addAnimation:self->_animations[1] forKey:@"upset"];
                            
                            [self.currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                                if ([node.name containsString:@"Fumina"]) {
                                    [node removeAllActions];
                                    [SCNTransaction begin];
                                    [SCNTransaction setCompletionBlock:^{
                                        [node setOpacity:1.0];
                                    }];
                                    [SCNTransaction setAnimationDuration:0.3f];
                                    [node setOpacity:0.0];
                                    [node setPosition:SCNVector3Zero];
                                    [SCNTransaction commit];
                                }
                            }];
                            
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                
                                //[self.sceneView.pointOfView removeAnimationForKey:@"shake" blendOutDuration:1.0f];
                                self.bossBattleCount++;
                                
                                NSDictionary *battleData = [self->_atkSeq objectAtIndex:self->_bossBattleCount];
                                if ([battleData objectForKey:@"missionComplete"]) {
                                    
                                    // run dialogs
                                    NSString *dialogId = [battleData objectForKey:@"missionComplete"];
                                    [self.dialogController run:dialogId];
                                    
                                } else {
                                    // continue
                                    
                                    [self.bossFumina runAction:[SCNAction moveTo:SCNVector3Zero duration:0.2f] completionHandler:^{
                                        // boss fumina will hide, and show fire
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            // fire explodes all of a sudden
                                            [self playSFX:@"burnFire"];
                                            [self.currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                                                if ([node.name containsString:@"fireNode"]) {
                                                    [node setOpacity:1.0];
                                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                        [SCNTransaction begin];
                                                        [SCNTransaction setAnimationDuration:0.7f];
                                                        [node setOpacity:0.0];
                                                        [SCNTransaction commit];
                                                    });
                                                }
                                            }];
                                            // bring to standard position/rotation
                                            SCNNode *stdTransform = [self node:@"appearanceAnchor"];
                                            SCNAction *aBlock = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                                                [SCNTransaction begin];
                                                [SCNTransaction setAnimationDuration:1.0f];
                                                [node setTransform:stdTransform.transform];
                                                [node setEulerAngles:SCNVector3Make(InRadian(-90), 0, 0)];
                                                [SCNTransaction commit];
                                            }];
                                            [self.currentStage runAction:aBlock];
                                            
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                [self bossFuminaMoves:battleData];
                                            });
                                        });
                                    }];
                                    
                                }
                                
                                
                            });
                            
                        } else {
                            //non-boss stage
                            [self playSFX:@"hit"];
                            [self warpNode:obj.node];
                            [self didTapSubject];
                        }
                        
                        *stop = YES;
                    } else if ([obj.node.name containsString:@"fireBall"] && obj.node.presentationNode.opacity == 1.0) {
                        //erase fireball at runtime
                        [self.spriteScene runAction:self.mazyHit];
                        
                        [obj.node setAccessibilityValue:nil];
                        
                        [SCNTransaction begin];
                        [SCNTransaction setAnimationDuration:0.3f];
                        [obj.node setScale:SCNVector3Make(2.0, 2.0, 2.0)];
                        [obj.node setOpacity:0.0];
                        [SCNTransaction commit];
                        
                    }
                    
                    
                }];
            }
        });
        
    }
    //
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)handleGameOver:(NSString *)moveName {
    
    if (_canPlay == false) {
        return;
    }
    
    if (_isDamaged == true) {
        return;
    }
    
    _isDamaged = true;
    
    // get damage parameters
    if (_currentHP >= 100) {
        self.currentHP = 100;
    }
    
    float dmgVal = [[[[_dat objectForKey:@"param"] objectForKey:moveName] objectForKey:@"damage"] floatValue];
    _currentHP -= dmgVal;
    float val = self.currentHP/100.00f;
    [self.hpBar setProgress:val animated:YES];
    NSLog(@"take damage %f <%f> val %f", _currentHP,dmgVal, val);
    
    [self.hpBar setProgressTintColor:self.hpBar.tintColor];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.hpBar setProgressTintColor:self.hpBar.backgroundColor];
    });
    
    [self playSFX:@"damage"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isDamaged = false;
    });
    
    [_glassOverlay setAlpha:1.0];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.5 animations:^{
            [self.glassOverlay setAlpha:0.0];
        }];
    });
    
    AudioServicesPlaySystemSound(1520);
    
    //check life first
    if (_currentHP > 0) {
        //animate crack, reduce life
    } else {
        
        // HP is Zero. gAme over!
        [self.pauseBtn setEnabled:NO];
        
        _gameIsActive = NO;
        
        [self.parent fadeAudio:nil fadeDuration:0.3f];
        [self.view setBackgroundColor:[UIColor blackColor]];
        [self.targetMarkDisplay setHidden:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self playSFX:@"failed"];
            [self.gameoverDisp setHidden:NO];
            [self.playerLifeLabel setHidden:YES];
        });

        //
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self handleExitGame:NO];
        });
    }
}

- (void)handleExitGame:(BOOL)levelUp {
    
    [self.view setBackgroundColor:[UIColor blackColor]];

    // stop gears
    [_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node removeAllActions];
    }];
    // at this moment, delete entire currentStage and actions
    [self deleteNode:_currentStage];
    [self.sceneView.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node removeAllActions];
    }];
    //delete boss
    if (_bossFumina) {
        [self deleteNode:_bossFumina];
        _bossFumina = nil;
    }
    
    // fade out and move to next level
    [UIView animateWithDuration:0.5 animations:^{
        [self.sceneView setAlpha:0.01];
    } completion:^(BOOL finished) {
        
        // save current worldmap state
        [self.sceneView.session getCurrentWorldMapWithCompletionHandler:^(ARWorldMap * _Nullable worldMap, NSError * _Nullable error) {
            if (worldMap) {
                self->_currentWorldMap = worldMap;
            }
        }];
        
        // pause and move next
        [self.sceneView.session pause];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //exit
            [self.gameoverDisp setHidden:YES];
            [self goBackToMenuWithLevelUp:levelUp];
            
        });
    }];
    
}


// タップしたら、フミナを消す
- (void)didTapSubject {
    
    NSLog(@"did tap suject");
    
    // for boss stage
    if (_isBoss == YES) {
        if (_currentTappedFuminas < _numberOfFumina) {
            _currentTappedFuminas++; // applies to all peers regardless of player
        }
        
        if (_currentTappedFuminas == _numberOfFumina) {
            
            [self.pauseBtn setEnabled:NO];
            
            _currentTappedFuminas = 0;// reset to recycle fumina count
            _canPlay = NO;
            
            NSDictionary *battleData = [self->_atkSeq objectAtIndex:self.bossBattleCount+1];
            if ([battleData objectForKey:@"missionComplete"]) {
                //end of game;
                self.gameIsActive = NO;
            }
            
            //
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                // fire explodes all of a sudden //
                [self playSFX:@"burnFire"];
                [self->_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                    if ([node.name containsString:@"fireNode"]) {
                        [node setOpacity:1.0];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [SCNTransaction begin];
                            [SCNTransaction setAnimationDuration:0.7f];
                            [node setOpacity:0.0];
                            [SCNTransaction commit];
                        });
                    }
                }];
                
                // bring to standard position/rotation
                SCNNode *stdTransform = [self node:@"appearanceAnchor"];
                
                SCNAction *aBlock = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                    
                    // get rotation value that faces player's position
                    CGFloat rotation = [self pointAngleFrom:self.currentStage.presentationNode.worldPosition to:self.ARCamera.presentationNode.worldPosition];
                    [SCNTransaction begin];
                    [SCNTransaction setAnimationDuration:1.0f];
                    [node setTransform:stdTransform.transform];
                    [node setEulerAngles:SCNVector3Make(InRadian(-90), InRadian(rotation), 0)];
                    [SCNTransaction commit];
                    
                    
                }];
                
                [self.currentStage runAction:aBlock];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{                    //
                    self->_bossBattleCount++;
                    NSDictionary *battleData = [self->_atkSeq objectAtIndex:self->_bossBattleCount];
                    if ([battleData objectForKey:@"missionComplete"]) {
                        //end of game;
                        [self.parent fadeAudio:@"defeatBoss" fadeDuration:0.35f];
                        [self displayGameCreditAfterGameCompletion];
                    } else {
                        // continue
                        [self bossFuminaMoves:battleData];
                    }
                });
            });
        }
    } else {
        // for non boss, clear stage based on fumina count
        if (_currentTappedFuminas < _numberOfFumina) {
            _currentTappedFuminas++; // applies to all peers regardless of player
        }
        if (_currentTappedFuminas == _numberOfFumina) {
            // When all Fuminas have been cleared
            
            [self.pauseBtn setEnabled:NO];
            
            [self.parent fadeAudio:nil fadeDuration:0.3f];
            _gameIsActive = NO;
            [self.targetMarkDisplay setHidden:YES];
            [self.playerLifeLabel setHidden:YES];
            [self.view setBackgroundColor:[UIColor blackColor]];
            // stop gears
            [_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                [node removeAllActions];
            }];
            // stop game
            
            SCNNode *vortexAxis = [self node:@"appearanceAnchor"];
            SCNNode *vortex = [self node:@"Circle-vfx-xmove-1"];
            SCNNode *sun = [self node:@"shineSun-vfx"];
            
            // Let stage shine away
            [vortexAxis setTransform:_currentStage.transform];
            [vortex setScale:SCNVector3Make(5.0, 5.0, 5.0)];
            [sun setScale:SCNVector3Make(0.3, 0.3, 0.3)];
            
            //1. light will scale up immediately
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self playSFX:@"stageRetract"];
                
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:0.5f];
                [sun setScale:SCNVector3Make(4.5, 4.5, 4.5)];
                [sun setOpacity:0.5];
                [SCNTransaction commit];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SCNTransaction begin];
                    [SCNTransaction setAnimationDuration:2.0f];
                    [vortex setOpacity:1.0];
                    [SCNTransaction commit];
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SCNTransaction begin];
                    [SCNTransaction setAnimationDuration:2.0f];
                    [self.currentStage enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                        [child.geometry.firstMaterial.emission setIntensity:1.0];
                    }];
                    [SCNTransaction commit];
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SCNTransaction begin];
                    [SCNTransaction setAnimationDuration:0.7];
                    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
                    [self.currentStage setScale:SCNVector3Make(0.0, 0.0, 0.0)];
                    [self.currentStage setEulerAngles:SCNVector3Make(self.currentStage.eulerAngles.x, InRadian(900), self.currentStage.eulerAngles.z)];
                    [self.currentStage setOpacity:0.0];
                    [sun setOpacity:0.0];
                    [sun setScale:SCNVector3Zero];
                    [SCNTransaction commit];
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SCNTransaction begin];
                    [SCNTransaction setAnimationDuration:0.8];
                    [vortex setOpacity:0.0];
                    [vortex setScale:SCNVector3Make(0.5, 0.5, 0.5)];
                    [self.sky setOpacity:0.0];
                    [SCNTransaction commit];
                });
            });
            
            //
            [self.gameoverDisp setText:@"Mission Cleared"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self playSFX:@"cleared"];
                [self.gameoverDisp setHidden:NO];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showPostGameOptions];
            });
        
        }
        //
    }
}

// Anim where fumina got stunned
- (void)warpNode:(SCNNode *)node {
    
    // shout!
    [self playSFX:@"fuminaHit"];
    [self.spriteScene runAction:self.mazyHit];
    
    [node removeAllActions];
    
    // change facial expression momentarily
    SCNMaterial *face = [node.geometry materialWithName:@"Face"];
    [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.5, 0.0)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.0, 0.0)];
    });
    
    [SCNTransaction begin];
    [SCNTransaction setCompletionBlock:^{
        if (self->_isBoss == YES) {
            [node setOpacity:1.0];
        }
    }];
    [SCNTransaction setAnimationDuration:0.3f];
    [node setOpacity:0.0];
    if (_isBoss == YES) {
        [node setPosition:SCNVector3Zero];
    } else {
        [node setScale:SCNVector3Make(2.0, 2.0, 2.0)];
    }
    [SCNTransaction commit];
    //
    
    
}

- (void)showPostGameOptions {
    
    // at this moment, delete entire currentStage and actions
    [self deleteNode:_currentStage];
    [self.sceneView.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node removeAllActions];
    }];
    _gameIsActive = NO;
    //
    if (_bossFumina) {
        [self deleteNode:_bossFumina];
        _bossFumina = nil;
    }
    //gameOver goBack to mainMenu
    [UIView animateWithDuration:1.0 animations:^{
        [self.sceneView setAlpha:0.0];
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:^{
                [self.parent mpFuncBackToMenu:YES];
            }];
        });
    }];
}

- (void)displayGameCreditAfterGameCompletion {
    
    // at this moment, delete entire currentStage and actions
    [self deleteNode:_currentStage];
    [self.sceneView.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node removeAllActions];
    }];
    _gameIsActive = NO;
    
    // tell gameCenter what boss level has acheived (gcIdentifier)
    //NSString *gcIdentifier = [[[self.dat objectForKey:@"gameStage"] objectForKey:self.selectedStage] objectForKey:@"gcIdentifier"];
     
    if (_bossFumina) {
        [self deleteNode:_bossFumina];
        _bossFumina = nil;
    }
    //gameOver goBack to mainMenu
    [UIView animateWithDuration:0.8 animations:^{
        [self.sceneView setAlpha:0.0];
    } completion:^(BOOL finished) {
        
        PostGameOptions *pgo = [self.storyboard instantiateViewControllerWithIdentifier:@"PostGameOptions"];
        pgo.parent = self;
        if ([[[self.dat objectForKey:@"gameStage"] objectForKey:self.selectedStage] objectForKey:@"lastBoss"]) {
            [pgo setIsLastBoss:YES];
            [self.parent fadeAudio:@"defeatBoss" fadeDuration:0.0f];
        } else {
            [pgo setIsLastBoss:NO];
            [self playSFX:@"LevelCompleteSfx"];
        }
        [self presentViewController:pgo animated:YES completion:nil];
        
    }];
}

- (void)goBackToMenuWithLevelUp:(BOOL)levelUp {
    
    [UIView animateWithDuration:1.0 animations:^{
        [self.sceneView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:YES completion:^{
            // remove all nodes to clearup memory
            [self.parent mpFuncBackToMenu:levelUp];
        }];
    }];
    
}


- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([anchor.name hasPrefix:@"stage"] && self.view.tag == 10) {
            [self.view setTag:2];
            self.playerDefinedAnchor = anchor;
            [self displayOpc];
        }
    });
    
}


// See if user is satisfied with the current position <if not, allow position replacement>
- (void)displayOpc {
    //
    [self.objectPosConfirmDisp setHidden:NO];
    [self.pauseBtn setEnabled:NO];
    //
}

- (IBAction)opcAction:(id)sender {
    
    // hide opc
    [_objectPosConfirmDisp setHidden:YES];
    
    if (sender == _opcYes) {
        
        [self.view setTag:1];
        [self animateTemporalOpeningAt:SCNMatrix4FromMat4(_playerDefinedAnchor.transform)];
        [self.parent setUserAnchor:_playerDefinedAnchor];
        [self.arCongifuration setPlaneDetection:ARPlaneDetectionNone];
        
    } else {
        //clear worldMap
        [self.parent setUserWorldMap:nil];
        //remove anchor
        [self.sceneView.session removeAnchor:_playerDefinedAnchor];
        _playerDefinedAnchor = nil;
        
        // reset position
        self.planeDetected = NO;
        self.isPlaneDetectionMode = YES;
        [self beginARWorldTracking];
        
        if ([_tapEllipse.layer animationForKey:@"dialogPulse"]) {
            [_tapEllipse.layer addAnimation:_pulseAnim forKey:@"dialogPulse"];
        }
        
        // spin AR Indicator
        SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:0.5 duration:(0.2)]];
        [rotate setTimingMode:SCNActionTimingModeEaseInEaseOut];
        [[_arIndicator childNodeWithName:@"theIndicator" recursively:YES] runAction:rotate forKey:@"spin"];
        //
        [self.dialogController skNodeAction:[[self.dat objectForKey:@"spriteSequence"] objectForKey:@"displayARConfig"]];
        self.view.tag = 10;
    }

}


// this is where game session begins with great animation
- (void)animateTemporalOpeningAt:(SCNMatrix4)transform {
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    if (![self.parent userWorldMap]) {
        [self.sceneView.session getCurrentWorldMapWithCompletionHandler:^(ARWorldMap * _Nullable worldMap, NSError * _Nullable error) {
            [self.parent setUserWorldMap:worldMap]; // register current worldMap
        }];
    }
    
    // initial setup
    SCNNode *vortexAxis = [self node:@"appearanceAnchor"];
    SCNNode *vortex = [self node:@"Circle-vfx-xmove-1"];
    SCNNode *sun = [self node:@"shineSun-vfx"];
    
    [self.parent fadeAudio:nil fadeDuration:1.25f];
    
    [vortexAxis setTransform:transform];
    
    [vortex setScale:SCNVector3Make(0.0, 0.0, 0.0)];
    [vortex setOpacity:0.0];
    [sun setScale:SCNVector3Make(0.2, 0.2, 0.2)];
    [sun setOpacity:0.0];
    
    // position stage
    [_currentStage setOpacity:0.0];
    [_currentStage setHidden:NO];
    [_currentStage setTransform:transform];
    
    // let the stage face towards camera
    CGFloat angle = [self pointAngleFrom:_currentStage.position to:_ARCamera.position];
    
    [_currentStage setEulerAngles:SCNVector3Make(InRadian(-90), GLKMathDegreesToRadians(angle), 0)];
    [_sky setEulerAngles:SCNVector3Make(InRadian(-90), GLKMathDegreesToRadians(angle), 0)];

    NSLog(@"angle %f <inRadian> %f", angle, GLKMathDegreesToRadians(angle));
    
    [self playSFX:@"temporalAppearanceSFX"];
    
    //1. Vortex appears
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:3.4f];
    [_blackBGNode setOpacity:1.0];
    [vortex setOpacity:1.0];
    [vortex setScale:SCNVector3Make(1.0, 1.0, 1.0)];
    [SCNTransaction commit];
    
    //2. Light fades in
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:4.0f];
        [sun setOpacity:1.0];
        [sun setScale:SCNVector3Make(3.5, 3.5, 3.5)];
        [SCNTransaction commit];
    });
    
    //3. Scene fades out
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.8 animations:^{
            [self.sceneView setAlpha:0.01];
        } completion:^(BOOL finished) {
            //
            [vortex setOpacity:0.0];
            [self.arIndicator setOpacity:0.0];
            [sun setOpacity:0.0];
            if (self->_bossFumina) {
                //ボス・ステージ
                [self->_blackBGNode setOpacity:0.0];
                [self->_sky setHidden:NO];
                [self->_sky setOpacity:1.0];
            } else {
                [self->_blackBGNode setOpacity:0.0];
                [self->_sky setOpacity:0.3];
            }
            //
            [self.sceneView setDebugOptions:SCNDebugOptionNone];
            //
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [UIView animateWithDuration:0.4f animations:^{
                    [self.sceneView setAlpha:1.0];
                } completion:^(BOOL finished) {
                    
                    // a short state when screen is not showing anything but white
                    
                    //for boss stage
                    if (self->_isBoss == YES) {
                        //
                        [self->_currentStage setOpacity:1.0];
                        [self lastBossBattleSequence];
                        //
                    } else {
                        //
                        self.gameIsActive = YES;
                        [self.currentStage setOpacity:1.0];
                        self.canPlay = YES;
                        [self.currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                            if ([node.name containsString:@"Fumina"]) {
                                [self fuminaPersistentAction:node];
                            }
                        }];
                        
                        [self.targetMarkDisplay setHidden:NO];
                        [self.pauseBtn setHidden:false];
                        [self.pauseBtn setEnabled:YES];
                        
                        //find bgm that needs to be played at
                        NSString *stageIndex = [self.selectedStage componentsSeparatedByString:@"_"].lastObject;
                        NSString *bgmName = [[self.dat objectForKey:@"bgmAtStage"] objectForKey:stageIndex];
                        if (bgmName) {
                            [self.parent playAudio:bgmName];
                        } else {
                            [self.parent playAudio:@"mysteriousWorld"];
                        }
                        
                    }
                    
                    
                }];
                
            });
        }];
    });
}

- (void)lastBossBattleSequence {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __weak id safeSelf = self;
        
        [self fadeToCam:[self getNodeContainingName:@"bossCam-1-0" withinNode:self.currentStage] fadeDuration:0.6f completion:^(BOOL finished) {
            //start panning after fading in to another camera
            [safeSelf panCamera:[self getNodeContainingName:@"bossCam-1-2" withinNode:self.currentStage] fadeDuration:8.0f];
        }];
    });
    
    // before fumina appears, the island looks in a despicable manner...
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // fire explodes all of a sudden
        [self playSFX:@"burnFire"];
        [self.currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
            if ([node.name containsString:@"fireNode"]) {
                [node setOpacity:1.0];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SCNTransaction begin];
                    [SCNTransaction setAnimationDuration:2.5f];
                    [node setOpacity:0.0];
                    [self.blackBGNode setOpacity:1.0];
                    [SCNTransaction commit];
                });
            }
        }];
        //
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // fumina appears...
            [self playSFX:@"explosion"];
            [self->_bossFumina runAction:[SCNAction moveByX:0 y:0 z:0.35 duration:0.3f]];
            [self.parent fadeAudio:@"bossBattle2" fadeDuration:0.5];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                // fumina shouts
                [self playSFX:@"growl"];
                [self->_bossFumina addAnimation:self->_animations[1] forKey:@"upset"];
                [self shake:self.sceneView.pointOfView rate:0.008 repeat:HUGE_VALF];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //
                    [self.sceneView.pointOfView removeAnimationForKey:@"shake" blendOutDuration:0.75f];
                    //
                    [SCNTransaction begin];
                    [SCNTransaction setCompletionBlock:^{
                        [self->_bossFumina runAction:[SCNAction moveTo:SCNVector3Zero duration:0.0]];
                    }];
                    [SCNTransaction setAnimationDuration:0.75f];
                    [self->_sky setOpacity:1.0];
                    [[self node:@"Sphere2"] setOpacity:1.0];
                    [SCNTransaction commit];
                    
                    [self fadeToCam:self.ARCamera fadeDuration:0.6f completion:nil];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[self node:@"bossFireBG-vfx-ymMove"] setOpacity:0.2];
                    });
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // game starts when gameplay is ready
                        [self->_targetMarkDisplay setHidden:NO];
                        self->_canPlay = YES;
                        self.gameIsActive = YES;
                        [self.pauseBtn setEnabled:YES];
                        //
                        self->_bossBattleCount = 0;
                        [self bossFuminaMoves:[self->_atkSeq objectAtIndex:self->_bossBattleCount]];
                        // run applicable fuminas
                        [self->_currentStage enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                            if ([node.name containsString:@"Fumina"]) {
                                [self fuminaPersistentAction:node];
                            }
                        }];
                    });
                });
            });
        });
    });
}
//




- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// DO NOT TOUCH

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    
    switch (camera.trackingState) {
        case ARTrackingStateNotAvailable:
            NSLog(@"Tracking state not available!");
            self.planeDetected = NO;
            break;
        case ARTrackingStateLimited:
            self.planeDetected = NO;
            switch (camera.trackingStateReason) {
                case ARTrackingStateReasonNone:
                    [self performSelectorOnMainThread:@selector(showSystemLabelWith:) withObject:NSLocalizedString(@"moveLR", nil) waitUntilDone:NO];
                    break;
                case ARTrackingStateReasonInitializing:
                    break;
                case ARTrackingStateReasonExcessiveMotion:
                    [self performSelectorOnMainThread:@selector(showSystemLabelWith:) withObject:NSLocalizedString(@"moveDeviceSlow", nil) waitUntilDone:NO];
                    break;
                case ARTrackingStateReasonInsufficientFeatures:
                    // tracking state is normal
                    [self performSelectorOnMainThread:@selector(showSystemLabelWith:) withObject:NSLocalizedString(@"lowLight", nil) waitUntilDone:NO];
                    break;
                case ARTrackingStateReasonRelocalizing:
                    // tracking state is normal
                    //[self performSelectorOnMainThread:@selector(showSystemLabelWith:) withObject:@"AR起動中" waitUntilDone:NO];
                    break;
            }
            break;
        case ARTrackingStateNormal:
            NSLog(@"Tracking state normal");
            //
            break;
    }
    
}

- (CGFloat)pointAngleFrom:(SCNVector3)p1 to:(SCNVector3)p2 {
    // get origin point to origin by subtracting end from start
    CGPoint originPoint = CGPointMake(p2.x-p1.x, p2.z-p1.z);
    float bearingRadians = atan2f(originPoint.x, originPoint.y); // get bearing in radians
    return GLKMathRadiansToDegrees(bearingRadians);
    //float bearingDegrees = (bearingRadians*(180/M_PI)); // convert to degrees. adjust for 3D world coordinate
    //return bearingDegrees;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)playSFX:(NSString *)name {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SKAction *sfx = [SKAction playSoundFileNamed:[NSString stringWithFormat:@"art.scnassets/%@",name] waitForCompletion:YES];
        [self.spriteScene runAction:sfx];
    });
}

- (SKAction *)prepareSFX:(NSString *)name {
    return [SKAction playSoundFileNamed:[NSString stringWithFormat:@"art.scnassets/%@",name] waitForCompletion:YES];
}

- (SCNNode *)node:(NSString *)nodeName {
    SCNNode *nodeToSearch;
    if (_currentStage) {
        nodeToSearch = [_currentStage childNodeWithName:nodeName recursively:YES];
    }
    if (nodeToSearch) {
        return nodeToSearch;
    }
    return [self.sceneView.scene.rootNode childNodeWithName:nodeName recursively:YES];
}

- (SCNNode *)getNodeContainingName:(NSString *)nodeName withinNode:(SCNNode *)sampleNode {
    NSLog(@"getNodeContainingName");
    __block SCNNode *rNode;
    [sampleNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if ([node.name containsString:nodeName]) {
            NSLog(@"getNodeContaintedName %@ sample %@", node, sampleNode);
            rNode = node;
        }
    }];
    return rNode;
}

- (void)addParticle:(NSString *)fileName toNode:(SCNNode *)nodeName {
    
    NSData *dat = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"scnp"]];
    SCNParticleSystem *scnp =  [NSKeyedUnarchiver unarchivedObjectOfClass:[SCNParticleSystem class] fromData:dat error:nil];
    dat = nil;
    
    [scnp setAccessibilityLabel:fileName];
    [scnp setBirthRate:0];
    [nodeName addParticleSystem:scnp];
    [nodeName setOpacity:0.0];
    
    NSLog(@"did add particle %@", scnp.description);
}



- (CAAnimation *)loadSCNAnimation:(NSString *)animName repeat:(float)repeatCount speed:(float)spd {
    
    NSString *animationName = [NSString stringWithFormat:@"%@-1",animName]; //creates "atk-1"
    NSURL *url = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"art.scnassets/%@", animName] withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:url options:nil ];
    CAAnimation *animation = [sceneSource entryWithIdentifier:animationName withClass:[CAAnimation class]]; //creates animation
    animation.fadeInDuration = 0.2f;
    animation.fadeOutDuration = 0.2f;
    animation.speed = spd;
    animation.removedOnCompletion = YES;
    animation.repeatCount = repeatCount;
    NSLog(@"animation %@", animation);
    return animation;
}


- (void)fadeToCam:(SCNNode *)camera fadeDuration:(float)dur completion:(completion)completionBlock {
    //
    [self.view setBackgroundColor:[UIColor blackColor]];
    [UIView animateWithDuration:dur animations:^{
        [self->_sceneView setAlpha:0.0];
    } completion:^(BOOL finished) {
        //change camera
        [self.sceneView setPointOfView:camera];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:dur animations:^{
                [self->_sceneView setAlpha:1.0];
            } completion:^(BOOL finished) {
                if (completionBlock) {
                    completionBlock(YES);
                }
            }];
        });
        //
    }];
    //
}

- (void)panCamera:(NSString *)camName :(float)duration {
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:duration];
    [self.sceneView setPointOfView:[self node:camName]];
    [SCNTransaction commit];
}

- (void)panCamera:(SCNNode *)node fadeDuration:(float)duration {
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:duration];
    [self.sceneView setPointOfView:node];
    [SCNTransaction commit];
}

- (void)shake:(SCNNode *)node rate:(float)rate repeat:(float)repeat {
    //
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"eulerAngles"];
    [animation setDuration:0.06];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setRepeatCount:repeat];
    [animation setAutoreverses:YES];
    [animation setRemovedOnCompletion:YES];
    [animation setFromValue:[NSValue valueWithSCNVector3:SCNVector3Make(node.eulerAngles.x+rate, node.eulerAngles.y+rate, node.eulerAngles.z+rate)]];
    [animation setToValue:[NSValue valueWithSCNVector3:SCNVector3Make(node.eulerAngles.x-rate, node.eulerAngles.y-rate, node.eulerAngles.z-rate)]];
    [node addAnimation:animation forKey:@"shake"];
    //
    NSLog(@"shake anim created for node %@", node.name);
}

- (void)deleteNode:(SCNNode *)node {
    
    [node setHidden:true];
    [node.particleSystems enumerateObjectsUsingBlock:^(SCNParticleSystem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setBirthRate:0.0];
    }];
    [node enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if (node.geometry) {
            [node.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.diffuse.contents = nil;
                obj.transparent.contents = nil;
            }];
            node.geometry = nil;
        }
        if (node.particleSystems) {
            [node removeAllParticleSystems];
        }
    }];
    [node removeAllActions];
    [node removeAllParticleSystems];
    [node removeFromParentNode];
    
    //recursive
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (SCNNode *)copyNode:(SCNNode *)nodeToCopy {
    // copy entire node
    SCNNode *copiedNode = [nodeToCopy clone];
    copiedNode.geometry = [nodeToCopy.geometry copy];
    return copiedNode;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [_spriteScene setSize:size];
}

- (void)fadeSceneToColor:(UIColor *)clr duration:(float)duration {
    
    [self.view setBackgroundColor:clr];
    
    [UIView animateWithDuration:duration animations:^{
        [self.sceneView setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
    
}

/// This method occurs after beating the boss
- (void)pauseSceneReturnAction:(NSInteger)idx {
    
    // boss small fumina (non-last boss)
    if (idx == 5) {
        // delete node
        [self showPostGameOptions];
        //[self goBackToMenuWithLevelUp:true];
    } else if (idx == 2) {
        // resume game
    } else if (idx == 1) {
        // repeat game
    } else {
        // last boss
        [self showPostGameOptions];
        //[self goBackToMenuWithLevelUp:false];
    }
    
}

- (IBAction)pauseAction:(id)sender {
    
    [self playSFX:@"pauseSfx"];
    
    
    [[self sceneView] setPlaying:false];
    //[[self sceneView].overlaySKScene setPaused:true];
    [[self sceneView].scene setPaused:true];
        
    PauseMenu *pm = [self.storyboard instantiateViewControllerWithIdentifier:@"PauseMenu"];
    [pm setParent:self];
    [self presentViewController:pm animated:true completion:nil];
    
    
}

@end
