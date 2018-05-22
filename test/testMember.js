var Membership = artifacts.require("Membership");

contract('Contracts', function(accounts) {
    let membership;

    it('Setup contract for testing', async function () {
        membership = await Membership.new({from: accounts[3]});
        console.log("contract Membership.sol deployed");
    });

    it("Should assign memberhipType and memberId", async function () {
        await membership.setFee(5, {from: accounts[3]});
        console.log("membership.setFee set to 5");
        await membership.requestMembership({value: web3.toWei(5,'ether'), from: accounts[0]});
        console.log("requestMembership");
        assert(await membership.getMembershipType(accounts[0]) > 0, "MembershipType should not be zero");
        console.log("ensure member type is greater than zero");
    });

    it("Should assign membership details to new address", async function () {

        await membership.requestMembership({value: web3.toWei(5,'ether'), from: accounts[2]});
        console.log(await membership.owner.call(), accounts[3]);
        console.log(await membership.getMembershipType(accounts[2]));
        await membership.updateMemberAddress(accounts[2], accounts[1], {from: accounts[3]});
        console.log("updateMemberAddress");
        assert(await membership.getMembershipType(accounts[2]) == 0, "MembershipType should be zero");
        assert(await membership.getMembershipType(accounts[1]) > 0, "MembershipType should not be zero");
        console.log("ensure member type is greater than zero");
    });

    it("Should change fee using setFee from owner account", async function () {
        await membership.setFee(15, {from: accounts[3]});
        console.log("membership.setFee set to 15");
        assert(membership.memberFee = 15, "fee should be 15");
        console.log("ensure fee is 15");
    });

    it("Should change member current membershipType", async function () {
        await membership.setMembershipType(accounts[1],7, {from: accounts[3]});
        console.log("membership.setMembershipType set to 7");
        assert(await membership.getMembershipType(accounts[1]) == 7, "MembershipType should be 7");
        console.log("MembershipType should be 7");
    });

    /*how to*/
/** it("Should get members accounts list/array", async function () {
        let memAccts[] = await membership.getMembers({from: accounts[4]});
        console.log("membership.getMembers array- currently only one member on test");
        assert(await memAccts[] == [0,accounts[1]], "Members accounts list");
        console.log("Membership array should contain account 1");
    });
*/
    /*how to*/
/** it("Should get member information", async function () {
        await membership.getMember({from: accounts[1]});
        console.log("membership.getMember- info for member 1");
        assert(membership.members.memberId == 2 && membership.members.membershipType == 7, "Membership should be 1 and id 2");
        console.log("Membership count should be 1");
    });
*/
    /**
    research how to delete from array.
    */
    it("Should count number of members", async function () {
        let memCount = await membership.countMembers({from: accounts[4]});
        console.log("membership.countMembers- currently only one member on test");
        assert(await memCount == 2, "Membership count should be 1");
        console.log("Membership count should be 1");
    });

/*how to*/
/*  it("Should get membershipType", async function () {
        let oldMemberAcct = await membership.getMembershipType(accounts[0], {from: accounts[1]});
        let newMemberAcct = await membership.getMembershipType(accounts[1], {from: accounts[1]});
        console.log("updateMemberAddress");
        assert(oldMemberAcct  == 0, "MembershipType should be zero");
        assert(newMemberAcct == 7, "MembershipType should be 7");
        console.log("ensure member type is greater than zero");
    });
 */
    it("Should allow owner to change contract owner", async function () {
        await membership.setOwner(accounts[5], {from: accounts[3]});
        console.log("membership.setOwner set to 5");
        assert(membership.owner = accounts[5], "owner should be account 5");
        console.log("ensure new contract owner is account 5");
    });

})