// var Membership = artifacts.require("Membership");

// contract('Membership', function(accounts) {
//     let membership;

//     it('Setup contract for testing', async function () {
//         membership = await Membership.new({from: accounts[3]});
//     });

//     it("Should assign memberhipType and memberId", async function () {
//         await membership.setFee(5, {from: accounts[3]});
//         await membership.requestMembership({value: web3.toWei(5,'ether'), from: accounts[0]});
//         assert(await membership.getMembershipType(accounts[0]) > 0, "MembershipType should not be zero");
//     });

//     it("Should assign membership details to new address", async function () {
//         await membership.updateMemberAddress(accounts[0], accounts[1], {from: accounts[3]});
//         assert(await membership.getMembershipType(accounts[0]) == 0, "MembershipType should be zero");
//         assert(await membership.getMembershipType(accounts[1]) > 0, "MembershipType should not be zero");
//     });

//     it("Should change fee using setFee from owner account", async function () {
//         await membership.setFee(15, {from: accounts[3]});
//         assert(membership.memberFee = 15, "fee should be 15");
//     });

//     it("Should change member current membershipType", async function () {
//         await membership.setMembershipType(accounts[1],7, {from: accounts[3]});
//         assert(await membership.getMembershipType(accounts[1]) == 7, "MembershipType should be 7");
//     });

//     it("Should get members accounts list/array", async function () {
//         let memAccts = await membership.getMembers({from: accounts[4]});
//         assert(await memAccts == accounts[1], "Members accounts list");
//     });

//     it("Should get member information", async function () {
//         let memberInfo = await membership.getMember(accounts[1], {from: accounts[6]});
//         assert(memberInfo = [1,7] , "Membership should be 7 and id 1");
//     });

//     it("Should count number of members", async function () {
//         let memCount = await membership.countMembers({from: accounts[4]});
//         assert(await memCount == 1, "Membership count should be 1");
//     });

//     it("Should get membershipType", async function () {
//         let oldMemberAcct = await membership.getMembershipType(accounts[0], {from: accounts[1]});
//         let newMemberAcct = await membership.getMembershipType(accounts[1], {from: accounts[1]});
//         assert(oldMemberAcct  == 0, "MembershipType should be zero");
//         assert(newMemberAcct == 7, "MembershipType should be 7");
//     });

//     it("Should allow owner to change contract owner", async function () {
//         await membership.setOwner(accounts[5], {from: accounts[3]});
//         assert(membership.owner = accounts[5], "owner should be account 5");
//         await membership.setOwner(accounts[3], {from: accounts[5]});
//     });

//     it("Should refund amount to user that did not pass KYC/AML", async function () {
//         balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
//         await membership.refund(accounts[1], 1000000000000000000, {from: accounts[3]});
//         var newbal1 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
//         assert(newbal1 > balance1, "balance1 should be less");

//     });

//     it("Should allow owner to withdraw funds to address specified", async function () {
//         balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[7]), 'ether').toFixed(0));
//         await membership.withdraw(accounts[7], 4000000000000000000, {from: accounts[3]});
//         var newbal2 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[7]), 'ether').toFixed(0)));
//         assert(newbal2 > balance2, "balance2 should be less");
//     });

//     it("Set Member id", async function () {
//         await membership.setMemberId(accounts[7], 2, {from: accounts[3]});
//         //console.log("memberId");
//         await membership.setMembershipType(accounts[7],1, {from: accounts[3]});
//         //console.log("membershipType");
//         let memberInfo = await membership.getMember(accounts[7], {from: accounts[3]});
//         //console.log("memberInfo",memberInfo );
//         assert(memberInfo = [2,1] , "Membership should be 1 and id 1");
//         //console.log("assert memberinfo");
//     });

//     it("request membership and refund", async function () {
//         await membership.setFee(5, {from: accounts[3]});
//         await membership.requestMembership({value: web3.toWei(5,'ether'), from: accounts[9]});
//         assert(await membership.getMembershipType(accounts[9]) ==1, "MembershipType should not be zero");
//         balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[9]), 'ether').toFixed(0));
//         //console.log(balance1);
//         let members = await membership.getMembers({from: accounts[3]});
//         //console.log(members);
//         await membership.refund(accounts[9], 5000000000000000000, {from: accounts[3]});
//         var newbal1 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[9]), 'ether').toFixed(0)));
//         //console.log(newbal1);
//         assert(newbal1 > balance1, "balance1 should be less");

//     });

//     it("add and remove member acct", async function () {
//         await membership.addMemberAcct(accounts[8], {from: accounts[3]});
//         //console.log("addmember");
//         await membership.addMemberAcct(accounts[9], {from: accounts[3]});
//         //console.log("addmember2");
//         await membership.addMemberAcct(accounts[7], {from: accounts[3]});
//         //console.log("addmember2");
//         let memCount = await membership.countMembers({from: accounts[3]});
//         //console.log("count", memCount);
//         let members = await membership.getMembers({from: accounts[3]});
//         //console.log(members);
//         await membership.removeMemberAcct(accounts[8], {from: accounts[3]});
//         //console.log("remove");
//         let memCount2 = await membership.countMembers({from: accounts[3]});
//         //console.log("count", memCount2);
//         let members2 = await membership.getMembers({from: accounts[3]});
//         //console.log(members2);
//         assert(await memCount2 == 2, "Membership count should be 3");
//         assert(await memCount == 3, "Membership count should be 4");
//  });



// })
