#include <libxml++/libxml++.h>
#include <libxml++/parsers/textreader.h>
#include <iostream>
#include <vector>
using namespace std;

int tag_depth, depth;
Glib::ustring image, file, tag;
vector<Glib::ustring> data;

int main()
{
    int j=0;
    tag="root";
    file="test.xml";
    xmlpp::TextReader reader(file);
    try {
    // routine
        while(reader.read())
            {
                depth = reader.get_depth();
                Glib::ustring name = reader.get_name();
                if ( name == tag )
                {
                        tag_depth = depth;
                        cout<<j++<<"\t"<<name<<endl;
                        data.push_back(name);
                        for( int i = 1; reader.get_depth() >= tag_depth && reader.read(); i++)
                        {
                                name = reader.get_name();
				if(name[0] == '#')
                                {
                                        if ( reader.has_value() && 
                                        (reader.get_value()).find("\n") == string::npos )
						data.push_back(reader.get_value());
					else
						data.push_back("no value");

                                } else {
                                        data.push_back(name);
                                }
                        } // end for
                        break;
                } // end if name == tag
            } // end while
            /* print vector content */
            for(int i = 0; i < data.size() ; i++)
            {
                cout<<i<<"\t"<<"data: "<<data[i]<<endl;
            }
    } catch (const exception& e) {
        cout << "Error: " << e.what() << endl;
    }
    // end routine
    return 0;
}
