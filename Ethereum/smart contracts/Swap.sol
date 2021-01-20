pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2;


contract PawPoints {
    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowance;
    string name;
    uint supply;
    event Allow(address, address, uint256);
    constructor(uint _supply, string _name) public {
        name = _name;
        supply = _supply;
        balance[msg.sender] = supply;
    }
    function getBalance(address a) public view returns (uint256) {
        return balance[a];
    }
    function approve(address spender, uint256 num) public returns (bool) {
        allowance[msg.sender][spender] = num;
        emit Allow(msg.sender, spender, num);
        return true;
    }
    function getAllowance(address from, address spender) public view returns (uint256) {
        return allowance[from][spender];
    }
    function transferFrom(address from, address to, uint256 num) public returns (bool) {
        if(allowance[from][msg.sender] >= num && balance[from] >= num) {
            balance[to] += num;
            balance[from] -= num;
            allowance[msg.sender][from] -= num;
            return true;
        }
        return false;
    }
}

contract Swap {
     struct Post {
        address party;
        uint256 points;
        uint256 nWei; // 10^18 wei = 1 Ether
        bool haveOrWant;
        bool isPost;
    }
    
    mapping (bytes32 => Post) posts;
    Post[] allPosts;
    address pointsContractAddress;
    event IdHave(bytes32);
    event IdWant(bytes32);

    constructor(address con) public {
        pointsContractAddress = con;
    }
    function getPosts() public view returns (Post[]) {
        return allPosts;
    }
    function have(uint256 points, uint256 nWei) payable public returns (bool) {
        bytes32 idWant = keccak256(abi.encodePacked(points, nWei, false));
        bytes32 idHave = keccak256(abi.encodePacked(points, nWei, true));
        PawPoints pointsContract = PawPoints(pointsContractAddress);
        if(posts[idHave].isPost) {
            return false;
        }
        if(posts[idWant].isPost) {
            // there is a matching want post
            if(pointsContract.getAllowance(msg.sender, this) >= points) {
                msg.sender.transfer(nWei);
                pointsContract.transferFrom(msg.sender, posts[idWant].party, points);
                return true;
            }
        } else {
            // create a new have post
            posts[idHave] = Post(msg.sender, points, nWei, true, true);
            allPosts.push(Post(msg.sender, points, nWei, true, true));
            return true;
        }
        return false;
    }

    function getAllow(address a) public view returns (uint256) {
        PawPoints pointsContract = PawPoints(pointsContractAddress);
        return pointsContract.getAllowance(a, this);
    }
    function want(uint256 points, uint256 nWei) payable public returns (bool) {
        bytes32 idWant = keccak256(abi.encodePacked(points, nWei, false));
        bytes32 idHave = keccak256(abi.encodePacked(points, nWei, true));
        emit IdHave(idHave);
        emit IdWant(idWant);
        PawPoints pointsContract = PawPoints(pointsContractAddress);
        if(posts[idWant].isPost) {
            return false;
        }
        if(posts[idHave].isPost) {
            // there is a matching have post
            if(pointsContract.getAllowance(posts[idHave].party, this) >= points) {
                posts[idHave].party.transfer(nWei);
                pointsContract.transferFrom(posts[idHave].party, msg.sender, points);
                return true;
            }
        } else {
            // create a new want post
            posts[idWant] = Post(msg.sender, points, nWei, false, true);
            allPosts.push(Post(msg.sender, points, nWei, false, true));
            return true;
        }
        return false;
    }

}
