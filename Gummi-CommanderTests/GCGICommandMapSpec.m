//
// Created by Simon Schmid
//
// contact@sschmid.com
//


#import "Kiwi.h"
#import "GIInjector.h"
#import "GCGICommandMap.h"
#import "GummiCommanderModule.h"
#import "GCDefaultEventBus.h"
#import "SomeEvent.h"
#import "GCCommand.h"
#import "SomeCommand.h"
#import "SomeObject.h"
#import "SomeOtherCommand.h"
#import "SomeGuard.h"
#import "NoGuard.h"
#import "YesGuard.h"
#import "DependencyGuard.h"


SPEC_BEGIN(GCGICommandMapSpec)

        describe(@"GCGICommandMap", ^{

            __block GIInjector *injector = nil;
            __block GCGICommandMap *commandMap = nil;
            beforeEach(^{
                [[GIInjector sharedInjector] reset];
                injector = [GIInjector sharedInjector];
                [injector addModule:[[GummiCommanderModule alloc] init]];
                commandMap = [injector getObject:@protocol(GCCommandMap)];
            });

            it(@"instantiates commandMap", ^{
                [[commandMap should] beKindOfClass:[GCGICommandMap class]];
            });

            it(@"has eventBus", ^{
                id eventBus = commandMap.eventBus;
                [[eventBus should] conformToProtocol:@protocol(GCEventBus)];
            });

            it(@"has no mapping", ^{
                BOOL has = [commandMap isEvent:[SomeEvent class] mappedToCommand:[SomeCommand class]];

                [[theValue(has) should] beNo];
            });

            it(@"has a mapping", ^{
                [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];
                BOOL has = [commandMap isEvent:[SomeEvent class] mappedToCommand:[SomeCommand class]];

                [[theValue(has) should] beYes];
            });

            it(@"removes mapping", ^{
                [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];
                [commandMap unMapEvent:[SomeEvent class] fromCommand:[SomeCommand class]];
                BOOL has = [commandMap isEvent:[SomeEvent class] mappedToCommand:[SomeCommand class]];

                [[theValue(has) should] beNo];
            });

            it(@"removes all mappings", ^{
                [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];
                [commandMap mapEvent:[SomeObject class] toCommand:[SomeOtherCommand class]];
                [commandMap unMapAll];

                BOOL has1 = [commandMap isEvent:[SomeEvent class] mappedToCommand:[SomeCommand class]];
                BOOL has2 = [commandMap isEvent:[SomeObject class] mappedToCommand:[SomeOtherCommand class]];

                [[theValue(has1) should] beNo];
                [[theValue(has2) should] beNo];
            });

            it(@"executes a command", ^{
                id <GCEventBus> eventBus = [injector getObject:@protocol(GCEventBus)];
                SomeEvent *event = [[SomeEvent alloc] init];
                event.object = [[SomeObject alloc] init];
                [eventBus postEvent:event];

                [[theValue(event.object.flag) should] beNo];
            });

            context(@"when assigned eventBus", ^{

                beforeEach(^{
                    commandMap.eventBus = [[GCDefaultEventBus alloc] init];
                });

                it(@"has eventBus", ^{
                    id eventBus = commandMap.eventBus;
                    [[eventBus should] beKindOfClass:[GCDefaultEventBus class]];
                });

                it(@"executes a command", ^{
                    SomeEvent *event = [[SomeEvent alloc] init];
                    event.object = [[SomeObject alloc] init];
                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];
                    [commandMap.eventBus postEvent:event];

                    [[theValue(event.object.flag) should] beYes];
                });

                it(@"executes commands in right order", ^{
                    SomeEvent *event = [[SomeEvent alloc] init];
                    event.object = [[SomeObject alloc] init];

                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];
                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeOtherCommand class]];

                    [commandMap.eventBus postEvent:event];

                    [[event.string should] equal:@"12"];
                });

                it(@"executes commands in right order", ^{
                    SomeEvent *event = [[SomeEvent alloc] init];
                    event.object = [[SomeObject alloc] init];

                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeOtherCommand class]];
                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];

                    [commandMap.eventBus postEvent:event];

                    [[event.string should] equal:@"21"];
                });

                it(@"executes commands in right order", ^{
                    SomeEvent *event = [[SomeEvent alloc] init];
                    event.object = [[SomeObject alloc] init];

                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class] priority:10];
                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeOtherCommand class] priority:20];

                    [commandMap.eventBus postEvent:event];

                    [[event.string should] equal:@"21"];
                });

                it(@"executes commands in right order", ^{
                    SomeEvent *event = [[SomeEvent alloc] init];
                    event.object = [[SomeObject alloc] init];

                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeOtherCommand class] priority:20];
                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class] priority:10];

                    [commandMap.eventBus postEvent:event];

                    [[event.string should] equal:@"21"];
                });

                it(@"auto removes mapping", ^{
                    SomeEvent *event = [[SomeEvent alloc] init];
                    event.object = [[SomeObject alloc] init];

                    [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class] priority:10 removeMappingAfterExecution:YES];

                    [commandMap.eventBus postEvent:event];
                    [commandMap.eventBus postEvent:event];

                    [[event.string should] equal:@"1"];
                });

            });

            context(@"guards", ^{

                it(@"has no mapping", ^{
                    GCMapping *mapping = [commandMap mappingForEvent:[SomeEvent class] command:[SomeCommand class]];

                    [mapping shouldBeNil];
                });

                context(@"when added a mapping", ^{

                    beforeEach(^{
                        [commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]];
                    });

                    it(@"has mapping", ^{
                        GCMapping *mapping = [commandMap mappingForEvent:[SomeEvent class] command:[SomeCommand class]];

                        [[mapping should] beKindOfClass:[GCMapping class]];
                    });

                    it(@"has no guards", ^{
                        GCMapping *mapping = [commandMap mappingForEvent:[SomeEvent class] command:[SomeCommand class]];
                        BOOL has = [mapping hasGuard:[SomeGuard class]];

                        [[theValue(has) should] beNo];
                    });

                    context(@"when guards added", ^{

                        __block NSArray *guards = nil;
                        __block GCMapping *mapping = nil;
                        beforeEach(^{
                            mapping = [commandMap mappingForEvent:[SomeEvent class] command:[SomeCommand class]];
                        });

                        it(@"has guard", ^{
                            guards = [NSArray arrayWithObject:[SomeGuard class]];
                            [mapping withGuards:guards];
                            BOOL has = [mapping hasGuard:[SomeGuard class]];

                            [[theValue(has) should] beYes];
                        });

                        it(@"prevents command execution when guard does not approve", ^{
                            [mapping withGuards:[NSArray arrayWithObject:[NoGuard class]]];
                            SomeEvent *event = [[SomeEvent alloc] init];
                            event.object = [[SomeObject alloc] init];
                            [event dispatch];

                            [[theValue(event.object.flag) should] beNo];
                        });

                        it(@"executes command when guard approves", ^{
                            [mapping withGuards:[NSArray arrayWithObject:[YesGuard class]]];
                            SomeEvent *event = [[SomeEvent alloc] init];
                            event.object = [[SomeObject alloc] init];
                            [event dispatch];

                            [[theValue(event.object.flag) should] beYes];
                        });

                        it(@"injects dependencies into guards", ^{
                            [mapping withGuards:[NSArray arrayWithObject:[DependencyGuard class]]];
                            SomeEvent *event = [[SomeEvent alloc] init];
                            event.object = [[SomeObject alloc] init];
                            [event dispatch];

                            [[theValue(event.object.flag) should] beYes];
                        });

                    });

                });

                it(@"has guard", ^{
                    [[commandMap mapEvent:[SomeEvent class] toCommand:[SomeCommand class]] withGuards:[NSArray arrayWithObject:[SomeGuard class]]];
                    BOOL has = [[commandMap mappingForEvent:[SomeEvent class] command:[SomeCommand class]] hasGuard:[SomeGuard class]];

                    [[theValue(has) should] beYes];
                });

            });

        });

        SPEC_END