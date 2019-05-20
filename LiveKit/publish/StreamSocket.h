//
//  StreamSocket.h
//  LiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveStreamInfo.h"
#import "StreamingBuffer.h"
#import "LiveDebug.h"



@protocol StreamSocket;
@protocol StreamSocketDelegate <NSObject>

/** callback buffer current status (回调当前缓冲区情况，可实现相关切换帧率 码率等策略)*/
- (void)socketBufferStatus:(nullable id <StreamSocket>)socket status:(LiveBuffferState)status;
/** callback socket current status (回调当前网络情况) */
- (void)socketStatus:(nullable id <StreamSocket>)socket status:(LiveState)status;
/** callback socket errorcode */
- (void)socketDidError:(nullable id <StreamSocket>)socket errorCode:(LiveSocketErrorCode)errorCode;
@optional
/** callback debugInfo */
- (void)socketDebug:(nullable id <StreamSocket>)socket debugInfo:(nullable LiveDebug *)debugInfo;
@end

@protocol StreamSocket <NSObject>
- (void)start;
- (void)stop;
- (void)sendFrame:(nullable LFFrame *)frame;
- (void)setDelegate:(nullable id <StreamSocketDelegate>)delegate;
@optional
- (nullable instancetype)initWithStream:(nullable LiveStreamInfo *)stream;
- (nullable instancetype)initWithStream:(nullable LiveStreamInfo *)stream reconnectInterval:(NSInteger)reconnectInterval reconnectCount:(NSInteger)reconnectCount;
@end
