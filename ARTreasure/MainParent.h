//
//  MainParent.h
//  ARTreasure
//
//  Created by Koji Murata on 15/12/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <SpriteKit/SpriteKit.h>
#import <ARKit/ARKit.h>

@interface MainParent : UIViewController

@property (strong, nonatomic) NSDictionary *dat;

@property (strong, nonatomic) AVAudioPlayer *introBgm;
@property (strong, nonatomic) AVAudioPlayer *loopBgm;

@property NSString *currentOST;

//current ARWorld - use as a reference to have seemless stage transition
@property (strong, nonatomic) ARWorldMap *userWorldMap;
@property (strong, nonatomic) ARAnchor *userAnchor;
@property (strong, nonatomic) NSMutableArray <AVAudioPlayer *>*sounds;

- (void)mpFuncDidStartGame;
- (void)mpFuncUserDidSelectStage:(NSString *)selectedStage;
- (void)mpFuncBackToMenu:(BOOL)increaseStage;

- (void)playSfx:(NSString *)name;
- (void)pauseAudio:(BOOL)paused;
- (void)playAudio:(NSString *)bgmId;
- (void)playSingleAudio:(NSString *)bgmId;
- (void)fadeAudio:(NSString *)bgmId fadeDuration:(float)duration;
- (void)restartStage;

@end
