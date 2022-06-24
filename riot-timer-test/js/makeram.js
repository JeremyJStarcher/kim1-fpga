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
array[0x00F1] = "00";

// Preset program counter
// array[0x00EF] = "00";
// array[0x00F0] = "02";


array[0x0000] = "AB";

/*
00EF = PCL
00F0 = PCH
00F1 = Status Register (P)
00F2 = Stack Pointer (SP)
00F3 = Accumulator (A)
00F4 = Y Index Register
00F5 = X Index Register
*/



// // Reset vectors
// array[0x17F9] = 0x00;     
// array[0x17FA] = 0x00
// array[0x17FB] = 0x1C;
// array[0x17FC] = 0x00
// array[0x17FD] = 0x1C;
// array[0x17FE] = 0x00
// array[0x17FF] = 0x1C;




// console.log(array.join(" "));
// console.log(longLine);

fs.writeFileSync('../../hdl/kim-1-ep2cs/ram.hex', array.join(" ") );
fs.writeFileSync('../../hdl/kim-1-dueprologic/src/ram.hex', array.join(" "));
 

function toBytes(l) {
    const a = Array.from(l);
    const o = [];

    for(let i = 0; i < a.length; i += 2) {
        const s = a[i] + a[i+1];
        o.push(s)
    }
    return o;
}


const ram128 = new Array(128).fill(0).map((k, i) => i.toString(16)).map(k => {
   return "00"; // ("0" + k).substr(-2)
}).map(k => k.toUpperCase());


/*
00F1 00.
17F9 00.     
17FA 00.1C. (7A)
17FC 00.1C.
17FE 00.1C.
*/

ram128[0x007A] = '00';
ram128[0x007B] = '1C';
ram128[0x007C] = '00';
ram128[0x007D] = '1C';
ram128[0x007E] = '00';
ram128[0x007F] = '1C';



fs.writeFileSync('../../hdl/kim-1-ep2cs/ram128.hex', ram128.join(" ") );
fs.writeFileSync('../../hdl/kim-1-dueprologic/src/ram128.hex', ram128.join(" "));

/*
                    00EF = PCL
                    00F0 = PCH
                    00F1 = Status Register (P)
                    00F2 = Stack Pointer (SP)
                    00F3 = Accumulator (A)
                    00F4 = Y Index Register
                    00F5 = X Index Register
                    */