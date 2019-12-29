//
//  RScanResult.h
//  r_scan
//
//  Created by 李鹏辉 on 2019/12/28.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface RScanResult : NSObject

+(NSDictionary*) toMap:(AVMetadataMachineReadableCodeObject*) obj;

+(NSNumber*) getType:(AVMetadataObjectType)type;


@end

