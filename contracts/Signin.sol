pragma solidity ^0.4.19;
/**
* 签到
* 1. 参与签到
* 2. 找到参与的列表
* 3. 签到
* 4. 补签
*/

import "./AttendanceFactory.sol";

contract Signin is AttendanceFactory {

    mapping (address => uint[]) participativeAttendances; // 参与的打卡
    mapping (uint => address[]) signinHistory; // 打卡记录
    /** 数据格式类似于
    {
        27831: [address1, address2, address3],
        27832: [address1, address2],
        27833: [address1]
    }
    key 为天数， value 为当天打卡的人
     */
    
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

    function _pushToAddressArray(address[] array, address item) internal pure returns(address[] memory){
        uint length = array.length;
        address[] memory newArray = new address[](length + 1);
        for (uint i = 0; i<length; i++){
            newArray[i] = array[i];
        }
        newArray[length] = item;
        return newArray;
    }

    function getParticipativedAttendance() external view returns(uint[]){
        return participativeAttendances[msg.sender];
    }

    function participative(uint aid) external payable returns(uint[]){
        // TODO 加入需要支付一笔钱
        uint[] memory paids;  // 打卡 ID 列表
        if (participativeAttendances[msg.sender].length > 0){
            paids = participativeAttendances[msg.sender];
        }
        paids = _pushToUintArray(paids, aid);
        participativeAttendances[msg.sender] = paids;
        return paids;
    }

    function signin(uint aid) external onlyParticipatived(aid) onlyAttendanceExist(aid) returns(bool success){
        Attendance memory attendance;
        attendance = attendances[aid];
        uint16 current_day;
        current_day = uint16(now/86400);
        // 在可打卡时间
        emit LogUint16("start_date", attendance.start_date);
        emit LogUint16("current_date", current_day);
        emit LogUint16("end_date", attendance.start_date + attendance.period);
        require(attendance.start_date <= current_day, "attendance not start");
        require(attendance.start_date + attendance.period >= current_day, "attendance already finished");

        address[] memory signinAddress;
        if (signinHistory[aid].length > 0){
            signinAddress = signinHistory[aid];
        }
        _pushToAddressArray(signinAddress, msg.sender);
        return true;
    }
}