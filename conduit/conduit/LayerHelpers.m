//
//  LayerHelpers.m
//  conduit
//
//  Created by Nathan Eidelson on 4/5/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

#import "LayerHelpers.h"

@implementation LayerHelpers

+ (NSDateFormatter *)LQSDateFormatter
{
  static NSDateFormatter *dateFormatter;
  if (!dateFormatter)
  {
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
  }
  return dateFormatter;
}

+ (void)authenticateLayerWithUserID:(NSString *)userID client:(LYRClient *)client completion:(void (^)(BOOL success, NSError * error))completion
{
  // Check to see if the layerClient is already authenticated.
  if (client.authenticatedUserID) {
    // If the layerClient is authenticated with the requested userID, complete the authentication process.
    if ([client.authenticatedUserID isEqualToString:userID]){
      NSLog(@"Layer Authenticated as User %@", client.authenticatedUserID);
      if (completion) completion(YES, nil);
      return;
    } else {
      //If the authenticated userID is different, then deauthenticate the current client and re-authenticate with the new userID.
      [client deauthenticateWithCompletion:^(BOOL success, NSError *error) {
        if (!error){
          [self authenticationTokenWithUserId:userID client:client completion:^(BOOL success, NSError *error) {
            if (completion){
              completion(success, error);
            }
          }];
        } else {
          if (completion){
            completion(NO, error);
          }
        }
      }];
    }
  } else {
    // If the layerClient isn't already authenticated, then authenticate.
    [self authenticationTokenWithUserId:userID client:client completion:^(BOOL success, NSError *error) {
      if (completion){
        completion(success, error);
      }
    }];
  }
}

+ (void)authenticationTokenWithUserId:(NSString *)userID client:(LYRClient *)client completion:(void (^)(BOOL success, NSError* error))completion{
  
  /*
   * 1. Request an authentication Nonce from Layer
   */
  [client requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
    if (!nonce) {
      if (completion) {
        completion(NO, error);
      }
      return;
    }
    
    /*
     * 2. Acquire identity Token from Layer Identity Service
     */
    [self requestIdentityTokenForUserID:userID appID:[client.appID UUIDString] nonce:nonce completion:^(NSString *identityToken, NSError *error) {
      if (!identityToken) {
        if (completion) {
          completion(NO, error);
        }
        return;
      }
      
      /*
       * 3. Submit identity token to Layer for validation
       */
      [client authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
        if (authenticatedUserID) {
          if (completion) {
            completion(YES, nil);
          }
          NSLog(@"Layer Authenticated as User: %@", authenticatedUserID);
        } else {
          completion(NO, error);
        }
      }];
    }];
  }];
}

+ (void)requestIdentityTokenForUserID:(NSString *)userID appID:(NSString *)appID nonce:(NSString *)nonce completion:(void(^)(NSString *identityToken, NSError *error))completion
{
  NSParameterAssert(userID);
  NSParameterAssert(appID);
  NSParameterAssert(nonce);
  NSParameterAssert(completion);
  
  NSURL *identityTokenURL = [NSURL URLWithString:@"https://layer-identity-provider.herokuapp.com/identity_tokens"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:identityTokenURL];
  request.HTTPMethod = @"POST";
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  
  NSDictionary *parameters = @{ @"app_id": appID, @"user_id": userID, @"nonce": nonce };
  NSData *requestBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
  request.HTTPBody = requestBody;
  
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
      completion(nil, error);
      return;
    }
    
    // Deserialize the response
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if(![responseObject valueForKey:@"error"])
    {
      NSString *identityToken = responseObject[@"identity_token"];
      completion(identityToken, nil);
    }
    else
    {
      NSString *domain = @"layer-identity-provider.herokuapp.com";
      NSInteger code = [responseObject[@"status"] integerValue];
      NSDictionary *userInfo =
      @{
        NSLocalizedDescriptionKey: @"Layer Identity Provider Returned an Error.",
        NSLocalizedRecoverySuggestionErrorKey: @"There may be a problem with your APPID."
        };
      
      NSError *error = [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
      completion(nil, error);
    }
    
  }] resume];
}

+ (LYRQuery *)createQueryWithClass:(Class)class_type
{
  return [LYRQuery queryWithClass:class_type];
}

+ (LYRPredicate *)createPredicateWithProperty:(NSString *)property
                                    _operator:(LYRPredicateOperator)_operator
                                        value:(id)value {
  return [LYRPredicate predicateWithProperty:property operator:_operator value:value];
}

#pragma mark - Push Notification Methods

+ (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
             client:(LYRClient *)client fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  // Get Message from Metadata

  NSError *error;
  BOOL success = [client synchronizeWithRemoteNotification:userInfo completion:^(NSArray *changes, NSError *error) {
    if (changes)
    {

      if ([changes count])
      {
    //    message = [self messageFromRemoteNotification:userInfo client:client];
        completionHandler(UIBackgroundFetchResultNewData);
      }
      else
      {
        completionHandler(UIBackgroundFetchResultNoData);
      }
    }
    else
    {
      completionHandler(UIBackgroundFetchResultFailed);
    }
  }];
  
  if (success) {
    NSLog(@"Application did complete remote notification sync");
  } else {
    NSLog(@"Failed processing push notification with error: %@", error);
    completionHandler(UIBackgroundFetchResultNoData);
  }
}


+ (LYRMessage *)messageFromRemoteNotification:(NSDictionary *)remoteNotification client:(LYRClient *)client
{
  static NSString *const LQSPushMessageIdentifierKeyPath = @"layer.message_identifier";
  
  // Retrieve message URL from Push Notification
  NSURL *messageURL = [NSURL URLWithString:[remoteNotification valueForKeyPath:LQSPushMessageIdentifierKeyPath]];
  
  // Retrieve LYRMessage from Message URL
  LYRQuery *query = [LYRQuery queryWithClass:[LYRMessage class]];
  query.predicate = [LYRPredicate predicateWithProperty:@"identifier" operator:LYRPredicateOperatorIsIn value:[NSSet setWithObject:messageURL]];
  
  NSError *error;
  NSOrderedSet *messages = [client executeQuery:query error:&error];
  if (!error) {
    NSLog(@"Query contains %lu messages", (unsigned long)messages.count);
    LYRMessage *message= messages.firstObject;
    LYRMessagePart *messagePart = message.parts[0];
    NSLog(@"Pushed Message Contents: %@",[[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding]);
  } else {
    NSLog(@"Query failed with error %@", error);
  }
  
  return [messages firstObject];
}

@end
