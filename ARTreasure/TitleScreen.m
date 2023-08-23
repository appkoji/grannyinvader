//
//  TitleScreen.m
//  ARTreasure
//
//  Created by Koji Murata on 26/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import "TitleScreen.h"
#import "ViewController.h"
#import "MainParent.h"

@interface TitleScreen ()

@property (strong, nonatomic) IBOutlet UIImageView *titleLogo;
@property (strong, nonatomic) IBOutlet UIImageView *titleScreenBG;
@property (strong, nonatomic) IBOutlet UIButton *startBtn;
@property (strong, nonatomic) IBOutlet UILabel *pressStartDisplay;
@property (strong, nonatomic) IBOutlet UILabel *nameDisplay;
@property (strong, nonatomic) SKAction *startSound;
@property (weak, nonatomic) SCNNode *firstFumina;
@property (weak, nonatomic) SCNNode *fireBall;
@end

@implementation TitleScreen
@synthesize firstFumina, fireBall;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    [_startBtn setEnabled:false];
    [_titleLogo setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/TitleWorld.dae"];
    self.sceneView.scene = scene;
    self.sceneView.contentScaleFactor = 1.0f;
    [self.sceneView setAlpha:0.0];
    
    
    
    scene = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
        
    // sprite scene setup
    _spriteScene = [SKScene sceneWithSize:self.sceneView.frame.size];
    self.sceneView.overlaySKScene = _spriteScene;
    [_spriteScene setPaused:NO];
    
    [[self node:@"blackoutBG"] setOpacity:0.0];
    
    // configure scene
    
    [self.sceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        //
        if (child.light) {
            [child.light setIntensity:480];
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
                //
                if ([child.name containsString:@"xmove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].x += 1*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
                if ([child.name containsString:@"yMove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].x += 0.5*u_time;"
                                        @"_geometry.texcoords[0].y += 1.5*u_time;";
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
            [child.camera setMinimumExposure:-0.5];
            [child.camera setMaximumExposure:0.3];
            [child.camera setExposureOffset:0.28];
            
            //bloom
            [child.camera setBloomIntensity:0.3];
            [child.camera setBloomThreshold:0.5];
            [child.camera setBloomBlurRadius:2.0];
            
            //
            [child.camera setSaturation:1.1];
            [child.camera setContrast:0.1];
            
            //
            [child.camera setWantsDepthOfField:YES];
            [child.camera setFStop:5.0];
            
        }
    }];
    
    // add lighting
    SCNLight *directional = [SCNLight light];
    [directional setType:SCNLightTypeDirectional];
    [directional setIntensity:850];
    
    [[self node:@"lightDirection"] setLight:directional];
    [[self node:@"Sphere2"] setOpacity:0.0];
    
    // add physics body to fireBall
    SCNNode *fireBall = [self node:@"fireBall"];
    fireBall.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:[SCNSphere sphereWithRadius:0.03f] options:nil]];
    fireBall.physicsBody.categoryBitMask = 2;
    [self addParticle:@"fireBall" toNode:fireBall];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    [UIView animateWithDuration:1.0 animations:^{
        [self.nameDisplay setAlpha:1.0];
    } completion:^(BOOL finished) {
        [self titleSequence];
    }];
    
}

- (void)skipSequence {
    
}

- (void)titleSequence {
    
    // display title stage where Fumina throws fire towards player
    [self.sceneView setPointOfView:[self node:@"Camera-Intro"]];
    
    // immediately add first stage fumina
    SCNScene *fuminaScene = [SCNScene sceneNamed:@"art.scnassets/FUMINA-FirstAttack.dae"];
    firstFumina = [fuminaScene.rootNode childNodeWithName:@"Fumina" recursively:YES];
    fuminaScene = nil;
    [_sceneView.scene.rootNode addChildNode:firstFumina];
    [firstFumina setTransform:[self node:@"ffmn-pos"].transform];
    [firstFumina setScale:SCNVector3Make(0.035, 0.035, 0.035)];
    [firstFumina setEulerAngles:SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)];
    
    //load animations and events
    
    // fire ball
    SCNNode *tempFireBallCopy = [self node:@"fireBall"];
    fireBall = tempFireBallCopy;
    
    SCNParticleSystem *particle = fireBall.particleSystems.firstObject;
    [fireBall setOpacity:0.0];
    SCNVector3 fBallOrigScale = fireBall.scale;
    [fireBall setScale:SCNVector3Zero];
    [particle setBirthRate:0];
    
    NSLog(@"initial fireball %@", fireBall);
    [[self node:@"fireBG-vfx-yMove"] setOpacity:0.0];
    
    // add fireball on fuminas left hand
    SCNNode *fmnLeftHand = [self node:@"L_Hand"];
    [fireBall setAccessibilityValue:@"L_Hand"];
    [self.sceneView.scene.rootNode addChildNode:fireBall];
    
    //instance sfx
    __block SKAction *shout = [self prepareSFX:@"fuminaShout"];
    __block SKAction *fire = [self prepareSFX:@"fire"];
    __block SKAction *hit = [self prepareSFX:@"explosion"];
    _startSound = [self prepareSFX:@"positionConfirm"];
    
    //fuminaShout
    SCNAnimationEvent *event0 = [SCNAnimationEvent animationEventWithKeyTime:0.4 block:^(id<SCNAnimation>  _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self.spriteScene runAction:shout];
        });
        
        SCNNode *ffGeometryNode = [self.firstFumina childNodeWithName:@"Fumina-OW" recursively:YES];
        
        SCNMaterial *face = [ffGeometryNode.geometry materialWithName:@"FaceMat"];
        [face.diffuse setContentsTransform:SCNMatrix4MakeTranslation(0.0, 0.5, 0.0)];
    }];
    
    // where fireball ignites on her hand
    SCNAnimationEvent *event1 = [SCNAnimationEvent animationEventWithKeyTime:0.65 block:^(id<SCNAnimation>  _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self->_startBtn.enabled == YES) {
                [self->fireBall setPosition:fmnLeftHand.worldPosition];
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:1.5];
                [self->fireBall setOpacity:1.0];
                [self->fireBall setScale:fBallOrigScale];
                [particle setBirthRate:20];
                [SCNTransaction commit];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [self.spriteScene runAction:fire];
                });
            }
        });
        
    }];
    
    __block SCNAction *afterHit = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self->_startBtn.enabled == YES) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [self.spriteScene runAction:hit];
                });
                [self.parent fadeAudio:@"gameTheme" fadeDuration:0.0f];
                // remove unnessesary scenes and objects
                shout = nil;
                fire = nil;
                hit = nil;
                [particle setBirthRate:0];
                
                //display title view
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self displayTitleScreen];
                });
            }
            
        });
        
    }];
    
    // cg throws fire to camera
    SCNAnimationEvent *event2 = [SCNAnimationEvent animationEventWithKeyTime:0.8 block:^(id<SCNAnimation>  _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
        [self->fireBall setAccessibilityValue:nil];
        [particle setBirthRate:50];
        SCNAction *bAction = [SCNAction sequence:@[[SCNAction moveTo:[self node:@"Camera-Intro3"].position duration:0.5],afterHit]];
        [self->fireBall runAction:bAction];
    }];
    
    CAAnimation *firstFireThrow = [self loadSCNAnimation:@"FUMINA-FirstAttack-Anim" repeat:0 speed:1.0];
    firstFireThrow.animationEvents = @[event0,event1,event2];
    //remove all animation eventblocks after use
    event0 = nil;
    event1 = nil;
    event2 = nil;
    
    // begin animation sequence
    [self.parent fadeAudio:@"space" fadeDuration:0.0f];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->firstFumina addAnimation:firstFireThrow forKey:@"firstFuminaSequence"];
    });
    
    //
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.startBtn setEnabled:true];
    });
    
    [UIView animateWithDuration:1.9f animations:^{
        [self.sceneView setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];
    
    NSLog(@"viewDidAppear on main Game Scene");
    
    // let camera pan to position "Camera-Intro2"
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:6.0];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [self.sceneView setPointOfView:[self node:@"Camera-Intro2"]];
    [SCNTransaction commit];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->_startBtn.enabled == YES) {
            [UIView animateWithDuration:2.0 animations:^{
                [self.nameDisplay setAlpha:0.0];
            }];
        }
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->_startBtn.enabled == YES) {
            [self panCamera:@"Camera-Intro3" :1.5];
        }
    });
    
}

- (SKAction *)prepareSFX:(NSString *)name {
    return [SKAction playSoundFileNamed:[NSString stringWithFormat:@"art.scnassets/%@",name] waitForCompletion:YES];
}

- (void)displayTitleScreen {
    
    // red/black background
    // title zooms in
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.5];
    [[self node:@"fireBG-vfx-yMove"] setOpacity:1.0];
    [SCNTransaction commit];
    
    [UIView animateWithDuration:0.15f animations:^{
        [self->_titleScreenBG setAlpha:0.5];
        [self->_titleLogo setAlpha:1.0];
        [self->_titleLogo setTransform:CGAffineTransformMakeScale(1.4, 1.4)];
        [self.fireBall setOpacity:0.0];
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.08f animations:^{
            [self->_titleLogo setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->_startBtn setEnabled:YES];
            [self.pressStartDisplay setTransform:CGAffineTransformMakeTranslation(0, +50)];
            [UIView animateWithDuration:1.0 animations:^{
                [self->_pressStartDisplay setAlpha:1.0];
                [self.pressStartDisplay setTransform:CGAffineTransformMakeTranslation(0, 0)];
            }];
        });
    }];
}

- (IBAction)startAction:(id)sender {
    
    [_spriteScene runAction:_startSound];
    [_startBtn setEnabled:false];
    
    // determine if titleLogo is already displayed or not
    if (_titleLogo.alpha < 1.0) {
        // skipped
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.parent fadeAudio:@"gameTheme" fadeDuration:0.0f];
        });

        
        NSLog(@"Paused");
        [_sceneView setPlaying:NO];
        [_sceneView.scene setPaused:YES];
        
        [fireBall removeAllActions];
        [fireBall removeAllAnimations];
        [firstFumina removeAllActions];
        [firstFumina removeAllAnimations];
        
        [UIView animateWithDuration:0.3f animations:^{
            [self->_titleScreenBG setAlpha:1.0];
            [self->_titleLogo setAlpha:1.0];
            [self->_titleLogo setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
            [self->_pressStartDisplay setAlpha:1.0];
            [self->_nameDisplay setAlpha:0.0];
        }];
        
    }
    
    //[_parent didStartGame];
    
    // close this view
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self gameDidStarted];
    });
    
}

- (void)gameDidStarted {
    
    // prepare to clear up this views property
    //[self clearupScene];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.parent mpFuncDidStartGame];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:NO];
    [self clearupScene];
}

- (void)clearupScene {
    
    [_sceneView.scene setPaused:YES];
    [_sceneView setPlaying:NO];
    
    [self.sceneView.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if (node.geometry) {
            [node.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj.diffuse setContents:nil];
                [obj.transparent setContents:nil];
                [obj.ambient setContents:nil];
                [obj.emission setContents:nil];
                [obj.ambientOcclusion setContents:nil];
                [obj.reflective setContents:nil];

            }];
        }
        if (node.particleSystems) {
            [node.particleSystems enumerateObjectsUsingBlock:^(SCNParticleSystem * _Nonnull particle, NSUInteger idx, BOOL * _Nonnull stop) {
                [particle setAccessibilityLabel:nil];
                [particle setEmitterShape:nil];
                [particle setParticleImage:nil];
            }];
        }
        if (node.skinner) {
            node.skinner = nil;
        }
        if (node.morpher) {
            node.morpher = nil;
        }
        if (node.physicsBody) {
            [node.physicsBody setPhysicsShape:nil];
            [node setPhysicsBody:nil];
        }
        [node removeAllAnimations];
        [node removeAllActions];
    }];
    [self.sceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if (node.geometry) {
            [node setGeometry:nil];
        }
        [node removeAllParticleSystems];
        [node removeFromParentNode];
    }];
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIImageView class]]) {
            [(UIImageView *)obj setImage:nil];
        }
    }];
    [self.spriteScene.children enumerateObjectsUsingBlock:^(SKNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj = nil;
    }];
    
    [self.spriteScene removeAllChildren];
    [self.spriteScene removeAllActions];
    
    self.sceneView.overlaySKScene = nil;
    [self.sceneView setScene:nil];
    
    _titleLogo = nil;
    _titleScreenBG = nil;
    _startBtn = nil;
    _pressStartDisplay = nil;
    _nameDisplay = nil;
    _startSound = nil;
    firstFumina = nil;
    fireBall = nil;
    _spriteScene = nil;
    
    [_sceneView removeFromSuperview];
    _sceneView = nil;

}

- (SCNNode *)node:(NSString *)nodeName {
    return [self.sceneView.scene.rootNode childNodeWithName:nodeName recursively:YES];
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

- (void)addParticle:(NSString *)fileName toNode:(SCNNode *)nodeName {
    
    NSData *dat = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"scnp"]];
    SCNParticleSystem *scnp =  [NSKeyedUnarchiver unarchivedObjectOfClass:[SCNParticleSystem class] fromData:dat error:nil];
    
    [scnp setAccessibilityLabel:fileName];
    [scnp setBirthRate:0];
    [nodeName addParticleSystem:scnp];
    [nodeName setOpacity:0.0];
    scnp = nil;
    
}

- (void)panCamera:(NSString *)camName :(float)duration {
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:duration];
    [self.sceneView setPointOfView:[self node:camName]];
    [SCNTransaction commit];
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
