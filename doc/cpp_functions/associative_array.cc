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
        void print_all ();

      private:
      protected:
          std::map < std::string, data* > m_str_array;
};

Associative::Associative ()
{
        data *one = new data;

        one->location = 1;
        one->value = "this is one";

        m_str_array["one"] = one;

        data *two = new data;

        two->location = 2;
        two->value = "this is two";

        m_str_array["two"] = two;
}

Associative::~Associative ()
{
        for (std::map < std::string, data * >::iterator i =
             m_str_array.begin (); i != m_str_array.end (); i++)
        {
                std::cout << "Destroyed " << i->first << std::endl;
                //delete i->second->value; ?? this causes double-free error
        }
}

void
Associative::print (const char* key)
{
        std::cout << m_str_array[key]->location << ". " << m_str_array[key]->value << std::endl;
}

void
Associative::print_all ()
{
        for (std::map < std::string, data * >::const_iterator i =
             m_str_array.begin (); i != m_str_array.end (); i++)
        {
                std::cout << i->first << ". " << i->second->value << std::endl;
        }
}

int
main ()
{
        // scope defines my_array
        {
                Associative my_array;

                my_array.print ("one");
                my_array.print ("two");

                std::cout << "printing all values: " << std::endl;

                my_array.print_all();

                std::cout << "printing value for 'two' again: " << std::endl;

                my_array.print ("two");
        }

        return 0;
}
