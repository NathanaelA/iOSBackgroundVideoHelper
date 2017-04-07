//
//  VideoHelper.h
//

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
