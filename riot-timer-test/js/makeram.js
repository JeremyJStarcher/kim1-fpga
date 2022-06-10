const fs = require('fs');
  
// Calling the readFileSync() method
// to read 'input.txt' file
const data = fs.readFileSync('../timertest.hex',
            {encoding:'utf8', flag:'r'});
 

const lines = data.split(/\r\n|\r|\n/);
lines.shift();
lines.pop();


const longLine = lines.filter(p => p[0] !== "/").join("");


const bytes = toBytes(longLine)

// Display the file data
//console.log(bytes);


const array = Array(0x03ff).fill('00')

bytes.forEach((b,i) => {
    array[0x0200 + i] = b;
});

// Turn off decimal mode
array[0x00F1] = 0x00;

// // Reset vectors
// array[0x17F9] = 0x00;     
// array[0x17FA] = 0x00
// array[0x17FB] = 0x1C;
// array[0x17FC] = 0x00
// array[0x17FD] = 0x1C;
// array[0x17FE] = 0x00
// array[0x17FF] = 0x1C;




 console.log(array.join(" "));
// console.log(longLine);


fs.writeFileSync('../../hdl/kim-1-ep2cs/ram.hex',
array.join(" ") );
 

function toBytes(l) {
    const a = Array.from(l);
    const o = [];

    for(let i = 0; i < a.length; i += 2) {
        const s = a[i] + a[i+1];
        o.push(s)
    }
    return o;
}