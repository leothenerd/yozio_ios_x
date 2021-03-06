//
//  Seriously.m
//  Prototype
//
//  Created by Corey Johnson on 6/18/10.
//  Copyright 2010 Probably Interactive. All rights reserved.
//

#import "YSeriously.h"
#import "YSeriouslyOperation.h"
#import "Yozio_Private.h"

const NSString *kSeriouslyMethod = @"kSeriouslyMethod";
const NSString *kSeriouslyTimeout = @"kSeriouslyTimeout";
const NSString *kSeriouslyHeaders = @"kSeriouslyHeaders";
const NSString *kSeriouslyBody = @"kSeriouslyBody";
const NSString *kSeriouslyProgressHandler = @"kSeriouslyProgressHandler";
NSString *yozioUserAgent = @"Yozio iOS SDK";

@implementation YSeriously : NSObject

+ (YSeriouslyOperation *)request:(NSMutableURLRequest *)request options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler {
  NSMutableDictionary *options = [self options];
  [options addEntriesFromDictionary:userOptions];
  
  NSURLRequestCachePolicy cachePolicy = NSURLRequestUseProtocolCachePolicy;
  NSTimeInterval timeout = 60;
  
  [request setCachePolicy:cachePolicy];
  [request setTimeoutInterval:timeout];
  [request setHTTPMethod:[[options objectForKey:kSeriouslyMethod] uppercaseString]];
  [request setTimeoutInterval:[[options objectForKey:kSeriouslyTimeout] doubleValue]];
  [request setAllHTTPHeaderFields:[options objectForKey:kSeriouslyHeaders]];
  [request setValue:YOZIO_SDK_VERSION forHTTPHeaderField:@"yozio-sdk-version"];
  
  if ([[request HTTPMethod] isEqual:@"POST"] || [[request HTTPMethod] isEqual:@"PUT"]) {
    [request setHTTPBody:[options objectForKey:kSeriouslyBody]];
  }
  
  SeriouslyProgressHandler progressHandler = [options objectForKey:kSeriouslyProgressHandler];
  
  YSeriouslyOperation *operation = [YSeriouslyOperation operationWithRequest:request handler:handler progressHandler:progressHandler];
  [[self operationQueue] addOperation:operation];
  
  return operation;
}

+ (YSeriouslyOperation *)requestURL:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler {
  if ([url isKindOfClass:[NSString class]]) url = [NSURL URLWithString:url];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nil];
  NSString *method = [[userOptions objectForKey:kSeriouslyMethod] uppercaseString];
  if ([method isEqual:@"POST"] || [method isEqual:@"PUT"]) {
    url = [self url:url params:nil];
  }
  else {
    url = [self url:url params:[userOptions objectForKey:kSeriouslyBody]];
  }
  [request setURL:url];
  
  return [self request:request options:userOptions handler:handler];
}

+ (NSMutableDictionary *)options {
  static NSString *method = @"GET";
  static NSTimeInterval timeout = 60;
  
  return [NSMutableDictionary dictionaryWithObjectsAndKeys:
          method, kSeriouslyMethod,
          [NSNumber numberWithInt:timeout], kSeriouslyTimeout,
          nil];
}

+ (NSOperationQueue *)operationQueue {
  static NSOperationQueue *operationQueue;
  
  if (!operationQueue) {
    operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 3;
  }
  
  return operationQueue;
}


// Helper Methods
// --------------
+ (YSeriouslyOperation *)get:(id)url handler:(SeriouslyHandler)handler {
  return [self get:url options:nil handler:handler];
}

+ (YSeriouslyOperation *)get:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler {
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"GET", kSeriouslyMethod, nil];
  [options addEntriesFromDictionary:userOptions];
  return [self requestURL:url options:options handler:handler];
}

+ (YSeriouslyOperation *)post:(id)url handler:(SeriouslyHandler)handler {
  return [self post:url options:nil handler:handler];
}

+ (YSeriouslyOperation *)post:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler {
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"POST", kSeriouslyMethod, nil];
  [options addEntriesFromDictionary:userOptions];
  return [self requestURL:url options:options handler:handler];
}

+ (YSeriouslyOperation *)post:(id)url body:(NSDictionary *)body handler:(SeriouslyHandler)handler {
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"POST", kSeriouslyMethod, nil];
  NSString* formattedQueryParams = [self formatQueryParams:body];
  NSData *escapedBodyData = [formattedQueryParams dataUsingEncoding: NSUTF8StringEncoding];
  [options setObject:escapedBodyData forKey:kSeriouslyBody];
  return [self requestURL:url options:options handler:handler];
}

+ (YSeriouslyOperation *)put:(id)url handler:(SeriouslyHandler)handler {
  return [self put:url options:nil handler:handler];
}

+ (YSeriouslyOperation *)put:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler {
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"PUT", kSeriouslyMethod, nil];
  [options addEntriesFromDictionary:userOptions];
  return [self requestURL:url options:options handler:handler];
}

+ (YSeriouslyOperation *)delete:(id)url handler:(SeriouslyHandler)handler {
  return [self delete:url options:nil handler:handler];
}

+ (YSeriouslyOperation *)delete:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler {
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"DELETE", kSeriouslyMethod, nil];
  [options addEntriesFromDictionary:userOptions];
  return [self requestURL:url options:options handler:handler];
}

// Utility Methods
// ---------------
+ (NSURL *)url:(id)url params:(id)params {
  if (!params) {
    return [url isKindOfClass:[NSString string]] ? [NSURL URLWithString:url] : url;
  }
  
  NSString *urlString = [NSString stringWithFormat:@"%@?%@", url, [self formatQueryParams:params]];
  
  return [NSURL URLWithString:urlString];
}

+ (NSString *)formatQueryParams:(id)params {
  if (![params isKindOfClass:[NSDictionary class]]) return params;
  
  NSMutableArray *pairs = [NSMutableArray array];
  for (id key in params) {
    id value = [(NSDictionary *)params objectForKey:key];
    
    if ([value isKindOfClass:[NSArray class]]) {
      for (id v in value) {
        [pairs addObject:[NSString stringWithFormat:@"%@[]=%@", key, [self escapeQueryParam:v]]];
      }
    }
    else {
      [pairs addObject:[NSString stringWithFormat:@"%@=%@",key, [self escapeQueryParam:value]]];
    }
  }
  
  return [pairs componentsJoinedByString:@"&"];
}

+ (NSString *)escapeQueryParam:(id)param {
  if (![param isKindOfClass:[NSString class]]) param = [NSString stringWithFormat:@"%@", param];
  
	CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(
                                                                kCFAllocatorDefault,
                                                                (CFStringRef)param,
                                                                NULL,
                                                                (CFStringRef)@":/?=,!$&'()*+;[]@#",
                                                                CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
  
  return [(NSString *)escaped autorelease];
}

@end
