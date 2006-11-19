/* compile with: g++ -o test associative_array.cc */

#include <map>
#include <iostream>
#include <string>

using namespace std;

typedef struct data
{
        short int location;
        const char* value;
};

class Associative
{
      public:
        Associative ();
        ~Associative ();
        void print (const char* key);

      private:
      protected:
          std::map < std::string, data* > m_str_array;
};

Associative::Associative ()
{
        data one;

        one.location = 1;
        one.value = "this is one";

        m_str_array["one"] = &one;
}

Associative::~Associative ()
{
}

void
Associative::print (const char* key)
{
        std::cout << m_str_array[key]->value << std::endl;
}

int
main ()
{
        Associative my_array;

        my_array.print ("one");

        return 0;
}
