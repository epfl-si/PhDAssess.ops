const CryptoJS = require("crypto-js");

let pass;
let to_decrypt;
let bytes;

pass = '';
to_decrypt = process.argv[2];

console.log(to_decrypt)

bytes = CryptoJS.AES.decrypt(to_decrypt.substring(2), pass);
console.log('\n')
console.log(JSON.parse(bytes.toString(CryptoJS.enc.Utf8)))
