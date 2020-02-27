//
//  main.m
//  Remote Access
//
//  Created by Peet McKinney on 2/25/20.
//  Copyright © 2020 Peet, Inc. All rights reserved.
//

 #import <Cocoa/Cocoa.h>
 #import "STPrivilegedTask.h"

 int main(int argc, const char * argv[]) {
 @autoreleasepool {
     NSTask *script = [[NSTask alloc] init];
     [script setLaunchPath:@"/bin/zsh"];
     [script setArguments:@[ [[NSBundle mainBundle] pathForResource:@"script" ofType:nil] ]];
     [script launch];
 }
    return 0;
 }

//#import <Cocoa/Cocoa.h>
//#import "STPrivilegedTask.h"
//
//int main(int argc, const char * argv[]) {
//@autoreleasepool {
//
//   STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
//   [privilegedTask setLaunchPath:@"/bin/zsh"];
//   [privilegedTask setArguments:@[@"script"]];
//
//   // Setting working directory is optional, defaults to /
//   NSString *path = [[NSBundle mainBundle] resourcePath];
//   [privilegedTask setCurrentDirectoryPath:path];
//
//   // Launch it, user is prompted for password
//   OSStatus err = [privilegedTask launch];
//   if (err == errAuthorizationSuccess) {
//       NSLog(@"Task successfully launched");
//   }
//   else if (err == errAuthorizationCanceled) {
//       NSLog(@"User cancelled");
//   }
//   else {
//       NSLog(@"Something went wrong");
//   }
//
//}
//   return 0;
//}
