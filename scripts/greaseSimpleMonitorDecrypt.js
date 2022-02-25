// ==UserScript==
// @name         Simple monitor decryption
// @namespace    https//phd-assess
// @version      0.1
// @description  Encrypt and decrypt messages
// @author       epfl-devfsd
// @match        https://simple-monitor.128.178.222.83.nip.io/views/instances/*
// @require      https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js
// @grant        none
// ==/UserScript==

// CONFIG: Insert your password here.
const encryptionKey = "soupaSecret";
/////////////////////////////////////

const decryptNode = (text) => {
  const bytes = CryptoJS.AES.decrypt(text, encryptionKey)
  return JSON.parse(bytes.toString(CryptoJS.enc.Utf8))
}

$(document).ready(() => {
    const dataTables = document.getElementsByClassName('table');

    for (const table of dataTables) {
      for (const row of table.rows) {
        for (const cell of row.cells) {
          if (cell.innerText && cell.innerText.startsWith('"U2F')) {
            let innerText = cell.innerText.replace('"', '').replace('\"', '')
            try {
              cell.innerText = `(${decryptNode(innerText)}) ${cell.innerText}`
            } catch (e) {
              cell.innerText = `(undecryptable) ${cell.innerText}`
            }
          }
        }
      }
    }
})
