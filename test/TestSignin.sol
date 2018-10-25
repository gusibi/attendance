pragma solidity ^0.4.19;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Signin.sol";

contract TestSignin {

    uint public initialBalance = 100 ether; // or any other value

    function testParticipative() public {
        Signin signin = new Signin();
        uint[] memory day_aids = new uint[](1);
        day_aids[0] = 0;
        signin.createAttendance("test1", 27831, 10, 0); // msg.sender 没有余额，暂时设置为0
        Assert.equal(signin.getAttendanceByDay(27831), day_aids, "Valid date attendance error");

        uint[] memory paids = new uint[](1);
        paids[0] = 0;
        signin.participative(0);

        Assert.equal(signin.getParticipativedAttendance(), paids, "Participatived attendance error");
    }

    function testSignin() public {
        Signin signin = new Signin();
        uint[] memory day_aids = new uint[](1);
        uint16 start_date;
        start_date = uint16(now / 86400) - 1;
        day_aids[0] = 0;
        signin.createAttendance("test1", start_date, 10, 0);
        Assert.equal(signin.getAttendanceByDay(start_date), day_aids, "Valid date attendance error");

        uint[] memory paids = new uint[](1);
        paids[0] = 0;
        signin.participative(0);

        Assert.equal(signin.getParticipativedAttendance(), paids, "Participatived attendance error");

        Assert.equal(signin.signin(0), true, "Signin failed");
    }

    function testSigninRepeat() public {
        Signin signin = new Signin();
        uint[] memory day_aids = new uint[](1);
        uint16 start_date;
        start_date = uint16(now / 86400) - 1;
        day_aids[0] = 0;
        signin.createAttendance("test1", start_date, 10, 0);
        Assert.equal(signin.getAttendanceByDay(start_date), day_aids, "Valid date attendance error");

        uint[] memory paids = new uint[](1);
        paids[0] = 0;
        signin.participative(0);

        // 打卡
        Assert.equal(signin.getParticipativedAttendance(), paids, "Participatived attendance error");
        Assert.equal(signin.signin(0), true, "Signin failed");

        // 重复打卡
        Assert.equal(signin.getParticipativedAttendance(), paids, "Participatived attendance error");
        Assert.equal(signin.signin(0), false, "Signin failed");
    }

    // function testAddressArrayContains() public {
    //     Signin signin = new Signin();
    //     address[] memory a = new address[](1);
    //     a[0] = msg.sender;
    //     uint index = signin.addressArrayIndexOf(a, msg.sender);
    //     Assert.equal(index, 0, "index error");
    // }

    // function addressArrayIntersection() public{
    //     Signin signin = new Signin();
    //     address[] memory a = new address[](1);
    //     address[] memory b = new address[](1);
    //     address[] memory c;
    //     a[0] = msg.sender;
    //     address[] result = signin.addressArrayIntersection(a, b);
    //     Assert.equal(result, c, "intersection error");
    // }

    // use javascript test require
    // function testSigninBeforeStart() public {
    //     Signin signin = new Signin();
    //     uint[] memory day_aids = new uint[](1);
    //     uint16 start_date;
    //     start_date = uint16(now / 86400) + 1;
    //     day_aids[0] = 0;
    //     signin.createAttendance("test1", start_date, 10, 1);
    //     Assert.equal(signin.getAttendanceByDay(start_date), day_aids, "Valid date attendance error");

    //     uint[] memory paids = new uint[](1);
    //     paids[0] = 0;
    //     signin.participative(0);

    //     Assert.equal(signin.getParticipativedAttendance(), paids, "Participatived attendance error");
    //     // test signin before start

    //     bool result;
    //     (result,) = signin.signin(0);
    //     Assert.isFalse(result, "Signin failed");
    // }

    // function testSigninAfterEnd() public {
    //     Signin signin = new Signin();
    //     uint[] memory day_aids = new uint[](1);
    //     uint16 start_date;
    //     start_date = uint16(now / 86400) - 100;
    //     day_aids[0] = 0;
    //     signin.createAttendance("test1", start_date, 10, 1);
    //     Assert.equal(signin.getAttendanceByDay(start_date), day_aids, "Valid date attendance error");

    //     uint[] memory paids = new uint[](1);
    //     paids[0] = 0;
    //     signin.participative(0);

    //     Assert.equal(signin.getParticipativedAttendance(), paids, "Participatived attendance error");

    //     // test signin after finished
    //     Assert.equal(signin.signin(0), false, "Signin failed");
    // }
}