//
//  RadioKit.h
//  RadioKit  aka  Stormy's Radio Kit  (SRK)
//
//  Created by Brian Stormont on 11/24/09.
//  Copyright 2009 Stormy Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

enum SRK_STATUS_TYPE {
	SRK_STATUS_STOPPED = 0,
	SRK_STATUS_CONNECTING,
	SRK_STATUS_BUFFERING,
	SRK_STATUS_PLAYING,
	SRK_STATUS_PAUSED,
};

enum SRK_URL_TYPE {
    SRK_RAW_STREAM = 0,
    SRK_PLS,
    SRK_M3U
};

@protocol StormysRadioKitDelegate
@optional
- (void) SRKConnecting;
- (void) SRKIsBuffering;
- (void) SRKPlayStarted;
- (void) SRKPlayStopped;
- (void) SRKPlayPaused;
- (void) SRKNoNetworkFound;
- (void) SRKMetaChanged;
- (void) SRKRealtimeMetaChanged:(NSString *)title withUrl: (NSString *)url;
- (void) SRKBadContent;
- (void) SRKMissingContent;
- (void) SRKHttpError:(CFIndex)errorCode;
- (void) SRKFileComplete;   // sent when a downloadable file has finished playing
- (void) SRKURLNotFound;
- (void) SRKTimeoutExceeded;
- (void) SRKQueueExhausted;
- (void) SRKAudioWillBeSuspended;
- (void) SRKAudioSuspended;
- (void) SRKAudioResumed;
- (void) SRKRecordingStopped: (NSException *) exception;
- (void) SRKTapCreated;
- (void) SRKTapDisposed;
@end

@interface RadioKit : NSObject{
	id delegate;
}
@property (nonatomic,retain) id delegate;
@property (nonatomic,readonly) NSString *currTitle;
@property (nonatomic,readonly) NSString *currUrl;
@property (nonatomic, readonly) NSUInteger throttledFileLengthInSeconds;
@property (nonatomic, readonly) bool isFileSeekAllowed;

- (id) initWithBufferCount: (unsigned int) bufferCount;

- (bool) authenticateLibraryWithKey1: (uint32_t)key1 andKey2: (uint32_t)key2;
- (void) setBufferWaitTime: (NSUInteger) waitTime;		// How much audio to accumulate (in seconds) in the buffer before playback starts
- (void) setBufferWaitTimeForFile: (NSUInteger) waitTime;		// How much audio to accumulate (in seconds) in the buffer before playback starts
- (void) setThrottleBypassTime: (NSUInteger) waitTime;

- (void) setStreamUrl: (NSString *)url isFile:(bool)isFile;  // sets the URL and if it is new, stops and restarts the stream
- (void) setStreamUrl: (NSString *)url isFile:(bool)isFile setType:(enum SRK_URL_TYPE)urlType;

- (void) setStreamURlWithOutRestart: (NSString *)url; // only changes the URL - does not try to restart the stream
- (NSString *) currStream;
- (void) stopStream;
- (void) pauseStream;
- (void) startStream;
- (enum SRK_STATUS_TYPE) getStreamStatus;
- (bool) isAudioPlaying;  // is audio playing - this is independent of the stream status of "playing" as we might not have a connection but still be playing from the buffer


- (void) rewind: (NSUInteger)seconds;
- (void) fastForward: (NSUInteger)seconds;

- (BOOL) isFastForwardAllowed: (NSUInteger) seconds;
- (BOOL) isRewindAllowed: (NSUInteger) seconds;

- (void) fastForwardToLive;
- (void) rewindToStart;

- (void) setContinuousBuffering: (BOOL) val;

// Buffer statistics
- (NSUInteger) maxBufferSize;
- (NSUInteger) currBufferUsage;
- (NSUInteger) currBufferPlaying;
- (NSUInteger) currBufferUsageInSeconds;
- (NSUInteger) maxBufferUsageInSeconds;
- (NSUInteger) timeShift;  // returns number of seconds we are time shifted in the past
- (NSUInteger) bufferByteOffset;  // returns offset at which the buffer starts ( for file downloads)
- (NSUInteger) filePlayTime; // current time offset we are in playing a file
- (NSUInteger) bufferWaitTime;

// Ice-cast / Shoutcast info field
- (NSInteger) bitRate;
- (char *) streamFormat;
- (NSString *) genre;

// Used to control fetching meta data from XML server (AudioVault XML formating)
- (void) setXMLMetaURL: (NSString *)url;
- (void) beginXMLMeta;
- (void) endXMLMeta;
- (NSString *) titleWithoutArtist;
- (NSString *) artist;
- (void) setStationTimeZone: (NSString *)timeZone;
- (void) setXmlDelay: (NSTimeInterval) delay;

// misc
- (void) setUserAgent: (NSString *) string;
- (void) setCustomHeader: (NSString *) string withValue: (NSString *) customValue;
- (void) setCustomParameter: (NSString *) string;

- (NSString *) version;
- (void) setDataTimeout: (NSUInteger) time;
- (void) setPauseTimeout: (NSUInteger) time;

-(void) setMetaEncoding: (NSStringEncoding) encoding;

// Audio level metering
- (void) enableLevelMetering;
- (void) getAudioLevels: (Float32 *) levels peakLevels: (Float32 *) peakLevels;

- (NSString *) finalUrlString;

- (void) playLocalFile: (NSString *) filename;

// Live365 XML parsing

- (void) setLive365MetaURL: (NSString *)url;
- (void) beginLive365Meta;
- (void) endLive365Meta;

//

- (AudioQueueRef) getAudioQueue;

// Recording API

- (void) startRecording: (NSString *)filename appendToFile: (BOOL) append resetStream: (BOOL) resetStream;
- (void) startRecording: (NSString *)filename appendToFile: (BOOL) append;
- (void) stopRecording;

// Audio Tap

- (void)configureTap:(AudioQueueProcessingTapCallback) callback
          clientData:(void *)clientData
               flags:(UInt32)flags
        outMaxFrames:(UInt32 *)processingMaxFrames
 outProcessingFormat:(AudioStreamBasicDescription *)processingFormat;

// Basic Authentication
- (void) enableBasicAuthentication: (NSString *) username password: (NSString *)password;
- (void) disableBasicAuthentication;

@end
