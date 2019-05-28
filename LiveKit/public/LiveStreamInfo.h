//
//  LiveStreamInfo.h
//  LiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveAudioConfiguration.h"
#import "LiveVideoConfiguration.h"



/// 流状态
typedef NS_ENUM (NSUInteger, LiveState){
    /// 准备
    LiveReady = 0,
    /// 连接中
    LivePending = 1,
    /// 已连接
    LiveStart = 2,
    /// 已断开
    LiveStop = 3,
    /// 连接出错
    LiveError = 4,
    ///  正在刷新
    LiveRefresh = 5
};

typedef NS_ENUM (NSUInteger, LiveSocketErrorCode) {
    LiveSocketError_PreView = 201,              //// 预览失败
    LiveSocketError_GetStreamInfo = 202,        //// 获取流媒体信息失败
    LiveSocketError_ConnectSocket = 203,        //// 连接socket失败
    LiveSocketError_Verification = 204,         //// 验证服务器失败
    LiveSocketError_ReConnectTimeOut = 205      //// 重新连接服务器超时
};

@interface LiveStreamInfo : NSObject

@property (nonatomic, copy) NSString *streamId;

#pragma mark -- FLV
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSInteger port;
#pragma mark -- RTMP
@property (nonatomic, copy) NSString *url;          //// 上传地址 (RTMP用就好了)
///音频配置
@property (nonatomic, strong) LiveAudioConfiguration *audioConfiguration;
///视频配置
@property (nonatomic, strong) LiveVideoConfiguration *videoConfiguration;

@end
