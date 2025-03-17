//
//  AudioPlayer.m
//  Dayima
//
//  Created by sunzj on 15/12/23.
//
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic) NSTimer *audioPlayerTimer;
@property (nonatomic, copy) NSString *originalCategory;

@end

@implementation AudioPlayer

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        NSError *error = nil;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
        if (error) {
            NSLog(@"Error:%@", error);
            return nil;
        }

        audioPlayer.meteringEnabled = YES;
        audioPlayer.delegate = self;
        self.audioPlayer = audioPlayer;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    }

    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        NSError *error = nil;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (error) {
            NSLog(@"Error:%@", error);
            return nil;
        }

        audioPlayer.meteringEnabled = YES;
        audioPlayer.delegate = self;
        self.audioPlayer = audioPlayer;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)play {
    if (self.audioPlayer.duration <= 0) {
        return;
    }

    if (self.audioPlayerTimer) {
        [self.audioPlayerTimer invalidate];
        self.audioPlayerTimer = nil;
    }

    if (self.audioPlayer.isPlaying) {
        return;
    }

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(audioCheck) userInfo:nil repeats:YES];
    self.audioPlayerTimer = timer;

    self.originalCategory = [AVAudioSession sharedInstance].category;

    BOOL ret = [self.audioPlayer play];
    if (ret) {
        [self playingDidStart];
    } else {
        [self playingDidFinish];
    }
}

- (void)stop {
    if (self.audioPlayer.playing == YES) {
        [self.audioPlayer stop];
        [self playingDidFinish];
        if ([self.delegate respondsToSelector:@selector(audioPlayerDidStopPlaying:)]) {
            [self.delegate audioPlayerDidStopPlaying:self];
        }
    }
}
- (BOOL)isPlaying {
    return self.audioPlayer.playing;
}

- (void)audioCheck {
    if (!self.audioPlayer.isPlaying) {
        return;
    }

    [self.audioPlayer updateMeters];
    float average = [self.audioPlayer averagePowerForChannel:0];

    if ([self.delegate respondsToSelector:@selector(audioPlayerIsPlaying:currentTime:currentPower:)]) {
        [self.delegate audioPlayerIsPlaying:self currentTime:self.audioPlayer.currentTime currentPower:[self levelOfPower:average]];
    }
}

- (float)levelOfPower:(float)power {
    float level;
    const float minDecibels = -80.0f;
    float decibels = power;

    if (decibels < minDecibels) {
        level = 0.0f;
    } else if (decibels >= 0.0f) {
        level = 1.0f;
    } else {
        float root = 2.0;
        float minAmp = powf(10.0f, 0.05f * minDecibels);
        float inverseAmpRange = 1.0f / (1.0f - minAmp);
        float amp = powf(10.0f, 0.05f * decibels);
        float adjAmp = (amp - minAmp) * inverseAmpRange;

        level = powf(adjAmp, 1.0f / root);
    }
    return level;
}

- (void)playingDidStart {
    [self startProximityMonitoring];

    [self refreshSessionCategory];
}

- (void)playingDidFinish {
    [self stopProximityMonitoring];

    [[AVAudioSession sharedInstance] setCategory:self.originalCategory error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:)]) {
        [self.delegate audioPlayerDidFinishPlaying:self];
    }
}

- (void)startProximityMonitoring {
    if (self.supportsProximityMonitoring) {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
}

- (void)stopProximityMonitoring {
    if (self.supportsProximityMonitoring) {
        if (![UIDevice currentDevice].proximityState) {
            [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        }
    }
}

- (void)refreshSessionCategory {
    if ([UIDevice currentDevice].proximityState) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

- (void)proximityStateDidChange:(NSNotification *)notification {
    if (self.isPlaying) {
        [self refreshSessionCategory];
    } else {
        if (![UIDevice currentDevice].proximityState) {
            [self stopProximityMonitoring];
        }
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self playingDidFinish];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    [self playingDidFinish];
}

@end
