//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;


contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum,string name,string description,string image,uint target,string currencyname,string currencysymbol) public {
        require(minimum<target,"Target cannot be small then minContribution");
        require(minimum>=10001,"minimuc connot less then 10000");
        address newCampaign = new Campaign(minimum, msg.sender,name,description,image,target,currencyname,currencysymbol);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}


contract Campaign {
  struct Request {
      string description;
      uint value;
      address recipient;
      bool complete;
      bool rejected;
      uint approvalCount;
      uint rejectedCount;
      mapping(address => bool) approvals;
      mapping(address => bool) rejection;
      uint requestedTime;
      uint votersCount;
      mapping(address =>bool) voters;

  }
event RequestStatus(string message);
  Request[] public requests;
  address public manager;
  uint public minimunContribution;
  string public CampaignName;
  string public CampaignDescription;
  string public imageUrl;
  uint public targetToAchieve;
  address[] public contributers;
  mapping(address => bool) public approvers;
  uint public approversCount;
  address public cmpyTokenAddress;
  string public currencyName;
  string public currencySymbol;
  bool public active=true;
  ERC20Token cmpytoken;
  modifier restricted() {
      require(msg.sender == manager,"Only Owner Can Do this Operation");
      _;
  }
  modifier activestate(){
    require(active);
    _;
  }

  function Campaign(uint minimun, address creator,string name,string description,string image,uint target, string currencyname,string currencysymbol) public {
      manager = creator;
      minimunContribution = minimun;
      CampaignName=name;
      CampaignDescription=description;
      imageUrl=image;
      targetToAchieve=target;
      currencyName=currencyname;
      currencySymbol=currencysymbol;
      cmpyTokenAddress=new ERC20Token(currencyname,currencysymbol,18,minimunContribution,creator,target);
      cmpytoken=ERC20Token(cmpyTokenAddress);
  }


  function getCompanytokenaddr() returns(address){
      return cmpyTokenAddress;
  }

  function contibute() public payable activestate {
      require(msg.value >= minimunContribution,"Amount Sent Was Less Than Min Contribution" );
      require(msg.sender!=manager,"Camp creator connot be donar");
      contributers.push(msg.sender);
      approvers[msg.sender] = true;
      approversCount++;
      cmpytoken.invest(msg.value,msg.sender);

  }

  function createRequest(string description, uint value, address recipient) public restricted {
      Request memory newRequest;
         newRequest.description= description;
         newRequest.value= value;
        newRequest.recipient= recipient;
         newRequest.complete= false;
         newRequest.approvalCount= 0;
         newRequest.requestedTime=block.timestamp;
        //  votersCount 
          

      requests.push(newRequest);
  }

  function approveRequest(uint index) public {
        require(requests[index].requestedTime+360>=block.timestamp,"Voting Process ended");
    //   if(index!=0){
    //       require(requests[index-1].voters[msg.sender],"You Have Not Voted Previous Decision -- Not Allowed to Appr/Deny Upcomming request");
    //   }
      require(approvers[msg.sender],"You Are NOt a Backer");
      require(!requests[index].approvals[msg.sender],"You already Approved this request");
       require(!requests[index].rejection[msg.sender],"You Already REjected Request");

      requests[index].approvals[msg.sender] = true;
      requests[index].approvalCount++;

       requests[index].voters[msg.sender]=true;
            requests[index].votersCount++;
  }

  function rejectRequest(uint index) public{
           require(requests[index].requestedTime+360>=block.timestamp,"Voting Process ended");
    //   if(index!=0){
    //       require(requests[index-1].voters[msg.sender],"You Hove No permission to Vote Upcomming Request");
    //   }
      require(approvers[msg.sender],"You are not a backer");
      require(!requests[index].approvals[msg.sender],"You already Approved this request");
      require(!requests[index].rejection[msg.sender],"You Already REjected Request");

       requests[index].rejection[msg.sender] = true;
    
    requests[index].voters[msg.sender]=true;
         requests[index].votersCount++;
  }

  function finalizeRequest(uint index) public restricted returns(string memory){
        require(!requests[index].complete,"This REquest Already Finalied");
        
      require((requests[index].requestedTime+360<=block.timestamp||approversCount==0),"Voting still in Process");

      
         
         if(requests[index].approvalCount > (approversCount / 2)){
          requests[index].recipient.transfer(requests[index].value);
          requests[index].complete = true;
        emit RequestStatus("Request FulFilled Successfully");
         }
         else if(approversCount==0){
             requests[index].recipient.transfer(requests[index].value);
                 requests[index].complete = true;
          emit RequestStatus(" No Approvers-- Request FulFilled ");

         }
         else{
                approversCount=requests[index].votersCount;
                requests[index].complete = true;
                requests[index].rejected=true;
          emit RequestStatus("Request Failed -- InsufficientVote");
         }

         /// Making Non Voters as NonApprovers:----
         for (uint i=0;i<contributers.length;i++){
             if(!requests[index].voters[contributers[i]]){
                 approvers[contributers[i]]=false;
                 approversCount--;
             }
         }

            
//       }
//       else{
//    require(requests[index].approvalCount > (approversCount / 2));
//       require(!requests[index].complete);

//       requests[index].recipient.transfer(requests[index].value);
//       requests[index].complete = true;
//       }
   


  }
function deactivate() public restricted{
active=false;
}

    function getSummary() public view returns (uint,uint,uint,uint,address,string,string,string,uint,address,string,string) {
        return(
            minimunContribution,
            this.balance,
            requests.length,
            approversCount,
            manager,
            CampaignName,
            CampaignDescription,
            imageUrl,
            targetToAchieve,
            cmpyTokenAddress,
            currencyName,
            currencySymbol

          );
    }

    function getRequestsCount() public view returns (uint){
        return requests.length;
    }
    function getRequestDetaile(uint index) public view returns(uint)
{
 return requests[index].requestedTime;
}
}




//erc 20 token creation




contract ERC20Token {
   
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint public minInvest;
    uint public tokenPrice;
    address public manager;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
      
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function ERC20Token(string tokenName, string tokenSymbol, uint8 decimalUnits,uint _minContribution, address _manager, uint target) public {
       
        totalSupply = (target/_minContribution)*10**34;
         balanceOf[_manager] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        manager=_manager;
        minInvest=_minContribution;
        tokenPrice=minInvest/10000;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        require(balanceOf[to] + value >= balanceOf[to]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function invest(uint amount,address sender) payable public returns (bool){
    
    require(amount>=minInvest);
    uint tokens=(amount/tokenPrice)*10**18; 
    require(balanceOf[manager]>tokens,"All Company Share is in circulation");
    balanceOf[sender]+=tokens;
    balanceOf[manager]-=tokens;
    return true;
}

function burn(uint _amount) public{
    require(balanceOf[msg.sender]>=_amount,"You dont have enough fund to burn");
    balanceOf[msg.sender]-=_amount;


}




}
