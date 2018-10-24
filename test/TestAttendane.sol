pragma solidity ^0.4.19;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/AttendanceFactory.sol";

contract TestAttendane {

    // event LogUintArray(string, uint[]);

    // function testInitialAttendanceUsingDeployedContract() {

    //     AttendanceFactory attendance = AttendanceFactory(DeployedAddresses.AttendanceFactory());

    //     uint[] memory day_aids;
    //     attendance.AttendanceFactory("test1", 17830, 10, 1);

    //     Assert.equal(attendance.getValidAttendance(), day_aids, "Owner should have 10000 MetaCoin initially");
    // }

    function testCreateAttendance() public {
        AttendanceFactory attendance = new AttendanceFactory();

        uint[] memory day_aids = new uint[](1);
        day_aids[0] = 0;

        attendance.createAttendance("test1", 27831, 10, 1);

        Assert.equal(attendance.getAttendanceByDay(27831), day_aids, "Valid date attendance error");
    }

    function testEmptyValidAttendance() public {
        AttendanceFactory attendance = new AttendanceFactory();

        uint[] storage day_aids;
        attendance.createAttendance("test1", 27830, 10, 1);

        Assert.equal(attendance.getValidAttendance(), day_aids, "Valid attendance error");
    }

    function testValidAttendance() public {
        AttendanceFactory attendance = new AttendanceFactory();

        // uint[] memory valid_aids = new uint[](1);
        // valid_aids[0] = 0;
        uint[] storage valid_aids;
        valid_aids.push(0);

        uint[] memory _validAttendance;
        attendance.createAttendance("test1", 17829, 10, 1);

        _validAttendance = attendance.getValidAttendance();
        Assert.equal(_validAttendance, valid_aids, "Valid attendance error");
    }

    function testGetAttendance() public {
        AttendanceFactory attendance = new AttendanceFactory();

        attendance.createAttendance("test1", 27831, 10, 1);
        string memory name;
        (,name,,,,,) = attendance.getAttendance(0);
        Assert.equal(name, "test1", "attendance error");
    }
}