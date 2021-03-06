pragma solidity ^0.4.8;


import './ERC20.sol';
import './SafeMath.sol';
import './ds-auth.sol';


/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is DSAuth, ERC20, SafeMath {

  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  mapping (address => mapping (address => uint)) managed;
  mapping (address => uint) fee;
  mapping (address => uint) public totalManaged;
  address[] public managedArr;
  bool public  stopped;

  modifier stoppable {
    assert (!stopped);
    _;
  }

  function stop() auth {
    stopped = true;
  }

  function start() auth {
    stopped = false;
  }

  function transfer(address _to, uint _value) stoppable returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) stoppable returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function forward(address _proxy, uint _value) returns (bool success) {
    managed[msg.sender][_proxy] = _value;
    managedArr.push(msg.sender);
    totalManaged[_proxy] = safeAdd(totalManaged[_proxy], _value);
    return true;
  }
  
  function getItemsInManagedArr() constant returns (uint items) {
    return managedArr.length;
  }
  
  function getSingleItemInMangedArr(uint _item) constant returns (address) {
    return managedArr[_item];
  }

  function backward(address _who, uint _value) returns (bool success) {
    managed[_who][msg.sender] = _value;
    totalManaged[msg.sender] = safeSub(totalManaged[msg.sender], _value);
  }

  function managedWeight(address _owner, address _manager) constant returns (uint amount) {
    return managed[_owner][_manager];
  }

  function setFee(uint _fee) returns (bool success) {
    fee[msg.sender] = _fee;
    return true;
  }

  function feeAmount(address _who) constant returns (uint amount) {
    if(totalManaged[_who] > 0) throw;
    return fee[_who];
  }

  function approveSelfSpender(address _spender, uint _value) returns (bool success) {
    allowed[this][_spender] = _value;
    Approval(this, _spender, _value);
    return true;
  }
}
