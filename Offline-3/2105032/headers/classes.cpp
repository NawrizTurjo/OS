#pragma once
#include "util.cpp"

// # Operative class --- Task 1
class Operative
{
public:
    int identifier;
    int unitNum;
    int stationNum;
    bool isLeader;

    Operative(int id)
    {
        this->identifier = id;
        this->unitNum = (id - 1) / M + 1;
        this->stationNum = (id % 4) + 1;
        this->isLeader = (id % M == 0);
    }

    void printDetails()
    {
        cout << "Operative ID: " << identifier
             << ", Unit Number: " << unitNum
             << ", Station Number: " << stationNum
             << ", Is Leader: " << (isLeader ? "Yes" : "No") << endl;
    }
};
vector<Operative> operatives;

// # Intelligent Staff class --- Task 2
class IntelligentStaff
{
public:
    int id;

    IntelligentStaff(int id) : id(id) {}
};
vector<IntelligentStaff> staffs;