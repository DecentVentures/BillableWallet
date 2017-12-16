pragma solidity ^0.4.17;

contract BillableWallet {

  struct Bill {
    uint amount;
    address biller;
  }

  struct Authorization {
    uint amount;
    uint waitTime;
  }

  struct BillerProfile {
    uint lastBilled;
    uint lastPaid;
    uint lastAuthorized;
  }

  address public owner;

  Bill[] pendingBills;
  Bill[] paidBills;
  mapping(address => Authorization) authorizations;
  mapping(address => BillerProfile) billerProfiles;


  function BillableWallet(address creator) public {
    owner = creator;
  }

  function authorizedFor(uint amount, address biller) public {
    BillerProfile billerProfile = billerProfiles[biller];
    Authorization auth = authorizations[biller];
    uint lastBillTime = billerProfile.lastAuthorized;
    uint waitTime = auth.waitTime;
    uint minTime = lastBillTime + waitTime;
    return now >= minTime && amount <= auth.amount;
  }

  function markPaid(uint pendingBillIndex) internal {
    uint length = pendingBills.length;
    Bill paidBill = pendingBills[pendingBillIndex];
    pendingBills[pendingBillIndex] = pendingBills[length - 1];
    delete pendingBills[length - 1];
    pendingBills.length--;
    paidBills.push(paidBill);
    billerProfiles[paidBill.biller].lastPaid = now;
  }

  function bill(uint amount) public {
    billerProfile[msg.sender].lastBilled = now;
    pendingBills.push(Bill(amount, msg.sender));
    if(authorizedFor(amount, msg.sender) && this.balance > amount) {
      billerProfile[msg.sender].lastAuthorized = now;
      markPaid(pendingBills.length -1);
      msg.sender.transfer(amount);
    }
  }

  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }

  function approve(uint pendingBillIndex) public ownerOnly {
    uint billAmt = pendingBills[pendingBillIndex].amount;
    if(msg.sender == owner && this.balance > billAmt) {
      markPaid(pendingBillIndex);
      msg.sender.transfer(billAmt);
    }
  }

  function authorize(address biller, uint amount, uint waitTime ) public ownerOnly {
    authorizations[biller] = Authorization(amount, waitTime);
  }

  function send(uint amount, address to) public ownerOnly {
    to.transfer(amount);
  }
}


