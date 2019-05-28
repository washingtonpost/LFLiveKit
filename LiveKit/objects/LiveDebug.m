//
//  LiveDebug.m
//  LaiFeng
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LiveDebug.h"

@implementation LiveDebug

- (NSString *)description {
    return [NSString stringWithFormat:@"丢掉的帧数:%ld 总帧数:%ld 上次的音频捕获个数:%ld 上次的视频捕获个数:%d 未发送个数:%ld 总流量:%0.f",_dropFrame,_totalFrame,(long)_currentCapturedAudioCount,_currentCapturedVideoCount,_unSendCount,_dataFlow];
}


@end
