//
//  Copyright 2011 Yozio. All rights reserved.
//

#if !defined(__YOZIO__)
#define __YOZIO__ 1

#import <Foundation/Foundation.h>

@interface Yozio : NSObject

/**
 * Configures Yozio with your application's information.
 
 * @param appKey  The application name we provided you for your application.
 * @param secretKey  The top secret key that only you know about. Don't share this with others!
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey;

/**
 * Retrieve the shortened url for a dynamic link. Returns the destinationUrl if it can't get a short url. (blocking)
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 * @param destinationUrl  the url that the shortened url must redirect to.
 */
+ (NSString *)getUrl:(NSString *)linkName destinationUrl:(NSString *)destinationUrl;

/**
 * Alert Yozio that a user has viewed a link.
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 */
+ (void)viewedLink:(NSString *)linkName;

/**
 * Alert Yozio that a user has clicked on a link.
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 */
+ (void)sharedLink:(NSString *)linkName;

@end

#endif /* ! __YOZIO__ */