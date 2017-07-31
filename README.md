# Digital Shares

Digital Shares contract describes the idea of distributing profit to share holders according to their share balance.

The problem with such contracts is to distribute profit we have to keep a list of share holders and iterate over it and calculate and record each holders profit. We need to distribute profit in one transaction because share holders can exchange their shares simultaniously. When there are not so many holders the scheme with iteration works fine, but when number of share holders grows above 200 distribute profit function runs out of gas. This happens because storing each holders profit takes from 5000 to 20000 gas. In Homestead block gas limit is 4712388. So this effectively limits storage operations which are required to run when we distribute profit.

We propose a solution to overcome this limitation. The proposed contract can distribute profit between any number of share holders.  

## Proposed solution

The idea is to hold share distribution in a separate contract. In our case it is called ShareSnapshot. The main contract, called DigitalShare, holds a list of addressed to ShareSnapshot contracts. When it is time to distribute profit DigitalShare locks latest ShareSnapshot contract from updates and creates new ShareSnapshot contract and add its address to array. This does not cost a lot of gas. One can say that we need to copy share distribution to a new contract. But the focus is that ShareSnapshot holds share movements from the latest profit distribution. Holding an array of ShareSnapshot addresses we can reconstruct any address share balance at any moment.  For example: at the beginning we have 4 share holders. Each of them owns 10 shares with 40 total share count. Let's name them A,B,C and D. So ShareSnapshot share distribution table looks like this:

* A = 10
* B = 10
* C = 10
* D = 10

When it is time to distribute profit a new ShareSnapshot is created with empty share distribution table. Let's asssme A wants to sell B 5 of his shares. In second ShareSnapshot contract share distribution table would look like this:

* A = -5
* B = 5
* C = 0
* D = 0

If we need to get share balance of A, we need to go from the first ShareSnapshot contract to the last one and just summarize share movements. So in our example share balance of A looks like 10 - 5 which equals 5. Share balance of B looks like 10 + 5 which is 15.  
When the holder comes for his payment he calls `withdraw` method of DigitalShare contract. The DigitalShare contract goes through all stored ShareSnapshot contracts, except the last one, and summarize holders share balance.

