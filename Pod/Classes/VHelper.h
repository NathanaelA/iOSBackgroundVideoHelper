/**********************************************************************************
 * (c) 2017, Master Technology
 * Licensed under a MIT License
 *
 * Any questions please feel free to email me or put a issue up on the private repo
 *                                                     Nathan@master-technology.com
 *********************************************************************************/
#import <Foundation/Foundation.h>

@class VideoHelper;

@protocol MTVideoDelegate <NSObject>
@required
-(void)onEvent:(NSInteger)pid data:(NSString *)data  bitRate:(NSInteger)bitRate error:(NSInteger)error;
@end


@interface VideoHelper : NSObject  {

  __strong id <MTVideoDelegate> _delegate;

}

#pragma mark - Properties

@property (atomic, strong) id <MTVideoDelegate> delegate;

#pragma mark - Init

- (instancetype)init;


#pragma mark - Actions

- (void)addObject: (NSDictionary *)zptObject;
- (void)enableDebugging;

@end
