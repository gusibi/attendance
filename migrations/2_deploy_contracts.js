var StringUtils = artifacts.require("./StringUtils.sol")
var AttendanceFactory = artifacts.require("./AttendanceFactory.sol");

module.exports = function(deployer) {
    deployer.deploy(StringUtils);
    deployer.link(StringUtils, AttendanceFactory);
    deployer.deploy(AttendanceFactory);
};