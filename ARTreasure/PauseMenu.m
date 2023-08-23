//
//  PauseMenu.m
//  ARTreasure
//
//  Created by Koji Murata on 14/08/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import "PauseMenu.h"
#import "ViewController.h"

@interface PauseMenu ()

@property (strong, nonatomic) IBOutlet UIButton *resumeBtn;
@property (strong, nonatomic) IBOutlet UIButton *homeBtn;
@property (strong, nonatomic) IBOutlet UIButton *repeatBtn;

- (IBAction)pauseMenuActions:(id)sender;

@end

@implementation PauseMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)pauseMenuActions:(id)sender {
    //
    [self dismissViewControllerAnimated:YES completion:^{
        //
        if (sender == self.resumeBtn) {
            //
            [[self.parent sceneView] setPlaying:YES];
            [[self.parent sceneView].overlaySKScene setPaused:NO];
            [[self.parent sceneView].scene setPaused:NO];
            [[self.parent sceneView].session runWithConfiguration:[self.parent arCongifuration]];
            [self.parent pauseSceneReturnAction:2];
        } else if (sender == self.repeatBtn) {
            // restart
            [self.parent pauseSceneReturnAction:1];
        }  else {
            // exit
            [self.parent pauseSceneReturnAction:0];
        }
        //
    }];
    
    
}


- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
