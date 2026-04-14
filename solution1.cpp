#include <iostream>
using namespace std;

int main() {
    int t;
    cin >> t;
    while(t--) {
        long long n, k;
        cin >> n >> k;
        
        long long current = k / (n - 1);
        long long current1 = k % (n - 1);
        long long count = current * n + current1;
        
        cout << count << endl;
    }
    return 0;
}