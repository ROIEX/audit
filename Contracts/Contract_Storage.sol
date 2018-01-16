pragma solidity ^0.4.15;
/* @file
 * @title CoinContract and Storage
 * @version 2.0.0
*/
contract CoinStorage {
  bool private workingState = false;
  address public owner;
  address public processor;
  mapping (address => uint256) private etherClients;
  event ContractEnabled();
  event ContractDisabled();

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  modifier processorAndOwner {
    require((msg.sender == processor)||(msg.sender == owner));
    _;
  }
  modifier workingFlag {
    require(workingState == true);
    _;
  }
  //@title Constructor
  function CoinStorage() public {
    owner = msg.sender;
    enableContract();
  }
  //@title Destructor
  function kill() public onlyOwner {
    require(workingState == false);
    selfdestruct(owner);
  }
  //@title Contract enabler
  function enableContract() public onlyOwner {
    workingState = true;
    ContractEnabled();
  }
  //@title Contract disabler
  function disableContract() public onlyOwner {
    workingState = false;
    ContractDisabled();
  }
  //@title Contract processor setter
  function setProcessor(address _processor) public onlyOwner {
    processor = _processor;
  }
  //@title Contract payment function
  function pay(address _client, uint256 _amount) public processorAndOwner workingFlag returns (uint256 ret) {
    etherClients[_client] += _amount;
    ret = etherClients[_client];
  }
  //@title Contract refund function
  function refund(address _client, uint256 _amount) public processorAndOwner workingFlag returns (uint256 ret) {
    etherClients[_client] -= _amount;
    ret = etherClients[_client];
  }
  //@title Sender funds getter
  function getInvestorFund(address _sender) public view workingFlag returns (uint256 amount) {
    return etherClients[_sender];
  }
}

contract CoinContract {
  bool private workingState = false;
  bool private preicoState = true;
  address public owner;
  address private proxy;
  CoinStorage private data;
  event FundsGot(address indexed _sender, uint256 _value, uint256 _state);
  event Refund(address client, uint256 value);
  event ContractEnabled();
  event ContractDisabled();
  event PayState(bool result);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  modifier proxyAndOwner {
    require((msg.sender == proxy)||(msg.sender == owner));
    _;
  }
  modifier workingFlag {
    require(workingState == true);
    _;
  }
  //@title Constructor
  function CoinContract() public {
    owner = msg.sender;
    enableContract();
  }
  //@title Destructor
  function kill() public onlyOwner {
    require(workingState == false);
    selfdestruct(owner);
  }
  //@title Contract enabler
  function enableContract() public onlyOwner {
    workingState = true;
    ContractEnabled();
  }
  //@title Contract disabler
  function disableContract() public onlyOwner {
    workingState = false;
    ContractDisabled();
  }
  //@title Contract proxy setter
  function setProxy(address _proxy) public onlyOwner {
    proxy = _proxy;
  }
  //@title Contract proxy setter
  function setData(address _data) public onlyOwner {
    data = CoinStorage(_data);
  }
  //@title Contract payment function
  function pay(address _client, uint256 _amount, uint256 _price) public proxyAndOwner workingFlag {
    require(_price > 0);
    bool res = false;
    uint256 state = data.pay(_client, _amount);
    uint256 value = _amount * _price;
    FundsGot(_client, _amount, state);
    res = proxy.call(bytes4(keccak256("generateTokens(address,uint256)")), _client, value);
    PayState(res);
  }
  function cashback(address _client, uint256 amountToken, uint256 amountWei) public workingFlag onlyOwner returns (bool ret) { // amountToken is an amount of tokens that should be refunded
    uint256 fund = data.getInvestorFund(_client);
    if ((fund > 0)&&(amountWei > 0)&&(amountWei < fund)) {
      data.refund(_client, amountWei);
      //proxy.call(bytes4(keccak256("destroyTokens(address,uint256)")), _client, amountToken);
      ret = proxy.call(bytes4(keccak256("refund(address,uint256,uint256)")), _client, amountWei, amountToken);
    }
  }
}
