pragma solidity ^0.4.19;
/**
* 签到
* 1. 参与签到
* 2. 找到参与的列表
* 3. 签到
* 4. 补签
*/

import "./AttendanceFactory.sol";
import "./stringUtils.sol";

contract Signin is AttendanceFactory {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    mapping (address => uint[]) participativeAttendances; // 参与的打卡
    mapping (string => address[]) signinHistory; // 打卡记录
    /** 数据格式类似于
    {
        1-27831: [address1, address2, address3],
        1-27832: [address1, address2],
        1-27833: [address1]
    }
    key 为{aid}-{天数}， value 为当天打卡的人
     */
    
    /// 判断是否参与了打卡，未参与禁止操作
    modifier onlyParticipatived(uint aid) {
        uint[] memory paids = participativeAttendances[msg.sender];
        bool participatived = false;
        for (uint i = 0; i < paids.length; i++){
            if (aid == i){
                participatived = true;
            }
        }
        require(participatived == true, "attendance not participatived"); // 判断是否加入
        _;
    }

    /// 判断是否完成了打卡，未完成禁止操作
    modifier onlyAccomplished(uint aid) {
        address[] memory accomplish_members = accomplishAttendance[aid];
        bool accomplished = false;
        for (uint i = 0; i < accomplish_members.length; i++){
            if (msg.sender == accomplish_members[i]){
                accomplished = true;
            }
        }
        require(accomplished == true, "attendance not accomplished"); // 判断是否加入
        _;
    }

    /// 将数据追加到 address 数组，为了减少消耗 gas，使用内存处理
    function _pushToAddressArray(address[] array, address item) internal pure returns(address[] memory){
        uint length = array.length;
        address[] memory newArray = new address[](length + 1);
        for (uint i = 0; i<length; i++){
            newArray[i] = array[i];
        }
        newArray[length] = item;
        return newArray;
    }

    /// 拼接 signinHistory key
    function getSigninHistoryKey(uint aid, uint day) internal pure returns(string){
        string memory aid_str = StringUtils.uint2string(aid);
        string memory day_str = StringUtils.uint2string(day);
        string memory key;
        key = StringUtils.concat(aid_str, "-");
        key = StringUtils.concat(key, day_str);
        return key;
    }

    /// 获取已参与的打卡列表
    function getParticipativedAttendance() external view returns(uint[]){
        return participativeAttendances[msg.sender];
    }

    /// 参与打卡，需要支付押金到押金池，完成全部打卡的人平分押金池奖金
    /// 调用时 指定 msg.value 转入eth
    function participative(uint aid) external payable onlyAttendanceExist(aid) returns(uint[]){
        Attendance storage a = attendances[aid];
        // emit LogAddress("this", address(this));
        // emit LogUint("this.balance", address(this).balance);
        // emit LogAddress("owner", owner);
        // emit LogUint("owner.balance", owner.balance);
        // emit LogAddress("tx.origin", tx.origin);
        // emit LogUint("tx.origin.balance", tx.origin.balance);
        // emit LogAddress("address", msg.sender);
        // emit LogUint("balance", msg.sender.balance);
        // emit LogUint("price", a.price);
        // 加入需要支付
        require(msg.value >= a.price, "insufficient value");
        // 转账 成功后加入
        uint[] memory paids;  // 打卡 ID 列表
        if (participativeAttendances[msg.sender].length > 0){
            paids = participativeAttendances[msg.sender];
        }
        paids = _pushToUintArray(paids, aid);
        participativeAttendances[msg.sender] = paids;
        // count +1
        a.members_count += 1;
        return paids;
    }

    /// 打卡
    function signin(uint aid) external onlyParticipatived(aid) onlyAttendanceExist(aid) returns(bool success){
        Attendance memory attendance;
        attendance = attendances[aid];
        uint16 current_day;
        current_day = uint16(now/86400);
        // 在可打卡时间
        require(attendance.start_date <= current_day, "attendance not start");
        require(attendance.start_date + attendance.period >= current_day, "attendance already finished");

        address[] memory signinAddress;
        string memory key = getSigninHistoryKey(aid, uint(current_day));
        if (signinHistory[key].length > 0){
            signinAddress = signinHistory[key];
        }
        // 判断是否已经打卡，如果已经打卡，直接返回 true
        for (uint i = 0; i < signinAddress.length; i++){
            if (signinAddress[i] == msg.sender){
                // 如果已经打卡
                return false;
            }
        }
        signinAddress = _pushToAddressArray(signinAddress, msg.sender);
        signinHistory[key] = signinAddress;
        return true;
    }

    /// 打卡任务完成，将押金池中押金平分给完成全部打卡任务的成员
    /// 参与的人可领取奖励，并且只能领一次
    function withdraw(uint aid) public onlyAccomplished(aid) returns(bool){

    }

    function addressArrayIndexOf(address[] items, address item) internal pure returns(uint){
        uint index = uint(-1);
        for (uint i = 0; i < items.length; i++){
            if (items[i] == item){
                index = i;
            }
        }
        return index;
    }

    function addressArrayContains(address[] items, address item) internal pure returns(bool){
        uint index = addressArrayIndexOf(items, item);
        if (index >= 0){
            return true;
        }else{
            return false;
        }
    }

    function addressArrayIntersection(address[] a, address[] b) internal pure returns(address[]){
        uint a_length = a.length;
        uint b_length = b.length;
        address[] memory intersection;
        address[] memory small_addresses;
        address[] memory large_addresses;
        if (a_length > b_length){
            small_addresses = b;
            large_addresses = a;
        }else{
            small_addresses = a;
            large_addresses = b;
        }
        for (uint i = 0; i < large_addresses.length; i++){
            address add = large_addresses[i];
            if (addressArrayContains(small_addresses, add)){
                intersection = _pushToAddressArray(intersection, add);
            }
        }
        return intersection;
    }

    /// 打卡结束，结算
    function attendanceEnd(uint aid) external onlyAttendanceExist(aid) onlyAttendanceCreator(aid) {
        // 对于可与其他合约交互的函数（意味着它会调用其他函数或发送以太币），
        // 一个好的指导方针是将其结构分为三个阶段：
        // 1. 检查条件
        // 2. 执行动作 (可能会改变条件)
        // 3. 与其他合约交互
        // 如果这些阶段相混合，其他的合约可能会回调当前合约并修改状态，
        // 或者导致某些效果（比如支付以太币）多次生效。
        // 如果合约内调用的函数包含了与外部合约的交互，
        // 则它也会被认为是与外部合约有交互的。

        // 1. 条件
        Attendance storage attendance = attendances[aid];
        uint16 current_day = uint16(now / 86400);
        require(current_day > attendance.start_date + attendance.period, "Attendance not yet ended.");
        require(!attendance.ended, "Attendance yet ended.");

        // 2. 生效
        attendance.ended = true; // 只有标记为 true，参与者才能提现
        emit AttendanceEnded(aid);

        // 3. 交互（统计完成人数）
        // 先将第一天打卡的人设置为完成打卡的用户
        // 和接下来每一天的做比较，取交集，最终的用户即为完成打卡的用户
        address[] memory accomplish_members;
        for (uint16 day = attendance.start_date; day <= attendance.start_date + attendance.period; day++){
            // 获取打卡记录 并统计
            string memory key = getSigninHistoryKey(aid, day);
            address[] memory histories = signinHistory[key];
            address[] memory compare_members;
            // 如果只需要连续一天打卡，第一天打卡的人即为完成打卡的人
            if (day == attendance.start_date){
                accomplish_members = histories;
            }else{ // 从第二天开始做交集
                compare_members = histories;
                accomplish_members = addressArrayIntersection(accomplish_members, compare_members);
            }
        }
        // 将完成人数写入 storage
        attendance.accomplish_count = uint16(accomplish_members.length);
        // 将完成的人写入 storage
        accomplishAttendance[aid] = accomplish_members;
        // beneficiary.transfer(highestBid);
    }
    
}