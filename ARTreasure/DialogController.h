//
//  DialogController.h
//  ARTreasure
//
//  Created by Koji Murata on 24/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DialogController : UIViewController

@property (weak, nonatomic) NSDictionary *dialogs;
@property (weak, nonatomic) id parent;
@property (strong, nonatomic) IBOutlet SCNView *dialogSceneView;
@property (nonatomic, strong) SKScene *spriteScene;

@property BOOL inDialogScene;

- (void)run:(NSString *)dialogIdentifier;
- (void)skNodeAction:(NSDictionary *)skAction;
- (SKNode *)skNode:(NSString *)nodeName;
- (void)deleteSKNode:(SKNode *)delNd;

@end

NS_ASSUME_NONNULL_END
