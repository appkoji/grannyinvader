//
//  GameMenuScene.m
//  ARTreasure
//
//  Created by Koji Murata on 26/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import "GameMenuScene.h"
#import "ViewController.h"
#import "MainParent.h"

@interface GameMenuScene ()

@property (weak, nonatomic) SCNNode *selectedStage;
@property NSInteger maxStage;

@end

@implementation GameMenuScene

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.userInteractionEnabled = YES;
    
    SCNScene *scene = [SCNScene sceneNamed:@"World.dae"];
    self.sceneView.scene = scene;
    [self.sceneView setAlpha:0.0];
    
    NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
    if ([save objectForKey:@"user_currentStage"]) {
        _maxStage = [[save objectForKey:@"user_currentStage"] integerValue];
    } else {
        [save setObject:[NSNumber numberWithInteger:0] forKey:@"user_currentStage"];
        [save synchronize];
        _maxStage = 0;
    }
    
    // add gesture for swiping left or right
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.view addGestureRecognizer:swipeLeft];
    [self.view addGestureRecognizer:swipeRight];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
    
    // prepare scene
    [self.sceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        //
        if (child.light) {
            [child removeFromParentNode];
            [child setLight:nil];
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
                    [mat.diffuse setMappingChannel:0];
                    [mat.diffuse setContents:[UIImage imageNamed:@"tex-fire"]];
                    [mat.transparent setMappingChannel:1];
                    [mat.transparent setContents:[UIImage imageNamed:@"tex-flameTransparent"]];
                }
                
                if ([child.name containsString:@"xmove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].x += 2*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
                if ([child.name containsString:@"ymMove"]) {
                    // shader
                    NSString *cvShader = @"_geometry.texcoords[0].y += 1*u_time;";
                    child.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : cvShader};
                }
            }];
            
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
            [child.camera setMinimumExposure:-0.4];
            [child.camera setMaximumExposure:0.2];
            [child.camera setExposureOffset:0.25];
            
            //bloom
            [child.camera setBloomIntensity:0.2];
            [child.camera setBloomThreshold:0.5];
            [child.camera setBloomBlurRadius:5.5];
            
            //
            [child.camera setSaturation:1.1];
            [child.camera setContrast:0.96];
            
        }
    }];
    
    [[self node:@"CollisionCube"] removeFromParentNode];
    [[self node:@"blackoutBG"] removeFromParentNode];
    
    _sky = [self node:@"Sphere"];
    [_sky setOpacity:1.0];
    [[self node:@"Sphere2"] setOpacity:0.0];
    
    //reorder
    [_sky setRenderingOrder:-5];
    [[self node:@"Sphere2"] setRenderingOrder:-4];
    
    // configure scene
    [self.sceneView setPlaying:YES];
    [self.sceneView.scene setPaused:NO];
    
    SCNNode *vortex = [self node:@"Circle-vfx-xmove-1"];
    SCNNode *sun = [self node:@"shineSun-vfx"];
    
    [self.sky setHidden:NO];
    [vortex setOpacity:0.0];
    [sun setOpacity:0.0];
    
    [self.sceneView.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        
        if ([child.name containsString:@"Fumina"]) {
            [child setOpacity:0.0];
        }
        if ([child.name containsString:@"Stage"]) {
            
            [child setOpacity:1.0];
            [child setHidden:NO];
            [child setEulerAngles:SCNVector3Zero];
            [child setScale:SCNVector3Make(1.8, 1.8, 1.8)]; //set 2x scale to display other stages too.
            // spin all of them
            SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0 z:0.5 duration:(2.0)]];
            [child runAction:rotate];
            // applies to all nodes
            [child removeAllParticleSystems];
            
            // extract name
            //subdivide its name
            NSArray *cmd = [child.name componentsSeparatedByString:@"_"];
            NSInteger stageID = [cmd.lastObject integerValue];
            NSLog(@"stageID: %ld VS maxStage: %ld", stageID, self.maxStage);
            if (stageID > self.maxStage) {
                [child setOpacity:0.1];
            } else {
                [child setOpacity:1.0];
            }

        }
        if ([child.name containsString:@"Phase"]) {
            [child setHidden:YES];
        }
    }];
    
    self.stageViewerCam = [self node:@"Camera-Free"];
    
    NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
    
    [save synchronize];
    
    if (![save objectForKey:@"user_newStage"]) {
        if ([save objectForKey:@"user_currentStage"]) {
            _currentStage = [[save objectForKey:@"user_currentStage"] integerValue];
        } else {
            _currentStage = 0;
        }
        [self resetPanPosition];
    } else {
        // has new stage!!
        _currentStage = [[save objectForKey:@"user_currentStage"] integerValue]-1;
        [self resetPanPosition];
    }
    
    // show scene that displays game map
    [self.parent fadeAudio:@"menuTheme" fadeDuration:0.0f];
    [self fadeToCam:[self node:@"Camera-Free"] fadeDuration:1.0 completion:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
        
    BOOL isNewStage = NO;
    if ([save objectForKey:@"user_newStage"]) {
        isNewStage = YES;
        [save removeObjectForKey:@"user_newStage"];
        [save synchronize];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.sceneView setAlpha:1.0];
    } completion:^(BOOL finished) {
        
        if (isNewStage == YES) {
            // get data
            self.currentStage = [[save objectForKey:@"user_currentStage"] integerValue];
            SCNNode *nextStage = [self hasStage:self.currentStage];
            self.selectedStage = nextStage;
            
            //pan from old position
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:2.0f];
            //
            [nextStage setOpacity:1.0];
            //
            [self.stageViewerCam setPosition:SCNVector3Make(nextStage.position.x, self.stageViewerCam.position.y, self.stageViewerCam.position.z)];
            [self.sky setPosition:self.stageViewerCam.position];
            [SCNTransaction commit];
            
            [self forStage:self.currentStage];
            
        }
        
    }];
    
}

- (void)resetPanPosition {
    SCNNode *nextStage = [self hasStage:_currentStage];

    if (nextStage) {
        _selectedStage = nextStage;
        //NSLog(@"panToFunction -> %ld node:%@", _currentStage, nextStage);
        [self panTo:nextStage.position.x];
        [self forStage:self.currentStage];
    }
}

- (void)swipeLeft:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // find and pan camera to certain position to display that stage.
        NSInteger nextInt = _currentStage+1;
        
        if (nextInt > _maxStage) {
            return;
        }
        
        SCNNode *nextStage = [self hasStage:nextInt];
        if (nextStage) {
            _selectedStage = nextStage;
            _currentStage = nextInt;
            [self panTo:nextStage.position.x];
            NSLog(@"LEFT %f", nextStage.position.x);
            [self forStage:nextInt];
        }
    }
}

- (void)swipeRight:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSInteger nextInt = _currentStage-1;
        SCNNode *nextStage = [self hasStage:nextInt];
        if (nextStage) {
            _selectedStage = nextStage;
            _currentStage = nextInt;
            [self panTo:nextStage.position.x];
            NSLog(@"RIGHT %f", nextStage.position.x);
            [self forStage:nextInt];
        }
    }
}

- (void)forStage:(NSInteger)stage {
    
    NSInteger bossStage = 27;
    NSInteger subBossStage = 9;
    
    if (stage == bossStage) {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:3.0];
        [[self node:@"Sphere2"] setOpacity:1.0];
        [[self node:@"bossFireBG-vfx-ymMove"] setOpacity:0.3];
        [[self node:@"bossFireBG2-vfx-ymMove"] setOpacity:0.0];
        [SCNTransaction commit];
    } else if (stage == subBossStage) {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:3.0];
        [[self node:@"Sphere2"] setOpacity:1.0];
        [[self node:@"bossFireBG2-vfx-ymMove"] setOpacity:0.3];
        [[self node:@"bossFireBG-vfx-ymMove"] setOpacity:0.0];
        [SCNTransaction commit];
    } else {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        [[self node:@"Sphere2"] setOpacity:0.0];
        [[self node:@"bossFireBG-vfx-ymMove"] setOpacity:0.0];
        [[self node:@"bossFireBG2-vfx-ymMove"] setOpacity:0.0];
        [SCNTransaction commit];
    }
}

- (void)panTo:(CGFloat)xPos {
    NSLog(@"panTo Called");
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.3f];
    [self.stageViewerCam setPosition:SCNVector3Make(xPos, self.stageViewerCam.position.y, self.stageViewerCam.position.z)];
    [_sky setPosition:self.stageViewerCam.position];
    [SCNTransaction commit];
}

- (SCNNode *)hasStage:(NSInteger)stage {
    
    __block NSString *cStage = [NSString stringWithFormat:@"%ld", stage];
    __block SCNNode *stageNode;
    
    [_sceneView.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        // find matching stage
        if ([node.name containsString:@"Stage"]) {
            //subdivide its name
            NSArray *cmd = [node.name componentsSeparatedByString:@"_"];
            if ([cmd.lastObject isEqualToString:cStage]) {
                stageNode = node;
                NSLog(@"hasStage %@",node.name);
                *stop = YES;
            }
        }
    }];
    
    return stageNode;
    
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

- (IBAction)startPlay:(id)sender {
    
    [self.view setUserInteractionEnabled:NO];

    // Removes all actions that are turning the stages
    [_sceneView.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if ([node.name containsString:@"Stage"]) {
            [node removeAllActions];
        }
    }];
    
    // Start : confirmation sound effects
    [_parent playSfx:@"confirm"];
    
    // zoomes into the stage
    [self panCamera:@"Camera-Sel" :3.0];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.sceneView.scene setPaused:YES];
        [self.sceneView setPlaying:NO];
        
        [UIView animateWithDuration:0.4 animations:^{
            [self.sceneView setAlpha:0.0];
        } completion:^(BOOL finished) {
            
            // prepare to close view
            [self dismissViewControllerAnimated:YES completion:^{
                [self.parent mpFuncUserDidSelectStage:self.selectedStage.name];
                [self clearupScene];
            }];
            
        }];
    });
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
    
    self.sceneView.overlaySKScene = nil;
    [self.sceneView setScene:nil];
    
    [_sceneView removeFromSuperview];
    _sceneView = nil;
    
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (SCNNode *)node:(NSString *)nodeName {
    return [self.sceneView.scene.rootNode childNodeWithName:nodeName recursively:YES];
}

- (void)panCamera:(NSString *)camName :(float)duration {
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:duration];
    [self.sceneView setPointOfView:[self node:camName]];
    [SCNTransaction commit];
    
}

@end
