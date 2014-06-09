
#include <iostream>
#include <fstream>
#include <stdexcept>
#include <string>
#include <memory>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

#include "mcc-properties.hh"
#include "util/config.h"
#include "util/misc.h"

#define EXIT_ERR	1
#define EXIT_OK	0

void cannot (const char * msg = 0)
{
		PRINT_ ("Error: cannot handle input formula");
		if (msg)
			PRINT (": %s", msg);
		else
			PRINT ("");
		exit (EXIT_ERR);
}

void translate_predicate (const xml_schema::type & f, std::string & out)
{
	SHOW (typeid (f) == typeid (mcc::is_fireable), "d");
	SHOW (typeid (f) == typeid (mcc::deadlock), "d");
	SHOW (typeid (f) == typeid (mcc::negation), "d");
	SHOW (typeid (f) == typeid (mcc::conjunction), "d");
	SHOW (typeid (f) == typeid (mcc::disjunction), "d");

	if (typeid (f) == typeid (mcc::is_fireable))
	{
		const mcc::is_fireable & f1 = (mcc::is_fireable &) f;
		auto tseq = f1.transition ();
		out += "( \"";
		for (auto it = tseq.begin (); it != tseq.end (); ++it)
		{
			// *it is xml_schema::idref, which inherits from std::basic_string
			if (it != tseq.begin ()) out += "|| \"";
			out += *it + "\" ";
		}
		out += ")";
	}
	else if (typeid (f) == typeid (mcc::deadlock))
	{
		out += "deadlock";
	}
	else if (typeid (f) == typeid (mcc::negation))
	{
		const mcc::negation & f1 = (mcc::negation &) f;
		out += "! (";
		translate_predicate (f1.boolean_formula (), out);
		out += ")";
	}
	else if (typeid (f) == typeid (mcc::disjunction))
	{
		const mcc::disjunction & f1 = (mcc::disjunction &) f;
		auto fseq = f1.boolean_formula ();
		out += "( ";
		for (auto it = fseq.begin (); it != fseq.end (); ++it)
		{
			// *it is xml_schema::type
			if (it != fseq.begin ()) out += "|| \"";
			translate_predicate (*it, out);
		}
		out += ")";
	}
	else if (typeid (f) == typeid (mcc::conjunction))
	{
		const mcc::conjunction & f1 = (mcc::conjunction &) f;
		auto fseq = f1.boolean_formula ();
		out += "(";
		for (auto it = fseq.begin (); it != fseq.end (); ++it)
		{
			// *it is xml_schema::type
			if (it != fseq.begin ()) out += ") && (";
			translate_predicate (*it, out);
		}
		out += ")";
	}
	else
	{
		cannot ("can only translate 'conjunction', 'disjunction', " \
				"'deadlock', or 'is-firable'");
	}
}

void
translate_formula (const xml_schema::type & f, std::string & out,
		bool & negate)
{
	SHOW (typeid (f) == typeid (mcc::invariant), "d");
	SHOW (typeid (f) == typeid (mcc::impossibility), "d");
	SHOW (typeid (f) == typeid (mcc::possibility), "d");

	negate = false;

	if (typeid (f) == typeid (mcc::possibility))
	{
		const mcc::possibility & f1 = (mcc::possibility &) f;
		translate_predicate (f1.boolean_formula (), out);
	}
	else if (typeid (f) == typeid (mcc::impossibility))
	{
		const mcc::impossibility & f1 = (mcc::impossibility &) f;
		translate_predicate (f1.boolean_formula (), out);
		negate = true;
	}
	else if (typeid (f) == typeid (mcc::invariant))
	{
		const mcc::invariant & f1 = (mcc::invariant &) f;
		out += "! (";
		translate_predicate (f1.boolean_formula (), out);
		out += ")";
		negate = true;
	}
	else
	{
		translate_predicate (f, out);
	}
}

int main (int argc, char ** argv)
{
	if (argc != 1) {
		PRINT ("Usage: mcc2cunf < XMLFILE > SPECFILE");
		return EXIT_ERR;
	}

	// parse the XML file, pset is the memory representation of it
	std::auto_ptr<mcc::property_set> pset;
	try {
		pset = mcc::property_set_ (std::cin, "(stdin)",
				xml_schema::flags::dont_validate);
	}
	catch (std::ifstream::failure & e) {
		PRINT ("mcc2cunf: cannot read standard input");
		return EXIT_ERR;
	}
	catch (xml_schema::exception & e) {
		std::cerr << "Error: " << e << std::endl;
		return EXIT_ERR;
	}

	// for each formula in the file ...
	for (auto p = pset->property().begin(); p != pset->property().end(); p++)
	{
		// reject the entire file on the first non-boolean formula
		auto & f = p->formula ();
		auto & bf = f.boolean_formula();
		if (! bf.present()) cannot ("can only handle boolean formulas");

		// translate the formula to Cunf's spec format
		std::string s;
		bool negate;
		translate_formula (bf.get (), s, negate);

		printf ("# %s %s\n%s;\n",
				negate ? "Y" : "N",
				p->id().c_str(), 
				s.c_str ());
	}
	exit (EXIT_OK);
}

