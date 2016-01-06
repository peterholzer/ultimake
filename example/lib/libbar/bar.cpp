#include "bar.hpp"

#include <iostream>


namespace unnamed {


SomeClass::SomeClass()
{
    std::cout << "SomeClass::SomeClass()" << std::endl;
}

SomeClass::~SomeClass()
{
    std::cout << "~SomeClass::SomeClass()" << std::endl;
}


} // namespace unnamed
