/**********************************************************************************
 * (c) 2017, Master Technology
 * Licensed under a MIT License
 *
 * Any questions please feel free to email me or put a issue up on the private repo
 * Version 0.1.0                                      Nathan@master-technology.com
 *********************************************************************************/

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VHelper.h"


int zhId = 0;

@interface VideoHelper  () < AVAssetDownloadDelegate >
{
    NSMutableArray *dict;
    NSMutableDictionary *tracking;

    AVAssetDownloadTask *lastAVAssetDownloadTask;

    NSThread *thread;
    NSLock *theLock;

    BOOL Lock;
    BOOL debugging;
    BOOL connected;
    long zId;

    AVAssetDownloadURLSession *avAssetDownloadSession;

    NSInteger cancelDownloadTimer;

}
@end

#pragma mark Public rountines used by NS

@implementation VideoHelper
- (instancetype)init;
{
    self = [super init];
    if (self) {
         zhId++;
         zId = zhId;
         NSLog(@"Initializing VideoHelper %ld", (long)zId);

    	 thread = [[NSThread alloc]initWithTarget:self selector:@selector(runQueue) object:nil];
    	 theLock = [[NSLock alloc] init];
	     Lock = true;
	     debugging = false;
	     dict = [NSMutableArray array];
	     tracking = [[NSMutableDictionary alloc] init];
	     cancelDownloadTimer = 0;
	     avAssetDownloadSession = nil;

         [thread start];
    } else {
       NSLog(@"VideoHelper INIT failed!");
    }
    return self;
}

/*
 Enabled debugging logging
*/
- (void)enableDebugging
{
    NSLog(@"Enabling Debugging Logs!");

    debugging = true;
    NSLog(@"Starting Delegate %ld Address %p", zId, _delegate);

}

/*
 Used to add an requests into the queue to be handled
*/
- (void)addObject: (NSDictionary *)zptObject
{
    [theLock lock];
      [dict addObject: zptObject];
      Lock = NO;
    [theLock unlock];

}


#pragma mark Private routines used by the thread to manage

/*
 Used to maintain a run loop
*/
- (void)runLoop: (float) length
{
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow: length];
        [runLoop runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
}

/* Do nothing (Selector) */
- (void)doNothing
{
  NSLog(@"Yes, I'm doing nothing!");
  // Yep do Nothing -- seems crazy doesn't it!
  return;
}

/*
Used to wait for the queue lock
 */
- (void)waitForLock
{
  do {
     if ([theLock tryLock]) {
       break;
     }
     [self runLoop:0.5];
  } while (true);
}

/*
 The command queue handler
*/
- (void)runQueue
{
        if (debugging) {
          NSLog(@"Staring Running Queue %ld", zId);
        }

	  [NSTimer scheduledTimerWithTimeInterval: FLT_MAX
                                     target: self selector: @selector(doNothing)
                                   userInfo: nil repeats:YES];

      bool curLock;

      NSDictionary *entry = nil;

      while ([[NSThread currentThread] isCancelled] == NO) {

          [self waitForLock];
          curLock = Lock;
          [theLock unlock];
	      while(curLock)
          {
            [self runLoop: 1.0];
            if ([theLock tryLock]) {
              curLock = Lock;
              [theLock unlock];
            }
          }

          long cnt;
	      do {
	            [self waitForLock];
	            cnt = dict.count;
	            [theLock unlock];
	            for (long i=0;i<cnt;i++) {
    	            [self waitForLock];
                    entry = [dict objectAtIndex: 0];

                    NSInteger cmd = [[entry valueForKey:@"command"] intValue];
                    NSInteger pid = [[entry valueForKey:@"id"] intValue];
                    NSInteger vid = [[entry valueForKey:@"dataNumber"] intValue];
                    AVURLAsset *asset = [entry objectForKey:@"AVAsset"];
                    NSString *data = [[entry valueForKey:@"dataString"] copy];
                    NSString *title = [[entry valueForKey:@"dataTitle"] copy];
                    [dict removeObjectAtIndex: 0];
                    [theLock unlock];

                    [self handleData: cmd data: data vid: vid pid: pid asset: asset title: title];
                    [self runLoop: 0.5];
                }
          } while (cnt > 0);

        // Reset our Lock
        [self waitForLock];
        Lock = YES;
        [theLock unlock];
      }

      if (debugging) {
        NSLog(@"Thread is quiting %ld", zId);
      }
      theLock = nil;
      thread = nil;
      dict = nil;
}


#pragma mark Routines to send data back to main ui thread (So NS can consume it)

/*
  Sends the actual data back to NS
*/
-(void)doSendToUI: (NSArray*)values
{
    if (debugging) {
      NSLog(@"Send to UI, on Main Thread!");
    }
    NSInteger pid = [[values objectAtIndex:0] intValue];
    NSString *data = [[values objectAtIndex:1] copy];
    NSInteger bitRate = [[values objectAtIndex:2] intValue];
    NSInteger error = [[values objectAtIndex:3] intValue];

    if([_delegate respondsToSelector:@selector(onEvent:data:bitRate:error:)]) {
      if(debugging) {
         NSLog(@"delegate selector is found!");
      }
      [_delegate onEvent:pid data:data bitRate:bitRate error:error];
    } else {
       NSLog(@"!!! delegate selector is NOT found, this is a critical issue !!! %p", _delegate);
    }
}

/*
 This receives the info from the thread then forwards it on to the doSendToUI for NativeScript
*/
-(void)sendToUI: (NSInteger)pid data:(NSString*)data bitRate:(NSInteger)bitRate error:(NSInteger)error
{
    if (debugging) {
      NSLog(@"Send to UI %ld, Data: %@, Error: %ld", (long)pid, data, (long)error);
    }
    if (!_delegate) {
      NSLog(@"_delegate is null!");
      return;
    }

    NSArray *vals = [NSArray arrayWithObjects: [NSNumber numberWithInt:(int)pid], data, [NSNumber numberWithInt:(int)bitRate], [NSNumber numberWithInt:(int)error], nil];
    [self performSelector:@selector(doSendToUI:) onThread:[NSThread mainThread] withObject:vals waitUntilDone:NO];
}


#pragma mark Incoming Queue Handler

/*
  Handles each request from the queue so we know what we are doing
*/
- (void)handleData: (NSInteger)command data:(NSString *)data vid: (NSInteger)vid pid:(NSInteger)pid asset: (AVURLAsset *)asset  title: (NSString *)title
{
    if (debugging) {
        NSLog(@"Handling Data Command: %ld, vid: %ld pid: %ld", (long)command, (long)vid, (long)pid);
    }

    switch (command) {
        case 0: [self closeConnection: pid]; break;
        case 1: [self setSetting: pid data:data vid:vid]; break;
        case 2: [self downloadVideo: pid data:data bitRate:vid asset: asset title: title]; break;
        case 3: [self cancelVideo: pid]; break;
        default:
            return;
    }
}


#pragma Handle Data helpers

/*
 Cancel the last video
*/
- (void)cancelVideo: (NSInteger)pid
{
   if (lastAVAssetDownloadTask != nil) {
      [lastAVAssetDownloadTask cancel];
      lastAVAssetDownloadTask = nil;
   }

   [self sendToUI: pid data:@"Cancelled" bitRate:0 error: 0];
}

/*
 Close connection
*/
- (void)closeConnection: (NSInteger)pid
{
   if (!connected) {
     NSLog(@"Calling Disconnect on already disconnected %ld", zId);
     return;
   }
   [self runLoop: 1.0];

   connected = NO;
    if (debugging) {
       NSLog(@"Closing connection %ld", zId);
    }

   [thread cancel];

   [self sendToUI: pid data:@"" bitRate:0 error: 0];
}

/*
 Set a setting
*/
- (void)setSetting: (NSInteger)pid data:(NSString *)data vid:(NSInteger)vid
{
  if (debugging) {
        NSLog(@"Setting Setting %@ %ld", data, vid);
  }

  // Currently we only support one setting, so we are just going to assign it
  cancelDownloadTimer = vid;
  [self sendToUI: pid data:@"" bitRate:0 error: 0];
}

/*
 This starts the download
*/
- (void)downloadVideo: (NSInteger)pid data:(NSString *)data bitRate:(NSInteger)bitRate asset:(AVURLAsset*)asset title:(NSString *)title
{
    if (debugging) {
      NSLog(@"Downloading %ld Video Connection %@", (long)pid, data);
    }

    // Generate a string version of the pid
    NSString *ppid = [NSString stringWithFormat:@"%ld",pid];

    // Track this connections start time
    tracking[ppid] = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];

    // Configure File to download
    AVURLAsset *hlsAsset;
     if (asset == nil || asset == [NSNull null]) {
        NSURL *assetURL;

        assetURL = [NSURL URLWithString:data];
        hlsAsset = [AVURLAsset assetWithURL:assetURL];
     } else {
        hlsAsset = asset;
     }

    if (avAssetDownloadSession == nil) {
       // Configure the Download Session
       NSURLSessionConfiguration *urlSessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"downloadedMedia"];
       urlSessionConfiguration.networkServiceType = NSURLNetworkServiceTypeBackground;

       avAssetDownloadSession = [AVAssetDownloadURLSession sessionWithConfiguration:urlSessionConfiguration assetDownloadDelegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }

    // Download Task
    AVAssetDownloadTask *avAssetDownloadTask = [avAssetDownloadSession assetDownloadTaskWithURLAsset:hlsAsset assetTitle:title assetArtworkData:nil options:@{AVAssetDownloadTaskMinimumRequiredMediaBitrateKey : @(bitRate)}];
    avAssetDownloadTask.taskDescription = ppid;

     // Start the Task
    [avAssetDownloadTask resume];

    // Track the last one to be able to cancel it...
    lastAVAssetDownloadTask = avAssetDownloadTask;
}


#pragma mark helpers

/*
 Calculate the foldersize easily; http://stackoverflow.com/questions/2188469/calculate-the-size-of-a-folder
*/
- (unsigned long long int)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;

    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }

    return fileSize;
}


#pragma mark - URLSession assetDownloadTask Delegates

/*
This is one of the handlers required for the AVAssetDownloader Delegates
*/
- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didResolveMediaSelection:(AVMediaSelection *)resolvedMediaSelection {
  // We don't need any code in this delegate
  if (debugging) {
    NSLog(@"Delegate: ResolveMediaSelection");
  }
}

/*
  This is the Delegate that gets called with a file is finished downloading
*/
- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didFinishDownloadingToURL:(NSURL *)location;
{
        // Get our PID
        NSString *ppid = assetDownloadTask.taskDescription;
        NSInteger pid = [ppid intValue];

        // Clear the task id, to eliminate duplicate notifications...
        assetDownloadTask.taskDescription = @"0";

        if (debugging) {
          NSLog(@"Delegate: download complete %ld", pid);
        }

        // Calculate the Total time taken
        NSInteger start = [tracking[ppid] intValue];
        NSInteger total = [[NSDate date] timeIntervalSince1970] - start;

        // Get the File Size
        unsigned long long int fileSize = [self folderSize: [location path]];
        if (debugging) {
           NSLog(@"Size: %llu, length: %ld total", fileSize, total );
        }

        // Don't allow a divide by zero...
        if (total == 0) {
            total=1;
        }

        // Send the data back to the main UI
        [self sendToUI: pid data:[location path] bitRate:(fileSize/total) error: 0];
}

/*
 This is the delegate that gets called occasionally with the current status of the download
*/
- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didLoadTimeRange:(CMTimeRange)timeRange totalTimeRangesLoaded:(NSArray<NSValue *> *)loadedTimeRanges timeRangeExpectedToLoad:(CMTimeRange)timeRangeExpectedToLoad {
{
        // Cancel preload once loadedSeconds is more than 10 seconds.
        NSInteger loadedSeconds = CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange));
        if (debugging) {
           NSLog(@"Download TimeStamp: %ld, time to cancel: %ld", loadedSeconds, cancelDownloadTimer);
        }
        // Cancel any downloads that are greater than the download timer, unless it is 0.
        if (loadedSeconds >= cancelDownloadTimer && cancelDownloadTimer > 0) {
            [assetDownloadTask cancel];
            lastAVAssetDownloadTask = nil;
        }
    }
}


@end
