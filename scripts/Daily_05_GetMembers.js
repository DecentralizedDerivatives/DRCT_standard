/**
*This checks payments submitted to membership
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Membership = artifacts.require("Membership");

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
var _membership = "0xd33615c5ea5d703f06d237f6c56ff2400b564c77";// mainnet

console.log(_nowUTC);
module.exports =async function(callback) {

    let membership;
        membership = await Membership.at(_membership);
        console.log("membership: ", membership.address);
        sleep_s(5);
        membersAccts = await membership.getMembers();
        console.log("MemberAccts: ", membersAccts);

}