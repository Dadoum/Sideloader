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
    override static Foo alloc() @selector("alloc");
    override Foo init() @selector("init");

    final int add5(int a) @selector("bar:")
    {
        return a + 5;
    }
}
