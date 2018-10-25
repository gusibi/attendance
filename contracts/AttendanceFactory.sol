pragma solidity ^0.4.19;
// pragma experimental ABIEncoderV2;
/* 打卡
1. 合约所有者可以创建打卡任务（打卡持续时间，打卡时间，比如：每天北京时间7点到8点）
2. 支付 n 以太 加入打卡，第二天开始
3. 连续打卡21 天的人平分总参与的钱。
4. 支持补打卡，当天补支付需要支付 n/21 * 2，补昨天的需支付 n/21 * 3，补前天的需支付 n/21 * 4，以此类推
*/

import "./stringUtils.sol";

contract AttendanceFactory {

    address public owner;

    event NewAttendance(uint aid, string name, uint16 start_date, uint8 period, uint8 price);
    event AttendanceEnded(uint aid);
    event LogUintArray(string, uint[]);
    function logUintArray(string s, uint[] x) internal{
        emit LogUintArray(s, x);
    }
    event LogAddress(string, address);
    event LogUint(string, uint);
    event LogUint16(string, uint16);
    event LogInt(string, int);
    event LogString(string, string);
    function logString(string s, string x) internal {
        emit LogString(s, x);
    }

    constructor() public {
        owner = msg.sender;
    }

    // 打卡数据
    struct Attendance{
        string  name;
        uint16  start_date; // 开始日期 （从1970kdui）
        uint8   period;  // 持续时间
        uint8   price;   // 参与需要支付的价格
        uint16  members_count; // 参与人数
        uint16  accomplish_count; // 完成(不间断打卡)人数
        uint16  rewards_amount; // 奖金池总额
        bool    ended;    // 是否结束，需要创建者手动结束
        address creator;  // 创建者
    }

    // event LogAttendanceArray(string, Attendance[]);

    Attendance[] public attendances; // 所有的打卡列表

    mapping (uint16 => uint[]) public dateAttendances; // 每天对应的打卡
    mapping (uint => address[]) public accomplishAttendance; // 完成打卡的统计(key 为 aid，value 为完成的参与者数组) 

    modifier onlyAttendanceExist(uint aid) {
        Attendance memory a = attendances[aid];
        require(StringUtils.compare(a.name, "") != 0, "attendance not exist"); // name 不为空，意思是 打卡存在
        _;
    }

    modifier onlyAttendanceCreator(uint aid) {
        Attendance memory a = attendances[aid];
        require(a.creator == msg.sender, "attendance not yours"); // 检查是否是你创建的打卡 
        _;
    }

    function _pushToUintArray(uint[] array, uint item) internal pure returns(uint[] memory){
        uint length = array.length;
        uint[] memory newArray = new uint[](length + 1);
        for (uint i = 0; i<length; i++){
            newArray[i] = array[i];
        }
        newArray[length] = item;
        return newArray;
    }

    function _updateDayAttendances(uint[] ats, uint aid) internal pure returns(uint[] memory){
        uint length = ats.length;
        uint[] memory newDayAttendances = new uint[](length + 1);
        for (uint i = 0; i<length; i++){
            newDayAttendances[i] = ats[i];
        }
        newDayAttendances[length] = aid;
        return newDayAttendances;
    }

    function createAttendance(string memory _name, uint16 _start_date, uint8 _period, uint8 _price) public{
        uint[] memory day_aids;  // 打卡 ID 列表
        uint id = attendances.push(Attendance(_name, _start_date, _period, _price, 0, 0, 0, false, msg.sender)) - 1;
        emit LogUint("days: ", _start_date);
        if (dateAttendances[_start_date].length > 0){
            day_aids = dateAttendances[_start_date];
        }
        // logUintArray("init attendances", day_aids);
        day_aids = _pushToUintArray(day_aids, id);
        dateAttendances[_start_date] = day_aids;
        // emit LogUint("add day: ", _start_date);
        // logUintArray("add attendance", dateAttendances[_start_date]);

        emit NewAttendance(id, _name, _start_date, _period, _price);
        // emit LogAttendanceArray("all attendance", attendances);
    }

    function getAttendance(uint aid) public view onlyAttendanceExist(aid) returns(
        uint id,
        string name,
        uint16 start_date, // 开始日期 （从1970kdui）
        uint8 period,  // 持续时间
        uint8 price,   // 参与需要支付的价格
        uint16 members_count, // 参与人数
        address creator  // 创建者
    ){
        Attendance memory a = attendances[aid];
        return (aid, a.name, a.start_date, a.period, a.price, a.members_count, a.creator);
    }

    function getValidAttendance() public view returns(uint[] memory){
        // 返回可参与（明天开始的打卡）打卡列表
        uint16 next_day;
        next_day = uint16(now / 86400) + 1;
        uint[] memory validAttendance;
        validAttendance = dateAttendances[next_day];
        // emit LogUint("next day: ", next_day);
        // logUintArray("valid attendance", validAttendance);
        return validAttendance; 
    }

    function getAttendanceByDay(uint16 day) public view returns(uint[] memory){
        // 返回可参与（明天开始的打卡）打卡列表
        uint[] memory dayAttendances;
        dayAttendances = dateAttendances[day];
        // emit LogUint("day: ", day);
        // logUintArray("date attendance", dayAttendances);
        return dayAttendances; 
    }
}