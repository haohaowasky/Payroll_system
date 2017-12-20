pragma solidity ^0.4.10;

// For the sake of simplicity lets assume EUR is a ERC20 token
// Also lets assume we can 100% trust the exchange rate oracle

import "./ERC223.sol";
import "./SafeMath.sol";


contract PayrollInterface {

    // this module does a good job in math work;
    using SafeMath for uint256;

    // employee's info
    struct employinfo {
        address emp_address; // each employee has an address
        uint256 emp_salary;
        address[] emp_allowtoken;
        uint time_pay;
        uint time_allocation;
        uint256 token_allocation;
    }

    // public variables
    mapping (uint256 => employinfo) public emp_book; // ID points to employess's info
    mapping (address => bool) public emp_check; // Authorization for the functions for employees only
    mapping (address => uint256) public exchangeboard; // for oracle
    mapping (address => uint256) public Get_Id; // for msg.sender to theri IDs

    // for the payday and allocation function
    mapping (address => mapping(address => uint256)) public emp_addr_allocation;


    address public owner;
    address public oracle;
    uint256 public emp_count = 0;  // counter for total people
    uint256 public total_pay = 0; // counter for yearly total spent on salary from company


    // private valraibles
    uint256 private emp_id = 1000; // Eployee's ID goes from 1000
    uint256 private balance; // Balance for ethereum




    modifier employee_only {
        require(emp_check[msg.sender] == true);
        _;
    }



    // constructor
    function PayrollInterface(address addr_oracle){
        owner = msg.sender;
        oracle = addr_oracle;
    }



    /* OWNER ONLY */
    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary)returns(uint256){
        require(msg.sender == owner);
        emp_id += 1; // generate a new ID

        // initialization for the infos
        emp_book[emp_id].emp_address = accountAddress;
        emp_book[emp_id].emp_salary = initialYearlyEURSalary;
        emp_book[emp_id].emp_allowtoken = allowedTokens;
        emp_book[emp_id].time_pay = 0;

        emp_check[accountAddress] = true; // I made a mapping for use in EMPLOYEE ONLY functions since

        // their address points to their IDs
        Get_Id[accountAddress] = emp_id;
        // uodates the total headcount
        emp_count += 1;
        // updates the total spent
        total_pay = total_pay.add(initialYearlyEURSalary);

        return emp_id; // since the ID is not given, I will just generate one, starting from 1001 till whatever.
    }


    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary){
        require(msg.sender == owner);

        // firtst substract the old salary
        total_pay = total_pay.sub(emp_book[employeeId].emp_salary);
        // updates the salary
        emp_book[employeeId].emp_salary = yearlyEURSalary;
        // Add the new salary
        total_pay = total_pay.add(yearlyEURSalary);

    }


    function removeEmployee(uint256 employeeId){
        require(msg.sender == owner);
        // substract the salary from the total count
        total_pay = total_pay.sub(emp_book[employeeId].emp_salary);
        // take down the access to call the functions
        emp_check[emp_book[employeeId].emp_address] = false;
        // substract the total number
        emp_count -= 1;
        // remove the pointer
        delete(emp_book[employeeId]);
    }


    function addFunds() payable returns(uint256){
        require(msg.sender == owner);
        // add ether
        balance = msg.value;

        return balance;
    }

    function scapeHatch(){
        require(msg.sender == owner);
        // take all the ether to owner
        selfdestruct(msg.sender);

    }


    function tokenFallback(address _from, uint _value, bytes _data) public returns(uint) {

        // this is like the payable function for msg.value in ERC223
        ERC223 token = ERC223(msg.sender);
        return token.balanceOf(this);

    } // Use approveAndCall or ERC223 tokenFallback


    function getEmployeeCount() constant returns (uint256){
        require(msg.sender == owner);
        return emp_count;
    }



    function getEmployee(uint256 employeeId) constant returns (address, uint256, address[], uint, uint, uint256){
        require(msg.sender == owner);
        // returns all the information for emplyee
        return (emp_book[employeeId].emp_address,
                emp_book[employeeId].emp_salary,
                emp_book[employeeId].emp_allowtoken,
                emp_book[employeeId].time_pay,
                emp_book[employeeId].time_allocation,
                emp_book[employeeId].token_allocation
                );
    }


    function calculatePayrollBurnrate() constant returns (uint256){
        return total_pay / 12;
    } // Monthly EUR amount spent in salaries



    function calculatePayrollRunway(address[] allthetokens) constant returns (uint256){
        uint256 total = 0;

        // get all the tokens, convert them into EUR, all them to the total and devided by spent per day

        for (uint8 i = 0; i < allthetokens.length; i++) {
            ERC223 token = ERC223(allthetokens[i]);
            uint256 fund = token.balanceOf(allthetokens[i]);
            uint256 money = fund.div(exchangeboard[allthetokens[i]]);
            total = total.add(money);
        }

        return total/ (total_pay/365);

    } // Days until the contract can run out of funds



    /* EMPLOYEE ONLY */

    function determineAllocation(address[] tokens, uint256[] distribution) employee_only returns(bool){

        // get the employee's information
        var employee = emp_book[Get_Id[msg.sender]];
        require(now - employee.time_pay > 15552000 ); // 180 days in seconds;

        // use mapping inside of mapping for the allocation;
        for (uint8 i = 0; i < tokens.length; i++){
            emp_addr_allocation[employee.emp_address][tokens[i]] = distribution[i];
        }

        // updates the time for the next round
        employee.time_allocation = now;

        return true;
    }// only callable once every 6 months



    function payday() employee_only returns(bool){

        // get the employee's information
        var employee = emp_book[Get_Id[msg.sender]];

        require(now - employee.time_pay > 2592000 ); // 30 days in seconds;

        for (uint8 i = 0; i < employee.emp_allowtoken.length; i++) {

            // if the allocation is 0, go skip and go check the next one
            if (emp_addr_allocation[employee.emp_address][employee.emp_allowtoken[i]] == 0)  //  map=> map

                continue;
                // get the rate, so I don't need to use the long code
                uint256 allocate_rate = emp_addr_allocation[employee.emp_address][employee.emp_allowtoken[i]];

                // the math, devided by 1200 so it is monthly rate, and take the decimals
                uint256 tokenAmount = employee.emp_salary.mul(allocate_rate).mul(exchangeboard[employee.emp_allowtoken[i]]) / 1200;

                // call the token address
                ERC223 token = ERC223(employee.emp_allowtoken[i]);

                // do the payment
                token.transfer(msg.sender, tokenAmount);

            }

        employee.time_pay = now;


        return true;
    } // only callable once a month


    /* ORACLE ONLY */

    function setExchangeRate(address token, uint256 EURExchangeRate) {
        require(msg.sender == oracle); // don't forget change it to oracle
        exchangeboard[token] = EURExchangeRate;

    } // uses decimals from token
}
