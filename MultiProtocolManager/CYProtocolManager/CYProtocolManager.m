//
//  CYProtocolManager.m
//  deleacVC
//
//  Created by 尚宇 on 2019/5/8.
//  Copyright © 2019 cython. All rights reserved.
//

#import "CYProtocolManager.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface CYProtocolManager()

@property (nonatomic,strong) NSMutableDictionary *refTargets;

@property (nonatomic,strong) NSPointerArray *targets;

@end

@implementation CYProtocolManager

static CYProtocolManager *manager = nil;

+ (instancetype)share{
    if (!manager) {
        manager = [[CYProtocolManager alloc] init];
    }
    return manager;
}

- (void)addDelegateTarget:(id)target withProtcol:(id)protocol{
    
    if (![self.refTargets.allKeys containsObject:protocol]) {
        
        NSPointerArray *targets = [NSPointerArray weakObjectsPointerArray];
        [targets addPointer:(__bridge void * _Nullable)(target)];
        [self.refTargets setObject:targets forKey:protocol];
        
    }else{
        NSPointerArray *targets = [self.refTargets objectForKey:protocol];
        
        if ([targets.allObjects containsObject:target]) {
            return;
            
        }
        
        [targets addPointer:(__bridge void * _Nullable)(target)];
    }
    
}

- (void)removeDelegateProtocol:(id)protocol{
    if ([self.refTargets.allKeys containsObject:protocol]) {
        [_refTargets removeObjectForKey:protocol];
    }
}

- (void)removeAll{
    [self.refTargets removeAllObjects];
}


- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    
    for (id key in self.refTargets.allKeys) {
        NSPointerArray *targets = [self.refTargets objectForKey:key];
        for (id obj  in targets) {
            if ([obj respondsToSelector:aSelector]) {
                return YES;
            }
        }
    }
    return NO;
}
/**   在给程序添加消息转发功能以前，必须覆盖两个方法，即methodSignatureForSelector 和 forwardInvocation:。             */
/**methodSignatureForSelector:的作用在于为另一个类实现的消息创建一个有效的方法签名，必须实现，并且返回不为空的methodSignature，否则会crash*/

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
    if (!sig) {
        
        for (id key in self.refTargets.allKeys) {
            NSPointerArray *targets = [self.refTargets objectForKey:key];
            for (id obj in targets) {
                if ((sig = [obj methodSignatureForSelector:aSelector])) {
                    break;
                }
            }
        }
        
    }
    return sig;
}

//方法转发-对象方法消息重定向
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    for (NSString* key in self.refTargets.allKeys) {
        NSPointerArray *targets = [self.refTargets objectForKey:key];
        const char *name = [key UTF8String];
        Protocol *protocol = objc_getProtocol(name);
        NSAssert(protocol!=nil, @"不存在的协议");
        struct objc_method_description protocol_method_description =  protocol_getMethodDescription(protocol, anInvocation.selector, YES, YES);
    
//        NSLog(@"===%@==%s=",NSStringFromSelector(protocol_method_description.name),protocol_method_description.types);
       
        if (protocol_method_description.name!=nil) {
            for (id obj in targets) {// 从anInvocation.selector:从 anInvocation 中获取消息
                if ([obj respondsToSelector:anInvocation.selector]) {//对象方法是否可以响应
                    [anInvocation invokeWithTarget:obj];// 若可以响应，则将消息转发给其他对象处理
                }
                else{
                    [self doesNotRecognizeSelector:anInvocation.selector];  // 若仍然无法响应，则报错：找不到响应方法
                }
            }
        }

    }
}



- (NSMutableDictionary *)refTargets{
    if (!_refTargets) {
        _refTargets = [[NSMutableDictionary alloc] init];
    }
    return _refTargets;
}

- (NSMutableArray *)targets{
    if (!_targets) {
        _targets = [[NSMutableArray alloc] init];
    }
    return _targets;
}


- (Class)getMeterClassObjc:(id)objc{
    return  object_getClass(objc);
}

//给objc的deallocz转发一个新方法
- (void)cy_dealloc{
    NSLog(@"=====%s====",__func__);
}

static void cy_dealloc(id self ,SEL _cmd){
    NSLog(@"====%s=%@=",__func__,self);
}


@end
