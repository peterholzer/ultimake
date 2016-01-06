#ifndef BAR_HPP___
#define BAR_HPP___


namespace unnamed {


/// An example
class SomeClass
{
    public:
        /// Create a new SomeClass
        SomeClass();
        ///
        virtual ~SomeClass();

    protected:

    private:
        // No copy constructor
        SomeClass(const SomeClass& other);
        // No assignment operator
        SomeClass& operator=(SomeClass const &rhs);

};


} // namespace unnamed


#endif // BAR_HPP___
