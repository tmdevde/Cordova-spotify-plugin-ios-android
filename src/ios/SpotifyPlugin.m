//
//  SpotifyPlugin.m
//
//#define kTokenSwapServiceURL "http://5.9.24.144:1039/swap"

// The URL to your token refresh endpoint
// If you don't provide a token refresh service url, the user will need to sign in again every time their token expires.

//#define kTokenRefreshServiceURL "http://5.9.24.144:1039/refresh"


#define kSessionUserDefaultsKey "SpotifySession"


#import "SpotifyPlugin.h"

#import <objc/runtime.h>

@interface SpotifyPlugin()<SPTAudioStreamingDelegate,SPTAudioStreamingPlaybackDelegate>
@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (atomic, readwrite) BOOL firstLoad;
@end;

@implementation SpotifyPlugin

- (void)myPluginMethod:(CDVInvokedUrlCommand*)command
{
    // Check command.arguments here.
}
- (id)init
{
    self = [super init];
}
-(void)login :(CDVInvokedUrlCommand*)command
{
    
    __weak SpotifyPlugin* weakSelf = self;
    // NSLog(@"SpotifyPlugin - %@ - %@",[command.arguments objectAtIndex:0],[command.arguments objectAtIndex:1]);
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.clientID =[command.arguments objectAtIndex:0];
    NSArray *arr = [NSArray arrayWithObjects:SPTAuthStreamingScope,SPTAuthUserFollowModifyScope,SPTAuthUserLibraryReadScope,SPTAuthUserFollowReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadEmailScope,SPTAuthUserReadTopScope, nil];
    auth.requestedScopes = arr;//@[SPTAuthStreamingScope];
    auth.redirectURL = [NSURL URLWithString:[command.arguments objectAtIndex:1]];
    if([command arguments].count==4 ){
        auth.tokenSwapURL = [NSURL URLWithString:[command.arguments objectAtIndex:2]];
        auth.tokenRefreshURL = [NSURL URLWithString:[command.arguments objectAtIndex:3]];
    }
    auth.sessionUserDefaultsKey = @kSessionUserDefaultsKey;
    NSString *responseType = @"token";
    
    __block id observer;
    
    [self.commandDelegate runInBackground:^{
        
        SPTAuthCallback callback = ^(NSError *error, SPTSession *session) {
            CDVPluginResult *pluginResult;
            
            if (error != nil) {
                if(error.code==400 && self.firstLoad == YES){
                        [self.player loginWithAccessToken:auth.session.accessToken];
                         [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onLogedIn(['logged in'])"];
                    }else{
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                        [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onDidNotLogin(['Did not login'])"];

                    }
            } else {
                pluginResult = [CDVPluginResult
                                resultWithStatus:CDVCommandStatus_OK
                                ];
                auth.session = session;
                SPTAuth *auth = [SPTAuth defaultInstance];
                if (self.player == nil) {
                    NSError *error = nil;
                    self.player = [SPTAudioStreamingController sharedInstance];
                    if ([self.player startWithClientId:auth.clientID audioController:nil allowCaching:YES error:&error]) {
                        self.player.delegate = self;
                        self.player.playbackDelegate = self;
                        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
                        [self.player loginWithAccessToken:auth.session.accessToken];
                        NSLog(@"SpotifyPlugin player init");
                        [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onLogedIn(['logged in'])"];
                    } else {
                        self.player = nil;
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error init" message:[error description] preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                        
                    }
                }
            }
            
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        };
        
        observer = [[NSNotificationCenter defaultCenter]
                    addObserverForName:CDVPluginHandleOpenURLNotification
                    object:nil queue:nil usingBlock:^(NSNotification *note) {
                        NSURL *url = [note object];
                        SPTAuth *auth = [SPTAuth defaultInstance];
                        
                        if ([auth canHandleURL:url]) {
                            [auth handleAuthCallbackWithTriggeredAuthURL:url callback:callback];
                            return;
                        }
                        
                        
                        if ([responseType isEqualToString:@"token"])
                            return [[SPTAuth defaultInstance]
                                    handleAuthCallbackWithTriggeredAuthURL:url
                                    callback:callback];
                    }
                    ];
        
        if ([SPTAuth supportsApplicationAuthentication]){
            [[UIApplication sharedApplication] openURL:auth.spotifyAppAuthenticationURL];
        }else{
            [[UIApplication sharedApplication] openURL:auth.spotifyWebAuthenticationURL];
        }
    }];

   
}
-(void)auth:(CDVInvokedUrlCommand*)command{
    SPTAuth *auth = [SPTAuth defaultInstance];
    if (self.player == nil) {
        NSError *error = nil;
        self.player = [SPTAudioStreamingController sharedInstance];
        if ([self.player startWithClientId:auth.clientID audioController:nil allowCaching:YES error:&error]) {
            self.player.delegate = self;
            self.player.playbackDelegate = self;
            self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
            [self.player loginWithAccessToken:[command.arguments objectAtIndex:0]];
            NSLog(@"SpotifyPlugin player init");
            [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onLogedIn(['logged in'])"];
        } else {
            self.player = nil;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error init" message:[error description] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            
        }
    }
}


-(void)getToken:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult;
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:[[[SPTAuth defaultInstance] session] accessToken]];
    [arr addObject:[[[SPTAuth defaultInstance] session] encryptedRefreshToken]];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:arr];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}
-(void)play:(CDVInvokedUrlCommand*)command
{
    NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onPlayError(['"];
   
    NSString * str1 = [command.arguments objectAtIndex:0];
    NSLog(@"SpotifyPlayer track %@",str1);
    if(![self.player delegate]){
        [str appendFormat:@"player not initialized'])"];
          [self.commandDelegate evalJs:str];
    }
    [self.player playSpotifyURI:str1 startingWithIndex:0 startingWithPosition:0 callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** failed to play: %@", error);
            [str appendFormat:@"%@'])",error];
            [self.commandDelegate evalJs:str];
            return;
        }
    }];
}
-(void)pause:(CDVInvokedUrlCommand*)command
{
    NSLog(@"SpotifyPlayer action play/pause");
    [self.player setIsPlaying:!self.player.playbackState.isPlaying callback:nil];
}
-(void)next:(CDVInvokedUrlCommand*)command
{
    NSLog(@"SpotifyPlayer action next");
    [self.player skipNext:nil];
    [self myPluginMethod:command];
    
}
-(void)prev:(CDVInvokedUrlCommand*)command
{
    NSLog(@"SpotifyPlayer action prev");
    [self.player skipPrevious:nil];
}
-(void)logout:(CDVInvokedUrlCommand*)command
{
    NSLog(@"SpotifyPlayer action logout");
   if (self.player) {
        [self.player setIsPlaying:NO callback:nil];
        [self.player logout];
        //SPTAuth *auth =[SPTAuth defaultInstance];
        // [[UIApplication sharedApplication] openURL:auth.spotifyWebAuthenticationURL];
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
            if ([cookie.domain rangeOfString:@"spotify."].length > 0 ||
                [cookie.domain rangeOfString:@"facebook."].length > 0) {
                [storage deleteCookie:cookie];
            }
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
      
    }
}
-(void)seek:(CDVInvokedUrlCommand*)command
{
    NSTimeInterval offset = ((NSNumber *)[command.arguments objectAtIndex:0]).doubleValue;
    offset=self.player.metadata.currentTrack.duration * offset/100;
    [self.commandDelegate runInBackground:^{
        
        
        
        [self.player seekTo:offset callback:^(NSError *error) {
            CDVPluginResult *pluginResult;
            
            if (error != nil) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error.localizedDescription];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
    NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onAudioFlush(["];
    [str appendFormat:@"%f])",offset];
    
    [self.commandDelegate evalJs:str];
    
    NSLog(@"SpotifyPlayer action seek %f ms",offset);
}
    -(void)seekTo:(CDVInvokedUrlCommand*)command
    {
        NSTimeInterval offset = ((NSNumber *)[command.arguments objectAtIndex:0]).doubleValue;
        if(offset > 0 && offset < self.player.metadata.currentTrack.duration){
        [self.commandDelegate runInBackground:^{
            
            
            
            [self.player seekTo:offset callback:^(NSError *error) {
                CDVPluginResult *pluginResult;
                
                if (error != nil) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error.localizedDescription];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                }
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
        }];
        NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onAudioFlush(["];
        [str appendFormat:@"%f])",offset];
        
        [self.commandDelegate evalJs:str];
        
        NSLog(@"SpotifyPlayer action seek %f ms",offset);
        } else {
            NSString *error = @"incorrect duration";
            NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onPlayError(['"];
            [str appendFormat:@"%@'])",error];
            [self.commandDelegate evalJs:str];
        }
    }
-(void)volume:(CDVInvokedUrlCommand*)command
{
    NSLog(@"SpotifyPlayer action volume%@", [command.arguments objectAtIndex:0]);
    
    [self.commandDelegate runInBackground:^{
        
        
        SPTVolume volume = [[command.arguments objectAtIndex:0] doubleValue];
        volume/=100;
        [self.player setVolume:volume callback:^(NSError *error) {
            CDVPluginResult *pluginResult;
            
            if (error != nil) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error.localizedDescription];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
    
    
}
/////////////////////////////////////////////////////////////////
//                          EVENTS                             //
////////////////////////////////////////////////////////////////

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
    
    if (isPlaying) {
        
        [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onPlay(['Player play'])"];
        
    } else {
        [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onPause(['Player paused'])"];
    }
}


-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeMetadata:(SPTPlaybackMetadata *)metadata {
    [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onTrackChanged(['Track changed'])"];
    NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onMetadataChanged(["];
    [str appendFormat:@"'%@',",metadata.currentTrack.name ];
    [str appendFormat:@"'%@',",metadata.currentTrack.artistName ];
    [str appendFormat:@"'%@',",metadata.currentTrack.albumName ];
    [str appendFormat:@"%f])",metadata.currentTrack.duration ];
    [self.commandDelegate evalJs:str];
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceivePlaybackEvent:(SpPlaybackEvent)event withName:(NSString *)name {
    NSLog(@"didReceivePlaybackEvent: %zd %@", event, name);
    NSLog(@"isPlaying=%d isRepeating=%d isShuffling=%d isActiveDevice=%d positionMs=%f",
          self.player.playbackState.isPlaying,
          self.player.playbackState.isRepeating,
          self.player.playbackState.isShuffling,
          self.player.playbackState.isActiveDevice,
          self.player.playbackState.position);
}
-(void)audioStreamingDidSkipToNextTrack:(SPTAudioStreamingController *)audioStreaming
{
    [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onNext(['Next trak'])"];
}
-(void)audioStreamingDidSkipToPreviousTrack:(SPTAudioStreamingController *)audioStreaming
{
    [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onPrev(['Previos trak'])"];
}
-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata
{
    if(trackMetadata != nil){
        [self.commandDelegate evalJs:@"window.cordova.plugins.SpotifyPlugin.Events.onTrackChanged(['Track changed'])"];
    }
}
-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didSeekToOffset:(NSTimeInterval)offset
{
}
- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePosition:(NSTimeInterval)position {
    NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onPosition("];
    [str appendFormat:@"%f)",position*1000];
    
    [self.commandDelegate evalJs:str];
    NSLog(@"SpotifyPlugin: %@",str);
}
-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeVolume:(SPTVolume)volume
{
    NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onVolumeChanged("];
    [str appendFormat:@"%f)",volume];
    
    [self.commandDelegate evalJs:str];
    
}
-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveError:(NSError *)error{
    NSLog(@"%@", error);
    NSMutableString *str = [NSMutableString stringWithString:@"window.cordova.plugins.SpotifyPlugin.Events.onPlayError(['"];
    [str appendFormat:@"%@'])",error];
    [self.commandDelegate evalJs:str];
}
@end
