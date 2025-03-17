//
//  AudioRecorder.m
//  Dayima
//
//  Created by sunzj on 15/12/23.
//
//

#import "AudioRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioRecorder () <AVAudioRecorderDelegate>

@property (nonatomic) AVAudioRecorder *audioRecorder;
@property (nonatomic) NSTimer *audioRecorderTimer;
@property (nonatomic, copy) NSString *originalCategory;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic) BOOL hasRecorded;

@end

@implementation AudioRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *audioPath = [self audioPath];
        NSURL *url = [NSURL fileURLWithPath:audioPath];
        NSDictionary *setting = [self audioSetting];
        NSError *error = nil;
        AVAudioRecorder *audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
        audioRecorder.delegate = self;
        audioRecorder.meteringEnabled = YES;
        _audioRecorder = audioRecorder;
        _filePath = audioPath.copy;
    }
    return self;
}

- (NSString *)filePath {
    if (!self.hasRecorded) {
        return nil;
    }
    return _filePath;
}

- (NSDictionary *)audioSetting {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    [dictionary setObject:@(8000) forKey:AVSampleRateKey];
    [dictionary setObject:@(1) forKey:AVNumberOfChannelsKey];
    [dictionary setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    [dictionary setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    [dictionary setObject:@(12800) forKey:AVEncoderBitRateKey];
    [dictionary setObject:@(AVAudioQualityHigh) forKey: AVEncoderAudioQualityKey];

    return dictionary.copy;
}

- (NSString *)audioPath { 
    NSString *fileName = [NSString stringWithFormat:@"%@.wav", @([[NSDate date] timeIntervalSince1970])];
    NSString *tmp = NSTemporaryDirectory();
    NSString *audioPath = [tmp stringByAppendingPathComponent:fileName];

    return audioPath;
}

- (void)audioCheck {
    if (!self.audioRecorder.isRecording) {
        return;
    }

    [self.audioRecorder updateMeters];
    float average = [self.audioRecorder averagePowerForChannel:0];
    if (self.maxTimeInterval > 0) {
        if (self.audioRecorder.currentTime >= self.maxTimeInterval) {
            [self stopRecording];
            return;
        }
    }

    if ([self.delegate respondsToSelector:@selector(audioRecorderIsRecording:currentTime:currentPower:)]) {
        [self.delegate audioRecorderIsRecording:self currentTime:self.audioRecorder.currentTime currentPower:[self levelOfPower:average]];
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

- (void)startRecording {
    if (self.audioRecorderTimer) {
        [self.audioRecorderTimer invalidate];
        self.audioRecorderTimer = nil;
    }

    if (self.audioRecorder.isRecording) {
        return;
    }

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(audioCheck) userInfo:nil repeats:YES];
    self.audioRecorderTimer = timer;

    self.originalCategory = [AVAudioSession sharedInstance].category;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    BOOL ret = [self.audioRecorder record];
    if (!ret) {
        self.hasRecorded = NO;
        [self stopRecording];
    }
}

- (void)stopRecording {
    if (self.audioRecorderTimer) {
        [self.audioRecorderTimer invalidate];
        self.audioRecorderTimer = nil;
    }

    if (self.audioRecorder.isRecording == NO) {
        return;
    }

    [self.audioRecorder stop];
    [[AVAudioSession sharedInstance] setCategory:self.originalCategory error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)cancelRecording {
    if (self.audioRecorderTimer) {
        [self.audioRecorderTimer invalidate];
        self.audioRecorderTimer = nil;
    }

    if (self.audioRecorder.isRecording == NO) {
        return;
    }

    [self.audioRecorder stop];
    [self.audioRecorder deleteRecording];
    [[AVAudioSession sharedInstance] setCategory:self.originalCategory error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
    self.hasRecorded = flag;
    if ([self.delegate respondsToSelector:@selector(audioRecorderDidFinishRecording:duration:)]) {
        [self.delegate audioRecorderDidFinishRecording:self duration:player.duration];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    self.hasRecorded = NO;
    if ([self.delegate respondsToSelector:@selector(audioRecorderDidFinishRecording:duration:)]) {
        [self.delegate audioRecorderDidFinishRecording:self duration:0];
    }
}

@end
