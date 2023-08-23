//
//  MultipeerSession.h
//  ARTreasure
//
//  Created by Koji Murata on 24/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>


NS_ASSUME_NONNULL_BEGIN
@interface MultipeerSession : UIViewController <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

@property (weak, nonatomic) id parent;
@property BOOL multiplayerModeIsActive;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *mcAdvertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *mcBrowser;
@property (strong, nonatomic) NSData *receivedData;
@property (strong, nonatomic) MCSession *session;

// to initialize
- (void)startMultiplayerSession;

- (void)startSessionAsParticipant;
- (void)startSessionAsHost;

- (void)sendGameDataToPeer:(id)data;

//!@abstract attempts to send data to other connected devices in Multiplayer mode unreliably but quick!.
- (void)sendQuickDataToPeer:(id)data;
@end

NS_ASSUME_NONNULL_END
