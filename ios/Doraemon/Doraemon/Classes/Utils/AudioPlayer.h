//
//  AudioPlayer.h
//  Dayima
//
//  Created by sunzj on 15/12/23.
//
//

#import <UIKit/UIKit.h>

@class AudioPlayer;

@protocol AudioPlayerDelegate <NSObject>

@optional

- (void)audioPlayerIsPlaying:(AudioPlayer *)audioPlayer currentTime:(NSTimeInterval)currentTime currentPower:(float)currentPower;
- (void)audioPlayerDidFinishPlaying:(AudioPlayer *)audioPlayer;
- (void)audioPlayerDidStopPlaying:(AudioPlayer *)audioPlayer;

@end

@interface AudioPlayer : NSObject

@property (nonatomic, weak) id <AudioPlayerDelegate> delegate;
@property (nonatomic) BOOL supportsProximityMonitoring;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithData:(NSData *)data;

- (void)play;
- (void)stop;
- (BOOL)isPlaying;

@end
