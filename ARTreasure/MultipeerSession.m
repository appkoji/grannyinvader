//
//  MultipeerSession.m
//  ARTreasure
//
//  Created by Koji Murata on 24/07/2018.
//  Copyright © 2018 KojiGames. All rights reserved.
//

#import "MultipeerSession.h"
#import "ViewController.h"

@interface MultipeerSession ()
//
@property MCPeerID *peerId;
@property NSString *serviceType;
@property NSTimeInterval currentTime;
//
@end


@implementation MultipeerSession

// This function must not run more than once!
- (void)startMultiplayerSession {
    
    self.multiplayerModeIsActive = NO;
    
    // All device must start this session to play multiplayer.
    NSString *deviceName = [[UIDevice currentDevice] name];
    self.peerId = [[MCPeerID alloc] initWithDisplayName:deviceName];
    
    _session = [[MCSession alloc] initWithPeer:self.peerId securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    _session.delegate = self;
    
    _serviceType = @"appkoji-fbaba";
    
    //[_parent showSystemLabelWith:@"システム起動"];
    
}


// Multiplayer game play mechanics

//!@abstract sends important data reliably to other peer
- (void)sendGameDataToPeer:(id)data {
    
    NSLog(@"Sending Reliable Data %@", data);
    
    //1.
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:NO error:nil];
    
    
    
    //2.
    @try {
        [_session sendData:archivedData toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    } @catch (NSException *exception) {
        NSLog(@"error sending data");
    }
    
}

- (void)sendQuickDataToPeer:(id)data {
    
    NSLog(@"Sending QuickData %@", data);

    //1.
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:NO error:nil];
    
    //2.
    @try {
        [_session sendData:archivedData toPeers:_session.connectedPeers withMode:MCSessionSendDataUnreliable error:nil];
    } @catch (NSException *exception) {
        NSLog(@"error sending data");
    }
    
}


//


- (void)startSessionAsParticipant {
    // advertise the availability player.
    _mcAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerId discoveryInfo:nil serviceType:_serviceType];
    _mcAdvertiser.delegate = self;
    [_mcAdvertiser startAdvertisingPeer];
}

- (void)startSessionAsHost {
    // stop advertising, but now start searching for other possible participants
    [_mcAdvertiser stopAdvertisingPeer];
    // browse
    _mcBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerId serviceType:_serviceType];
    _mcBrowser.delegate = self;
    [_mcBrowser startBrowsingForPeers];
}

- (void)browser:(nonnull MCNearbyServiceBrowser *)browser foundPeer:(nonnull MCPeerID *)peerID withDiscoveryInfo:(nullable NSDictionary<NSString *,NSString *> *)info {
    
    // display information on transcieving peer sessions
    NSString *lbl = [NSString stringWithFormat:@"時空メカ「%@」が近くにいます!", peerID.displayName];
    [_parent showSystemLabelWith:lbl];
    
    // Invite all peers found around this player...
    [browser invitePeer:peerID toSession:_session withContext:nil timeout:15];
    
}

- (void)advertiser:(nonnull MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(nonnull MCPeerID *)peerID withContext:(nullable NSData *)context invitationHandler:(nonnull void (^)(BOOL, MCSession * _Nullable))invitationHandler {
    
    NSTimeInterval peerRunningTime;
    [context getBytes:&peerRunningTime length:sizeof(NSTimeInterval)];
    
    NSString *messageTitle = [NSString stringWithFormat:@"マルチプレーヤー"];
    NSString *message = [NSString stringWithFormat:@"%@さんのゲームに参加しますか？", peerID.displayName];
    
    // ask player whether to connect with this peer
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:messageTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *connect = [UIAlertAction actionWithTitle:@"参加する" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        invitationHandler(true, self.session);
        [advertiser stopAdvertisingPeer];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"キャンセル" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:connect];
    [alertController addAction:cancel];
    
    [_parent presentViewController:alertController animated:YES completion:nil];
    
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    if (state == MCSessionStateConnected) {
        
        if ([_parent isHost] == YES) {
            
        } else {
            // peer
            NSString *lbl = [NSString stringWithFormat:@"しばらくお待ちください..."];
            [_parent showSystemLabelWith:lbl];
        }
        
        // tell everyone that multiplayer mode is active
        self.multiplayerModeIsActive = YES;
        
    }
    if (state == MCSessionStateConnecting) {
        NSString *lbl = [NSString stringWithFormat:@"%@へ接続中", peerID.displayName];
        [_parent showSystemLabelWith:lbl];
    }
    if (state == MCSessionStateNotConnected) {
        if ([_parent isHost] == YES) {
            NSString *lbl = [NSString stringWithFormat:@"Peerへの接続に失敗しました。"];
            [_parent showSystemLabelWith:lbl];
        } else {
            NSString *lbl = [NSString stringWithFormat:@"ホストへの接続に失敗しました"];
            [_parent showSystemLabelWith:lbl];
        }
    }
}




////

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler {
    NSLog(@"did receive certificate");
    certificateHandler(YES);
}

- (void)session:(nonnull MCSession *)session didFinishReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error {
    
}


- (void)session:(nonnull MCSession *)session didReceiveData:(nonnull NSData *)data fromPeer:(nonnull MCPeerID *)peerID {
    [self didReceivedData:data fromPeer:peerID];
}


- (void)session:(nonnull MCSession *)session didReceiveStream:(nonnull NSInputStream *)stream withName:(nonnull NSString *)streamName fromPeer:(nonnull MCPeerID *)peerID {
    
}

- (void)session:(nonnull MCSession *)session didStartReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID withProgress:(nonnull NSProgress *)progress {
    
}

- (void)browser:(nonnull MCNearbyServiceBrowser *)browser lostPeer:(nonnull MCPeerID *)peerID {
    
}

- (void)didReceivedData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    NSSet *setOfClasses = [NSSet setWithObjects:[NSString class],[NSArray class],[ARAnchor class],[ARWorldMap class],[NSNumber class], nil];
    id unarchivedData = [NSKeyedUnarchiver unarchivedObjectOfClasses:setOfClasses fromData:data error:nil];
    
    if ([_parent isHost] == NO) {
        // this method must not be ran by host, only peer
        
        if ([unarchivedData isKindOfClass:[ARWorldMap class]]) {
            ARWorldMap *worldMap = (ARWorldMap *)unarchivedData;
            NSLog(@"did received ARWorldMap %@", worldMap);
            [_parent setCurrentWorldMap:worldMap];
            
            // after receiving worldmap, play game immediately
            [_parent performSelectorOnMainThread:@selector(runMultiplayerGame) withObject:nil waitUntilDone:NO];
        }
    } else {
    }
    
    // all multiplayer devices will receive this data
    // This command should only run to peer that didn't send this data
    if ([unarchivedData isKindOfClass:[NSString class]]) {
        NSString *stringdata = (NSString *)unarchivedData;
        if ([stringdata hasPrefix:@""]) {
            
        }
    }
    
    // all peers will go through this argument
    if ([peerID isEqual:self.peerId] == NO) {
        // This command should only run to peer that didn't send this data
        if ([unarchivedData isKindOfClass:[NSString class]]) {
            NSLog(@"did received quick data %@ from peer %@", unarchivedData, peerID.displayName);
            //[_parent multiplayerRunQuickMethod:unarchivedData];
        }
    }
    
}


@end
