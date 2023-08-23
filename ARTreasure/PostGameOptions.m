//
//  PostGameOptions.m
//  ARTreasure
//
//  Created by Koji Murata on 15/08/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import "PostGameOptions.h"
#import "ViewController.h"
#import "MainParent.h"

@interface PostGameOptions ()

- (IBAction)pgAction:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *cgTitle;
@property (nonatomic, strong) UIViewController *creditView;

@property (strong, nonatomic) NSTimer *creditTimer;
@property NSTimeInterval t;
@property (strong, nonatomic) IBOutlet UIImageView *tapEllipse;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (strong, nonatomic) IBOutlet UIImageView *whiteBG;
@property (strong, nonatomic) IBOutlet UIImageView *theEndDisp;

@end

@implementation PostGameOptions

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // displays
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
    
    // add a subview of credit contents
    _creditView = [self.storyboard instantiateViewControllerWithIdentifier:@"CreditLine"];
    [_creditView.view setAlpha:0.0];
    [_creditView.view setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.creditView.view];
    
    // set position
    [_creditView.view setFrame:CGRectMake(0, 0, 450, 7000)];
    
    // set center
    _t = 0;
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.view addGestureRecognizer:_tap];
    [self.view setTag:0];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    //fade out gameCleared label
    [_creditView.view setCenter:CGPointMake(self.cgTitle.center.x, _creditView.view.center.y+300)];
    
    //NSLog(@"creditView center %f - cgTitleCenter %f", _creditView.view.center.x, self.cgTitle.center.x);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // display rate on appStore after dismissing cgTitle
        
        [SKStoreReviewController requestReview];
        // display tap ellipse
        [self.tapEllipse.layer addAnimation:[self.parent pulseAnim] forKey:nil];
        [self.tapEllipse setHidden:NO];
        
    });
}

- (void)didTap:(UIGestureRecognizer *)recognizer {
    if (self.view.tag == 0) {
        
        [self.parent playSFX:@"confirm"];
        [self.view setTag:1];
        [self.tapEllipse setHidden:YES];
        
        [UIView animateWithDuration:1.0 animations:^{
            [self.cgTitle setAlpha:0.0];
        } completion:^(BOOL finished) {
            
            
            //lastBoss vs. normBoss
            if (self.isLastBoss == YES) {
                //Fade out audio
                [[self.parent parent] fadeAudio:nil fadeDuration:0.8];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self.parent parent] playSingleAudio:@"GrannyInvader-EndingTheme"];
                    [self startCreditSeq];
                });
                
            } else {
                // dismiss this view while calling back to main parent
                [self dismissViewControllerAnimated:YES completion:^{
                    [self.parent pauseSceneReturnAction:5];
                }];
            }
            
        }];
    }
}

- (void)startCreditSeq {
    
    // start moving upwards per pixel
    //__block CGFloat abCenter = [UIScreen mainScreen].bounds.size.height;
    
    self.creditTimer = [NSTimer scheduledTimerWithTimeInterval:(0.01) repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        [self.creditView.view setCenter:CGPointMake(self.cgTitle.center.x, self.creditView.view.center.y-0.63)];
        
        if (self.creditView.view.frame.origin.y < -6500 && self.view.tag == 1) {
            [self.view setTag:2];
            
            [UIView animateWithDuration:1.0 animations:^{
                [self.creditView.view setAlpha:0.0];
                [self.whiteBG setAlpha:0.0];
            } completion:^(BOOL finished) {
                [timer invalidate];
                [self dismissCreditAndDisplay];
            }];
            
        }
    }];
    
    [self.creditTimer fire];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.5 animations:^{
            [self.creditView.view setAlpha:1.0];
        }];
    });
    
}

- (void)dismissCreditAndDisplay {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.parent playSFX:@"complete!"];
        [UIView animateWithDuration:0.5 animations:^{
            [self.theEndDisp setAlpha:1.0];
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 animations:^{
                [self.theEndDisp setAlpha:0.0];
            } completion:^(BOOL finished) {
                
                // dismiss this view while calling back to main parent
                [self dismissViewControllerAnimated:YES completion:^{
                    [self.parent pauseSceneReturnAction:0];
                }];
                
            }];
        });
        
    });
    
}

- (IBAction)pgAction:(id)sender {

}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
