module objc.developerservices;

import core.attribute : selector;

extern (Objective-C)
extern class NSObject
{
    static NSObject alloc() @selector("alloc");
    NSObject init() @selector("init");
}

extern (Objective-C)
class Test : NSObject
{
    override static Test alloc() @selector("alloc");
    override Test init() @selector("init");

    final int add5(int a) @selector("bar:")
    {
        return a + 5;
    }
}
