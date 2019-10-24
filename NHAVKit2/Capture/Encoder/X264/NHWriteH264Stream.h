//
//  NHWriteH264Stream.h
//  NHPushStreamSDK
//
//  Created by nenhall on 2019/2/19.
//  Copyright © 2019 neghao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NHX264OutputProtocol.h"
#import "NHCaptureSessionProtocol.h"


#ifdef __cplusplus
extern "C" {
#endif
#include <libavcodec/avcodec.h>
#ifdef __cplusplus
}
#endif


NS_ASSUME_NONNULL_BEGIN

@interface NHWriteH264Stream : NSObject <NHX264OutputProtocol>
@property (copy, nonatomic) NSString *filePath;

- (void)writeFrame:(AVPacket)packet streamIndex:(NSInteger)streamIndex;

@end

NS_ASSUME_NONNULL_END
