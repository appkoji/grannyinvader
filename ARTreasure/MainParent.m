//
//  MainParent.m
//  ARTreasure
//
//  Created by Koji Murata on 15/12/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import "MainParent.h"
#import <GameKit/GameKit.h>
//Calling Views
#import "ViewController.h"
#import "TitleScreen.h"
#import "GameMenuScene.h"
#import "DialogController.h"

@interface MainParent ()
@property NSInteger selectedStage;
@property NSInteger gamePhase;
@end

@implementation MainParent

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // This is the main view where everystate is being controlled.
    _dat = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"logic" ofType:@"plist"]];
    _gamePhase = 0;
    
    // load sound effects to avoid lag
    _sounds = [NSMutableArray new];
    
    [_sounds addObject:[self preloadSfx:@"damage"]];
    [_sounds addObject:[self preloadSfx:@"fuminaShout"]];
    [_sounds addObject:[self preloadSfx:@"fuminaHit"]];
    [_sounds addObject:[self preloadSfx:@"positionConfirm"]];
    [_sounds addObject:[self preloadSfx:@"ARDetected"]];
    [_sounds addObject:[self preloadSfx:@"confirm"]];
    [_sounds addObject:[self preloadSfx:@"failed"]];
    [_sounds addObject:[self preloadSfx:@"fire"]];
    [_sounds addObject:[self preloadSfx:@"electro"]];
    [_sounds addObject:[self preloadSfx:@"cleared"]];
    [_sounds addObject:[self preloadSfx:@"pauseSfx"]];

    
    // loading save data
    NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
    NSInteger currentUserStage = [[save objectForKey:@"user_currentStage"] integerValue];
    NSUbiquitousKeyValueStore *cloudSave = [NSUbiquitousKeyValueStore defaultStore];
    
    // try applying cloud data to local storage everytime the app launches
    if ([cloudSave objectForKey:@"user_currentStage"]) {
        // get value from iCloud
        NSInteger cloudCurrentUserStage = [[cloudSave objectForKey:@"user_currentStage"] integerValue];
        // apply to local storage ONLY when cloud value is higher than local storage value
        if (cloudCurrentUserStage >= currentUserStage) {
            [save setObject:[NSNumber numberWithInteger:currentUserStage] forKey:@"user_currentStage"];
            [save synchronize];
        } else {
            //when local storage value is higher than iCloud value, apply data the otherway around
            [cloudSave setObject:[NSNumber numberWithInteger:currentUserStage] forKey:@"user_currentStage"];
            [cloudSave synchronize];
        }
    }
}

- (void)playSfx:(NSString *)name {
    [_sounds enumerateObjectsUsingBlock:^(AVAudioPlayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.accessibilityValue isEqualToString:name]) {
            if (obj.isPlaying) {
                [obj stop];
                [obj setCurrentTime:0.0];
            }
            [obj play];
            *stop = YES;
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    //
    [super viewWillAppear:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appMovedToBackground) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appMovedToBackground) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appMovedToForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    //
}

- (void)appMovedToBackground {
    /*
     - pause audio at all scenes
     - move to pause menu only when in game scene
     - do nothing in menu selection scene
    */
    [self pauseAudio:YES];
}

- (void)appMovedToForeground {
    /*
     - restart audio only when in game selection scene (gamePhase:0)
     - in game scene, do nothing and continuously display pause menu (gamePhase:1)
     */
    
    [self pauseAudio:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];

    if (self.view.tag != 1) {
        
        //load gameCenter
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        [localPlayer setAuthenticateHandler:^(UIViewController * _Nullable viewController, NSError * _Nullable error) {
            if (viewController) {
                [self presentViewController:viewController animated:YES completion:nil];
            }
        }];
        
        //load achievements
        [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray<GKAchievement *> * _Nullable achievements, NSError * _Nullable error) {
            [achievements enumerateObjectsUsingBlock:^(GKAchievement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"Loaded Achievement: %@", obj.identifier);
            }];
        }];
        
        NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
        if ([save objectForKey:@"intro"]) {
            // go to title screen if intro scene has passed
            TitleScreen *ts = [self.storyboard instantiateViewControllerWithIdentifier:@"TitleScreen"];
            ts.parent = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:ts animated:YES completion:nil];
            });
        } else {
            // go straight to boss meetup scene for first time gamers to motivate gamer to play the game
            
            /*
            DialogController *diag = [self.storyboard instantiateViewControllerWithIdentifier:@"DialogController"];
            diag.parent = self;
            diag.dialogs = [_dat objectForKey:@"dialogs"];
            diag.inDialogScene = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:diag animated:YES completion:^{
                    [diag run:@"bossIntro"];
                }];
            });
             */
            TitleScreen *ts = [self.storyboard instantiateViewControllerWithIdentifier:@"TitleScreen"];
            ts.parent = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:ts animated:YES completion:nil];
            });
            
            // For beta test
            //GameMenuScene *gms = [self.storyboard instantiateViewControllerWithIdentifier:@"GameMenuScene"];
            //gms.parent = self;
            //[self presentViewController:gms animated:YES completion:nil];
            
        }
        
        /*
        GameMenuScene *gms = [self.storyboard instantiateViewControllerWithIdentifier:@"GameMenuScene"];
        gms.parent = self;
        [self presentViewController:gms animated:YES completion:nil];
        */
         
        self.view.tag = 1;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Entry point: TitleScreen -> Stage Selection Menu
- (void)mpFuncDidStartGame {
    [self fadeAudio:@"menuTheme" fadeDuration:1.5f];

    // run Stage Selection Menu
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GameMenuScene *gms = [self.storyboard instantiateViewControllerWithIdentifier:@"GameMenuScene"];
        gms.parent = self;
        [self presentViewController:gms animated:YES completion:nil];
    });
    
}

// Entry point: Stage selection -> Game
- (void)mpFuncUserDidSelectStage:(NSString *)selectedStage {
    //
    [self fadeAudio:nil fadeDuration:1.0];
    // start gameSession
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ViewController *game = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        game.parent = self;
        game.selectedStage = selectedStage;
        self.selectedStage = [[selectedStage componentsSeparatedByString:@"_"].lastObject integerValue];
        [self presentViewController:game animated:YES completion:^{
            [game prepareToRunStage];
        }];
    });
}

- (void)restartStage {
    [self fadeAudio:nil fadeDuration:0.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ViewController *game = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        game.parent = self;
        game.selectedStage = [NSString stringWithFormat:@"Stage_MultiPlayer_%ld",self.selectedStage];
        [self presentViewController:game animated:YES completion:^{
            [game prepareToRunStage];
        }];
    });
}

// Entry point: Game -> Stage Selection
- (void)mpFuncBackToMenu:(BOOL)increaseStage {
    
    [self fadeAudio:@"menuTheme" fadeDuration:1.0];
    
    // cater local/iCloud stages
    NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *iCloudSave = [NSUbiquitousKeyValueStore defaultStore];
    NSInteger currentUserStage = [[save objectForKey:@"user_currentStage"] integerValue];

    //increase stage
    if (increaseStage == YES) {
        NSUInteger maxStage = 27;
        
        /// check if current stage if the selected stage are equal...
        if (currentUserStage == self.selectedStage && currentUserStage < maxStage) {
            // Apply to local storage
            [save setObject:[NSNumber numberWithInteger:currentUserStage+1] forKey:@"user_currentStage"];
            [save setObject:@"YES" forKey:@"user_newStage"];
            [save synchronize];
            // Apply to iCloud too
            [iCloudSave setObject:[NSNumber numberWithInteger:currentUserStage+1] forKey:@"user_currentStage"];
            [iCloudSave synchronize];
        }
        
    }
    
    // run Stage Selection Menu
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GameMenuScene *gms = [self.storyboard instantiateViewControllerWithIdentifier:@"GameMenuScene"];
        gms.parent = self;
        gms.currentStage = currentUserStage;
        [self presentViewController:gms animated:YES completion:nil];
    });
    
}

- (AVAudioPlayer *)preloadSfx:(NSString *)name {
    NSString *content = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"art.scnassets/%@",name] ofType:@"mp3"];
    @try {
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:content] error:nil];
        [player setAccessibilityValue:name];
        NSUserDefaults *save = [NSUserDefaults standardUserDefaults];
        if ([save objectForKey:@"sfxVolume"]) {
            [player setVolume:[[save objectForKey:@"sfxVolume"] floatValue]];
        } else {
            [player setVolume:0.3];
        }
        [player prepareToPlay];
        return player;
    } @catch (NSException *exception) {
        NSLog(@"Error loading sound file");
    }
    return nil;
}

- (void)playAudio:(NSString *)bgmId {
    
    //return;
    NSArray <NSString *>*fn = [[[_dat objectForKey:@"audio"] objectForKey:bgmId] componentsSeparatedByString:@"/"];
    NSString *path1 = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"art.scnassets/%@",fn[0]] ofType:@"mp3"];
    NSString *path2 = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"art.scnassets/%@",fn[1]] ofType:@"mp3"];
    NSError *error;
    
    NSData *data1 = [NSData dataWithContentsOfFile:path1 options:NSDataReadingMapped error:&error];
    NSData *data2 = [NSData dataWithContentsOfFile:path2 options:NSDataReadingMapped error:&error];
    path1 = nil;
    path2 = nil;
    
    if (!data1) {
        if (error) {
            @throw error;
        }
    } if (!data2) {
        if (error) {
            @throw error;
        }
    }
    
    _currentOST = bgmId;
    self.introBgm = data1 ? [[AVAudioPlayer alloc] initWithData:data1 error:&error] : nil;
    self.loopBgm = data2 ? [[AVAudioPlayer alloc] initWithData:data2 error:&error] : nil;
    data1 = nil;
    data2 = nil;
    
    if (self.introBgm && self.loopBgm) {
        // rethread
        NSLog(@"playing OST Audio");
        [self.introBgm stop];
        [self.loopBgm stop];
        [self.introBgm prepareToPlay];
        [self.loopBgm prepareToPlay];
        [self.introBgm setVolume:0.7f];
        
        [self.loopBgm setVolume:0.0];
        [self.loopBgm setNumberOfLoops:-1];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.loopBgm play];
            [self.introBgm play];
            [self.loopBgm stop];
            [self.loopBgm playAtTime:self.loopBgm.deviceCurrentTime + self.introBgm.duration];
            [self.loopBgm setVolume:0.7f];
        });
    }
    
}

- (void)playSingleAudio:(NSString *)bgmId {
    
    //return;
    NSString *path1 = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"art.scnassets/%@",bgmId] ofType:@"mp3"];
    NSError *error;
    NSData *data1 = [NSData dataWithContentsOfFile:path1 options:NSDataReadingMapped error:&error];
    path1 = nil;
    
    if (!data1) {
        if (error) {
            @throw error;
        }
    }
    
    _currentOST = bgmId;
    self.loopBgm = data1 ? [[AVAudioPlayer alloc] initWithData:data1 error:&error] : nil;
    data1 = nil;
    
    if (self.loopBgm) {
        // rethread
        NSLog(@"playing OST Audio");
        [self.loopBgm play];
        [self.loopBgm setVolume:0.7f];
    }
    
}

- (void)pauseAudio:(BOOL)paused {
    
    if (paused) {
        // pause audio
        [self.loopBgm stop];
        [self.introBgm stop];
    } else {
        //play current audio
        [self.loopBgm play];
    }
    
}

- (void)fadeAudio:(NSString *)bgmId fadeDuration:(float)duration {
    
    if (_currentOST != bgmId) {
        
        if (duration > 0.05) {
            [_introBgm setVolume:0.0 fadeDuration:duration];
            [_loopBgm setVolume:0.0 fadeDuration:duration];
            
            if (bgmId) {
                duration += 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (bgmId) {
                        [self playAudio:bgmId];
                    }
                });
            }
        } else {
            //no duration, of existing audio
            [_introBgm setVolume:0.0 fadeDuration:duration];
            [_loopBgm setVolume:0.0 fadeDuration:duration];
            if (bgmId) {
                // just play
                [self playAudio:bgmId];
            }
        }
    } else {
        NSLog(@"ignore OST is already playing");
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
