/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVADevice.h"

/**
 *  Provide and keep track of device log based on collected properties.
 */
@interface AVADeviceTracker : NSObject

/**
 *  Current device log.
 */
@property(nonatomic, readonly) AVADevice *device;

/**
 *  Refresh properties.
 */
- (void)refresh;

@end