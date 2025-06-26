#include "headers/util.cpp"
#include "headers/globalVariables.cpp"
#include "headers/initAndClean.cpp"
#include "headers/worker.cpp"

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        cerr << "Usage: ./a.out <input_file> <output_file>" << endl;
        return 0;
    }

    // check for intput file existence
    if (!ifstream(argv[1]))
    {
        cerr << "Error: Input file does not exist." << endl;
        return 1;
    }

    // File handling for input and output redirection
    ifstream inputFile(argv[1]);
    streambuf *cinBuffer = cin.rdbuf(); // Save original cin buffer
    cin.rdbuf(inputFile.rdbuf());       // Redirect cin to input file

    ofstream outputFile(argv[2]);
    streambuf *coutBuffer = cout.rdbuf(); // Save original cout buffer
    cout.rdbuf(outputFile.rdbuf());       // Redirect cout to output file

    cin >> N >> M;
    cin >> x >> y;

    if (N % M != 0)
    {
        cin.rdbuf(cinBuffer);
        cout.rdbuf(coutBuffer);
        cerr << "Error: N must be divisible by M." << endl;
        return 1;
    }

    // cout << "N: " << N << ", M: " << M << endl;
    // cout << "x: " << x << ", y: " << y << endl;

    // for(int i=1;i<=N;i++)
    // {
    //     operatives.push_back(Operative(i)); // Create and add Operative objects to the vector
    // }

    // for(Operative &o : operatives)
    // {
    //     o.printDetails(); // Print details of each operative
    // }

    initialize();

    vector<pThread> operativesThreads(N);
    vector<pThread> staffsThreads(numStaffs);

    for (int i = 0; i < numStaffs; i++)
    {
        newThread(&staffsThreads[i], NULL, intelligentStaffsWork, (void *)&staffs[i]);
    }

    for (int i = 0; i < N; i++)
    {
        newThread(&operativesThreads[i], NULL, operativesWork, &operatives[i]);
    }

    for (int i = 0; i < N; i++)
    {
        joinThread(operativesThreads[i], NULL);
    }

    for (int i = 0; i < numStaffs; i++)
    {
        joinThread(staffsThreads[i], NULL);
    }

    cleanup();

    // Restore cin and cout to their original states (console)
    cin.rdbuf(cinBuffer);
    cout.rdbuf(coutBuffer);

    return 0;
}

/*
```bash run-script.sh
    g++ -pthread 2105032.cpp -o 2105032
    ./2105032 data.in data.out
    rm -rf 2105032
```
*/