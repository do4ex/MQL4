struct Name

{
    string first_name;                 // name
    string last_name;                  // last name
};

class CPerson
{
    protected:
    Name m_name;                     // name
    public:

    void SetName(string n);

    string GetName()
    {
        return (m_name.first_name + " " + m_name.last_name);
    }

    private:

    string GetFirstName(string full_name);

    string GetLastName(string full_name);
}

;

void CPerson::

SetName(string n)
{
    m_name.first_name = GetFirstName(n);
    m_name.last_name = GetLastName(n);
}

string CPerson::

GetFirstName(string full_name)
{
    int pos = StringFind(full_name, " ");
    if (pos > 0)
    {
        StringSetCharacter(full_name, pos, 0);
    }
    return (full_name);
}

string CPerson::

GetLastName(string full_name)
{
    string ret_string;
    int pos = StringFind(full_name, " ");
    if (pos > 0)
    {
        ret_string = StringSubstr(full_name, pos + 1);
    }
    else
    {
        ret_string = full_name;
    }
    return (ret_string);
}