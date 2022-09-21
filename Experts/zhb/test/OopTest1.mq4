
struct Name{

	string firstName;
	string secondsName;
}

class CPersion{

	protected:
		Name mName;
	public:
		void SetName(string n);

	string getName() {

		return (mName.firstName+ " "+ mName.secondsName);
	}

	private:
		string getFirstName(string fullName);

		string getlastName(string fullName);

};

void CPersion::
	SetName(string n){
		mName.firstName = getFirstName(n);
		mName.secondsName = getlastName(n);
	}





























