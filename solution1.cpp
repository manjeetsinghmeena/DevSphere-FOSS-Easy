#include <iostream>
using namespace std;

int main() {
    int t; cin >> t;
    while(t--){
        long long n, k;
        cin >> n >> k;
        long long count = 0, current = 0;
        while (count < k) {
            current++;
            if (current % n != 0) count++;
        }
        cout << current << endl;
    }
    return 0;
}