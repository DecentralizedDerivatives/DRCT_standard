

var twoweek = new Date(Date.now() + 12096e5) ;
console.log("twoweek:", twoweek);

//var currentTime = new Date();

var currentTime = new Date() ;
var _date = currentTime.setDate(currentTime.getDate()+1);
var d = (_date - (_date % 86400000))/1000;
console.log("_date",_date);
console.log("d", d);

var _nowUTC  = new Date(_date).toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log("_nowUTC", _nowUTC);


