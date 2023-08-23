//
//  DialogController.m
//  ARTreasure
//
//  Created by Koji Murata on 24/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#define InRadian(degrees)((M_PI * degrees)/180)

#import "DialogController.h"
#import "ViewController.h"
#import "MainParent.h"

@interface DialogController ()

@property (strong, nonatomic) NSArray *currentDialog;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIImageView *textShade;

@property int currentPointer;
@property int c; // for uitextfield typewriter effects

@property (strong, nonatomic) NSString *currentLine;
@property (weak, nonatomic) SCNNode *bossFumina;
@property (strong, nonatomic) NSTimer *textTimer;

@property (strong, nonatomic) IBOutlet UIButton *tap;
- (IBAction)userDidTap:(id)sender;

@end

@implementation DialogController

//
/*
 Dialog controller
 This view will be used in the entire app's life cycle, and will only be instantiated once!
*/

- (void)startNewDialog:(NSArray *)newDialog run:(BOOL)run {
    
    // store dialog
    self.currentDialog = newDialog;
    
    // initialize
    _currentPointer = 0;
    _c = 0;
    
    if (run == YES) {
        [self runDialog];
    }
    //
}

- (void)userDidSkip {
    
}

- (void)run:(NSString *)dialogIdentifier {
    
    _currentDialog = [_dialogs objectForKey:dialogIdentifier];
    _currentPointer = 0;
    
    [self runDialog];
    
}

/* */
- (void)runDialog {
    
    NSDictionary *dialog = [self.currentDialog objectAtIndex:_currentPointer];
    NSLog(@"runDialog %@", dialog);
    
    // control session
    if ([dialog objectForKey:@"pauseSession"]) {
        //
        BOOL setPause = [dialog objectForKey:@"pauseSession"];
        
        if (setPause == YES) {
            [[_parent sceneView].session pause];
        } else {
            [[_parent sceneView].session runWithConfiguration:[_parent arCongifuration]];
        }
        //
    }
    
    // display post game menu
    if ([dialog objectForKey:@"successGame"]) {
        
        // call post boss -
        [_parent displayGameCreditAfterGameCompletion];
        
    }
    
    //
    if ([dialog objectForKey:@"playBgm"]) {
        [[self.parent parent] fadeAudio:[dialog objectForKey:@"playBgm"] fadeDuration:0.0];
    }
    
    // run full animation preparations all for <UIObjects, SceneKit objects, Scenekit characters, SpriteKit objects>
    if ([dialog objectForKey:@"scenePreparation"]) {
        
        NSArray *spCmd = [dialog objectForKey:@"scenePreparation"];
        [spCmd enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull cmd, NSUInteger idx, BOOL * _Nonnull stop) {
            
            float delay = 0;
            if ([cmd objectForKey:@"delay"]) {
                delay = [[cmd objectForKey:@"delay"] floatValue];
            }
            float duration = 0;
            if ([cmd objectForKey:@"duration"]) {
                duration = [[cmd objectForKey:@"duration"] floatValue];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // command for UIObjects
                if ([cmd objectForKey:@"uiObject"]) {
                    //
                    NSString *subjectName = [cmd objectForKey:@"uiObject"];
                    id obj;
                    if ([subjectName isEqualToString:@"sceneView"]) {
                        obj = [self.parent sceneView];
                    }
                    
                    //command
                    [UIView animateWithDuration:duration animations:^{
                        
                        if ([cmd objectForKey:@"setAlpha"]) {
                            [obj setAlpha:[[cmd objectForKey:@"setAlpha"] floatValue]];
                        }
                    }];
                    //
                }
                
                // command for SceneKit Objects within current scene
                if ([cmd objectForKey:@"node"]) {
                    //
                    //SCNNode *subjectNode = [self.parent node:(NSString *)[cmd objectForKey:@"node"]];
                    
                    
                    
                }
                // command for Scenekit Characters
                if ([cmd objectForKey:@"character"]) {
                    //NSString *subjectName = [cmd objectForKey:@"character"];
                    
                }
                
            });
            
            
        }];
    }
    
    
    // run 3D node animations
    if ([dialog objectForKey:@"nodeAnim"]) {
        
        NSArray *nodeAnim = [dialog objectForKey:@"nodeAnim"];
        [nodeAnim enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull cmd, NSUInteger idx, BOOL * _Nonnull stop) {
            //
            
            float delay = 0.0;
            if ([cmd objectForKey:@"delay"]) {
                delay = [[cmd objectForKey:@"delay"] floatValue];
            }
            float duration = 0.0;
            if ([cmd objectForKey:@"duration"]) {
                duration = [[cmd objectForKey:@"duration"] floatValue];
            }
            
            if ([cmd objectForKey:@"node"]) {
                // for animation that must have node
                
                SCNNode *currentNode;
                NSString *nodeName = [cmd objectForKey:@"node"];
                
                // custom nodes
                if ([nodeName isEqualToString:@"boss"]) {
                    currentNode = [self->_parent bossFumina];
                } else if ([nodeName isEqualToString:@"pov"]) {
                    currentNode = [self->_parent sceneView].pointOfView;
                } else if ([nodeName isEqualToString:@"base"]) {
                    currentNode = [self->_parent currentStage];
                }
                //
                
                if (!currentNode) { // set node by finding
                    currentNode = [self->_parent node:nodeName];
                }
                if (!currentNode) { // set node by finding
                    currentNode = [self->_parent getNodeContainingName:nodeName withinNode:[self.parent sceneView].scene.rootNode];
                }
                
                SCNAction *delayAction = [SCNAction waitForDuration:delay];
                
                SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
                    
                    // run func in this block
                    NSLog(@"action block %@", node.name);
                    
                    if ([cmd objectForKey:@"opacity"]) {
                        [node runAction:[SCNAction fadeOpacityTo:[[cmd objectForKey:@"opacity"] floatValue] duration:duration]];
                    }
                    if ([cmd objectForKey:@"scale"]) {
                        [node runAction:[SCNAction scaleTo:[[cmd objectForKey:@"scale"] floatValue] duration:duration]];
                    }
                    if ([cmd objectForKey:@"shake"]) {
                        float rate = [[cmd objectForKey:@"shake"] floatValue];
                        [self->_parent shake:node rate:rate repeat:HUGE_VALF];
                    }
                    if ([cmd objectForKey:@"removeShake"]) {
                        float fadeOutDur = [[cmd objectForKey:@"removeShake"] floatValue];
                        [node removeAnimationForKey:@"shake" blendOutDuration:fadeOutDur];
                    }
                    // override base animation
                    if ([cmd objectForKey:@"overrideAnim"]) {
                        [node removeAllAnimations];
                        
                        NSString *animationName = [cmd objectForKey:@"overrideAnim"];
                        if ([animationName isEqualToString:@"paused"]) {
                            [node addAnimation:[[self->_parent animations] objectAtIndex:4] forKey:nil];
                        } else {
                            CAAnimation *anim = [self->_parent loadSCNAnimation:animationName repeat:HUGE_VALF speed:1.0];
                            [node addAnimation:anim forKey:animationName];
                        }
                    }
                    
                    //
                    if ([cmd objectForKey:@"position"]) {
                        SCNNode *positionNode = [self->_parent node:(NSString *)[cmd objectForKey:@"position"]];
                        NSLog(@"action block positionNode %@", positionNode.name);
                        [node runAction:[SCNAction moveTo:positionNode.worldPosition duration:duration]];
                    }
                    
                }];
                
                [currentNode runAction:[SCNAction sequence:@[delayAction, action]]];
                
            }
            
            // for actions without node
            if ([cmd objectForKey:@"sfx"]) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self->_parent playSFX:(NSString *)[cmd objectForKey:@"sfx"]];
                });
                
            }
            
            // lighten up all camera momentarily
            if ([cmd objectForKey:@"setCameraExposure"]) {
                
                float exposure = [[cmd objectForKey:@"setCameraExposure"] floatValue];
                
                [[self->_parent sceneView].scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                    if (child.camera) {
                        //
                        [child runAction:[SCNAction sequence:@[[SCNAction waitForDuration:delay],[SCNAction runBlock:^(SCNNode * _Nonnull node) {
                            [SCNTransaction begin];
                            [SCNTransaction setAnimationDuration:duration];
                            [node.camera setExposureOffset:exposure];
                            [SCNTransaction commit];
                        }]]]];
                        //
                    }
                }];
            }
            
            // remove all camera shake - this is to reset everything
            if ([cmd objectForKey:@"removeAllShake"]) {
                float fadeOutDuration = [[cmd objectForKey:@"removeAllShake"] floatValue];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self.parent sceneView].scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                        [child removeAnimationForKey:@"shake" blendOutDuration:fadeOutDuration];
                    }];
                });
                
               
            }
            
            // screenControl
            if ([cmd objectForKey:@"whiteOut"]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.parent fadeSceneToColor:[UIColor whiteColor] duration:duration];
                    });
                });
                
                
            }
            
            // control audio
            if ([cmd objectForKey:@"fadeAudio"]) {
                //contain only two objects [0] duration [1] next audio name
                NSArray *cmds = [[cmd objectForKey:@"fadeAudio"] componentsSeparatedByString:@"|"];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (cmds.count == 1) {
                        [[self.parent parent] fadeAudio:nil fadeDuration:[cmds.firstObject floatValue]];
                    } else {
                        [self->_parent fadeAudio:cmds.lastObject fadeDuration:[cmds.firstObject floatValue]];
                    }
                });
                
            }
            
            // control camera pan
            if ([cmd objectForKey:@"setCamera"]) {
                NSArray *cmds = [[cmd objectForKey:@"setCamera"] componentsSeparatedByString:@"|"];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (cmds.count == 1) {
                        [self->_parent panCamera:cmds.firstObject :0.0];
                    } else {
                        [self->_parent panCamera:cmds.firstObject :[cmds.lastObject floatValue]];
                    }
                });
            }
            
            // control camera fade
            if ([cmd objectForKey:@"fadeToCam"]) {
                NSArray *cmds = [[cmd objectForKey:@"fadeToCam"] componentsSeparatedByString:@"|"];
               
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (cmds.count == 1) {
                        
                        [self->_parent fadeToCam:[self.parent getNodeContainingName:cmds.firstObject withinNode:[self.parent currentStage]] fadeDuration:0.1 completion:nil];
                    } else {
                        [self->_parent fadeToCam:[self.parent getNodeContainingName:cmds.firstObject withinNode:[self.parent currentStage]] fadeDuration:[cmds.lastObject floatValue] completion:nil];
                    }
                });
            }
            
            // call next dialog phase
            if ([cmd objectForKey:@"callNext"]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self->_currentPointer++;
                    [self runDialog];
                });
            }
        
        }];
    }
    
    // in dialoge scene only functions
    if (_inDialogScene == YES) {
        if ([dialog objectForKey:@"camera"]) {
            [self.dialogSceneView setPointOfView:[self node:(NSString *)[dialog objectForKey:@"camera"]]];
            [[self node:@"Sphere"] setPosition:[self node:(NSString *)[dialog objectForKey:@"camera"]].worldPosition];
        }
        if ([dialog objectForKey:@"panTo"]) {
            float duration = 1.0;
            if ([dialog objectForKey:@"panToDuration"]) {
                duration = [[dialog objectForKey:@"panToDuration"] floatValue];
            }
            [self panCamera:(NSString *)[dialog objectForKey:@"panTo"] :duration];
        }
        if ([dialog objectForKey:@"fadeIn"]) {
            [UIView animateWithDuration:0.7 animations:^{
                [self.dialogSceneView setAlpha:1.0];
            }];
        }
        if ([dialog objectForKey:@"fadeOut"]) {
            [UIView animateWithDuration:0.7 animations:^{
                [self.dialogSceneView setAlpha:0.0];
            }];
        }
        
        if ([dialog objectForKey:@"bossAnim"]) {
            if (!_bossFumina) {
                [self createBossFuminaInstance];
            }
            // after creation, call
            
        }
        
        if ([dialog objectForKey:@"disappearObject"]) {
            [self objectDisappearance:[self node:[dialog objectForKey:@"disappearObject"]]];
        }
        
    }
    
    //display line
    if ([dialog objectForKey:@"line"]) {
        //
        [_textView setHidden:NO];
        [_textShade setHidden:NO];

        _currentLine = [dialog objectForKey:@"line"];
        _c = 0;
        //
        _textTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if (self.c < self.currentLine.length) {
                [self.textView setText:[NSString stringWithFormat:@"%@%C",self.textView.text,[self.currentLine characterAtIndex:self.c]]];
                self.c++;
            } else {
                [timer invalidate];
            }
        }];
    } else {
        [_textView setHidden:YES];
        [_textShade setHidden:YES];
    }
    
    
    
    if ([dialog objectForKey:@"autoTapAfter"]) {
        float delay = [[dialog objectForKey:@"autoTapAfter"] floatValue];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->_currentPointer++;
            if (self.currentPointer < self.currentDialog.count) {
                [self runDialog];
            }
        });
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    if (_inDialogScene == YES) {
        NSLog(@"Dialog Viewdidload inDialogStarted ");
        SCNScene *scene = [SCNScene sceneNamed:@"World.dae"];
        self.dialogSceneView.scene = scene;
        [self.dialogSceneView setAlpha:0.0];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    _spriteScene = [SKScene sceneWithSize:self.dialogSceneView.frame.size];
    self.dialogSceneView.overlaySKScene = _spriteScene;
    
    if (_inDialogScene == YES) {
        
        
        
        // configure scene
        //UIImage *fire = [UIImage imageNamed:@"tex-fire"];
        //UIImage *flameTrns = [UIImage imageNamed:@"tex-flameTransparent"];

        [self.dialogSceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
            //
            if (child.light) {
                [child.light setIntensity:500];
            }
            if (child.geometry) {
                [child.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull mat, NSUInteger idx, BOOL * _Nonnull stop) {
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
                    if ([mat.name containsString:@"flame"]) {
                        //[mat.diffuse setMappingChannel:0];
                        //[mat.diffuse setContents:fire];
                        //[mat.transparent setMappingChannel:1];
                        //[mat.transparent setContents:flameTrns];
                    }
                    if ([child.name containsString:@"xmove"]) {
                        // shader
                        NSString *cvShader = @"_geometry.texcoords[0].x += 2*u_time;";
                        child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                    }
                    if ([child.name containsString:@"yMove"]) {
                        // shader
                        NSString *cvShader = @"_geometry.texcoords[0].x += 0.5*u_time;"
                        @"_geometry.texcoords[0].y += 3*u_time;";
                        child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                    }
                }];
                // detect if geometry has
                if ([child.name containsString:@"Phase"]) {
                    [child setHidden:YES];
                }
                
            }
            
            // hide stage
            if ([child.name containsString:@"Stage"]) {
                [child setOpacity:1.0];
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
                [child.camera setMinimumExposure:-0.5];
                [child.camera setMaximumExposure:0.3];
                [child.camera setExposureOffset:0.28];
                //bloom
                [child.camera setBloomIntensity:0.35];
                [child.camera setBloomThreshold:0.5];
                [child.camera setBloomBlurRadius:3.0];
                //
                [child.camera setSaturation:1.1];
                [child.camera setContrast:0.1];
                //
                [child.camera setWantsDepthOfField:YES];

                [child.camera setFStop:4.0];
                
            }
        }];
        
        // add lighting
        
        SCNLight *directional = [SCNLight light];
        [directional setType:SCNLightTypeDirectional];
        [directional setIntensity:900];
        [[self node:@"lightDirection"] setLight:directional];
        
        [[self node:@"Sphere2"] setOpacity:1.0];
        
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
}

- (void)createBossFuminaInstance {
    
    // load fumina from file as new instance
    NSString *bossFilePath = @"art.scnassets/FUMINA.dae";
    SCNScene *fuminaScene = [SCNScene sceneNamed:bossFilePath];
    _bossFumina = [fuminaScene.rootNode childNodeWithName:@"root" recursively:YES];
    [[_bossFumina childNodeWithName:@"tapCube" recursively:YES] setOpacity:0.0];
    
    // set its position
    SCNNode *bossAxis = [self node:@"fmnBoss-Pos0"];
    NSLog(@"bossAxis added <setup> %@", bossAxis);
    
    [bossAxis addChildNode:_bossFumina]; //add
    [_bossFumina setEulerAngles:SCNVector3Make(InRadian(90), _bossFumina.eulerAngles.y, _bossFumina.eulerAngles.z)];
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.bossFumina runAction:[SCNAction moveByX:0 y:0 z:0.35 duration:0.3f]];
    });
    
}

// controlling sprite
- (void)skNodeAction:(NSDictionary *)skAction {
    
    // initial parameters
    SKNode *theNode;
    
    float delay = 0.0;
    if ([skAction objectForKey:@"delay"]) {
        delay = [[skAction objectForKey:@"delay"] floatValue];
    }
    SKAction *delayAction = [SKAction waitForDuration:delay];
    
    
    // load corresponding skAction dictionary
    if ([skAction objectForKey:@"name"]) {
        
        NSString *nodeName = [skAction objectForKey:@"name"];
        
        if ([self skNode:nodeName]) {
            //node exists
            theNode = [self skNode:nodeName];
        } else {
            //none, create new unless delete command is issued
            if (![skAction objectForKey:@"delete"]) {
                theNode = [self loadSpriteFromFile:nodeName];
                [[_parent spriteScene] addChild:theNode];
                [theNode setPaused:NO];
            }
        }
    }
    
    NSLog(@"sknode created/found %@",theNode);
    
    
    // delay applies from here
    SKAction *actionBlock = [SKAction runBlock:^{
        // setting userData
        [theNode.userData enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSLog(@"existing key %@", key);
        }];
        if ([skAction objectForKey:@"centerPosition"]) {
            [theNode setPosition:CGPointMake([self.parent screenCenter].x, [self->_parent spriteScene].size.height-[self.parent screenCenter].y)];
        }
        // delete node from scene
        if ([skAction objectForKey:@"delete"]) {
            [self deleteSKNode:theNode];
        }
    }];
    
    if (theNode) {
        // run action
        [theNode runAction:[SKAction sequence:@[delayAction, actionBlock]]];
    }
}
- (SKNode *)skNode:(NSString *)nodeName {
    return [[_parent spriteScene] childNodeWithName:nodeName];
}
- (SKNode *)loadSpriteFromFile:(NSString *)fileName {
    //1. load from file
    NSString *fileUrl = [NSString stringWithFormat:@"%@.sks", fileName];
    SKNode *loadedScene = [SKNode nodeWithFileNamed:fileUrl].children.firstObject;
    [loadedScene removeFromParent];
    [loadedScene setName:fileName];
    NSLog(@"loaded skFile %@ < actions:%d", loadedScene, loadedScene.hasActions);
    [loadedScene.children enumerateObjectsUsingBlock:^(SKNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.hasActions) {
            NSLog(@"loaded sk child W/T action(s):%d - %@", obj.hasActions, obj.name);
        }
    }];
    return loadedScene;
}
- (void)deleteSKNode:(SKNode *)delNd {
    
    [delNd removeAllActions];
    [delNd removeAllChildren];
    [delNd removeFromParent];
    
}
- (SCNNode *)node:(NSString *)nodeName {
    return [self.dialogSceneView.scene.rootNode childNodeWithName:nodeName recursively:YES];
}
- (void)panCamera:(NSString *)camName :(float)duration {
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:duration];
    [self.dialogSceneView setPointOfView:[self node:camName]];
    [[self node:@"Sphere"] setPosition:[self node:camName].worldPosition];
    [SCNTransaction commit];
    
}

- (void)objectDisappearance:(SCNNode *)objectToTransform {
        
    SCNNode *vortexAxis = [self node:@"appearanceAnchor"];
    SCNNode *vortex = [self node:@"Circle-vfx-xmove-1"];
    SCNNode *sun = [self node:@"shineSun-vfx"];
    
    // Let stage shine away
    [vortexAxis setTransform:objectToTransform.transform];
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
            [objectToTransform enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                [child.geometry.firstMaterial.emission setIntensity:1.0];
            }];
            [SCNTransaction commit];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.7];
            [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
            [objectToTransform setScale:SCNVector3Make(0.0, 0.0, 0.0)];
            [objectToTransform setEulerAngles:SCNVector3Make(objectToTransform.eulerAngles.x, InRadian(900), objectToTransform.eulerAngles.z)];
            [objectToTransform setOpacity:0.0];
            [sun setOpacity:0.0];
            [sun setScale:SCNVector3Zero];
            [SCNTransaction commit];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.8];
            [vortex setOpacity:0.0];
            [vortex setScale:SCNVector3Make(0.5, 0.5, 0.5)];
            //[self.sky setOpacity:0.0];
            [SCNTransaction commit];
        });
    });
}

- (void)playSFX:(NSString *)name {
    SKAction *sfx = [SKAction playSoundFileNamed:[NSString stringWithFormat:@"art.scnassets/%@",name] waitForCompletion:YES];
    [_spriteScene runAction:sfx];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (IBAction)userDidTap:(id)sender {
    self->_currentPointer++;
    [self.textView setText:@""];
    if (self.currentPointer < self.currentDialog.count) {
        [self runDialog];
    } else {
        [_textView setHidden:YES];
    }
}

@end
