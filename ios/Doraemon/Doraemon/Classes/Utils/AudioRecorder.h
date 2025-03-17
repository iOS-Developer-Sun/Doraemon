//
//  AudioRecorder.h
//  Dayima
//
//  Created by sunzj on 15/12/23.
//
//

#import <Foundation/Foundation.h>

@class AudioRecorder;

@protocol AudioRecorderDelegate <NSObject>

@optional

- (void)audioRecorderIsRecording:(AudioRecorder *)audioRecorder currentTime:(NSTimeInterval)currentTime currentPower:(float)currentPower;
- (void)audioRecorderDidFinishRecording:(AudioRecorder *)audioRecorder duration:(NSTimeInterval)duration;

@end

@interface AudioRecorder : NSObject

@property (nonatomic, weak) id <AudioRecorderDelegate> delegate;
@property (nonatomic) NSTimeInterval maxTimeInterval;
@property (nonatomic, copy, readonly) NSString *filePath;

- (void)startRecording;
- (void)stopRecording;
- (void)cancelRecording;

@end

