
#include <iostream>
#include <fstream>
#include <stdexcept>
#include <string>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

#include "mcc-properties.hh"
#include "util/config.h"
#include "util/misc.h"

#define TMP "/tmp/"

std::string operator+ (const std::string & s, long i) 
{
	std::string ss (s);
	ss.append (std::to_string (i));
	return ss;
}

std::string operator+ (int i, const std::string & s)
{
	return s + i;
}

std::string & operator+= (std::string & s, long i) 
{
	return s.append (std::to_string (i));
}

#if 0
class Unfolding {

	std::string net_path;
	std::string unf_path;

public:

	Unfolding (std::string net_path) {
		struct stat stb;
		int ret;

		ret = stat (net_path.c_str (), &stb);
		if (ret < 0) {
			throw runtime_error (net_path + ": cannot read");
		}

		this->net_path = net_path;
		this->unf_path = std::string (TMP) + "d" + stb.st_dev;
		unf_path += "i" + to_string (stb.st_ino) + ".cuf";

		TRACE (stb.st_dev, "llu");
		TRACE (stb.st_ino, "lu");
		TRACE (this->net_path.c_str (), "s");
		TRACE (this->unf_path.c_str (), "s");
	}

	void compute (void) {
		int ret;
		struct stat stb;
		time_t t;

		/* read modification times of unfolding and net */
		ret = stat (net_path.c_str (), &stb);
		if (ret < 0) {
			throw runtime_error (net_path + ": cannot read");
		}
		t = stb.st_mtime;

		ret = stat (unf_path.c_str (), &stb);
		if (ret >= 0 && stb.st_mtime > t) {
			TRACE (t, "lu");
			TRACE (stb.st_mtime, "lu");
			return;
		}

		/* unfolding */
		ret = system (unf_path.c_str ());
		TRACE (ret, "d");
		if (ret < 0) {
			throw runtime_error ("Problems invoking cunf");
		}
	}
};
#endif

bool inv_dead (const mcc::property & p, long nre) {
	TRACE (p.id().c_str(), "s");

	const mcc::formula & f = p.formula ();
	if (typeid (f) != typeid (mcc::invariant)) return false;

	const mcc::invariant & finv = (const mcc::invariant &) f;
	const mcc::formula & f1 = finv.formula1 ();
	if (typeid (f1) != typeid (mcc::is_deadlock)) return false;

	cout << "FORMULA " << p.id ();
	cout << (nre == 0 ? " TRUE " : " FALSE ");
	cout << "TECHNIQUES NET_UNFOLDING" << endl;

	return true;
}

bool deadlock (const mcc::property & p, const std::string & unf) {
	int ret, i;
	char buff[1024];

	TRACE (p.id().c_str(), "s");

	const mcc::formula & f = p.formula ();
	if (typeid (f) != typeid (mcc::impossibility)) return false;

	const mcc::invariant & finv = (const mcc::invariant &) f;
	const mcc::formula & f1 = finv.formula1 ();
	if (typeid (f1) != typeid (mcc::is_deadlock)) return false;

	/* run cna for deadlocks */
	std::string cmd = "cna-mcc " + unf + " /tmp/cna.out ";
	cmd += "--deadlock --reduce 4-tree stb bin sccred";
	DEBUG ("Running cna: '%s'", cmd.c_str ());
	ret = system (cmd.c_str ());
	if (ret < 0) {
		cout << "CANNOT_COMPUTE" << endl;
		return true;
	}

	/* load the result */
	ifstream fin ("/tmp/cna.out");
	for (i = 0; i < 1024; i++) buff[i] = 0;
	fin.getline (buff, 1024);

	/* parse the result */
	TRACE (buff, "s");
	if (buff[16] != ':' && (buff[19] != 'Y' || buff[19] != 'N')) {
		cout << "CANNOT_COMPUTE" << endl;
		return true;
	}

	cout << "FORMULA " << p.id ();
	cout << (buff[18] == 'N' ? " TRUE " : " FALSE ");
	cout << "TECHNIQUES NET_UNFOLDING SAT_SMT" << endl;

	return true;

#if 0
	try {
		dynamic_cast<const mcc::formula_system &> (f);
		DEBUG ("It is formula_system");
	}
	catch (...) { 
		DEBUG ("Except 1");	
	}
	
	try {
		dynamic_cast<const mcc::invariant &> (f);
		DEBUG ("It is invariant");
	}
	catch (...) {
		DEBUG ("Except 2");	
	}
#endif
}

int main (int argc, char ** argv)
{
	/* wrapper pnml pep unf query nrevents */
	if (argc != 6) {
		TRACE (argc, "d");
		cout << "CANNOT_COMPUTE" << endl;
		return 0;
	}

	std::string pnml = argv[1];
	std::string pep   = argv[2];
	std::string unf   = argv[3];
	std::string query = argv[4];
	long   nre   = stol (argv[5]);

	/* pset is the memory representation of the xml file */
	auto_ptr<mcc::property_set> pset;
	try {
		ifstream fin;
		fin.exceptions (ifstream::badbit | ifstream::failbit);
		fin.open (query);
		pset = mcc::property_set_ (fin, query, xml_schema::flags::dont_validate);
	}
	catch (ifstream::failure & e) {
		cerr << query + ": cannot open" << endl;
		cout << "CANNOT_COMPUTE" << endl;
		return 0;
	}
	catch (xml_schema::exception & e) {
		cerr << e << endl;
		cout << "CANNOT_COMPUTE" << endl;
		return 0;
	}

	/* for each formula in the file, run the verification */
	int i = 0;
	for (mcc::property_set::property_iterator p = pset->property().begin();
			p != pset->property().end(); p++) {

		DEBUG ("Formula %d", i++);
		if (deadlock (*p, unf)) continue;
		if (inv_dead (*p, nre)) continue;
		cout << "DO_NOT_COMPETE" << endl;
	}

	return 0;
}

