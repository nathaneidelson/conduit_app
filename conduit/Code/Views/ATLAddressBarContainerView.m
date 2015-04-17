//
//  ATLUIAddressBarContainerView.m
//  Atlas
//
//  Created by Ben Blakley on 11/25/14.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
#import "ATLAddressBarContainerView.h"
#import "ATLAddressBarView.h"

@implementation ATLAddressBarContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];

    // Ignore taps on this view (but allow taps on its subviews).
    if (view == self) return nil;

    return view;
}

@end
