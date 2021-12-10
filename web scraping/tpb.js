#!/usr/bin/node



// /home/london/node/scripts/web_scraping/pirate_bay/tpb.js:162
//                         .filter( e => e.type == 'tag' && e.name == 'b' )[0].children[0].data;
//                          ^
// 
// TypeError: Cannot read properties of undefined (reading 'filter')
//     at Request._callback (/home/london/node/scripts/web_scraping/pirate_bay/tpb.js:162:26)
//     at Request.self.callback (/usr/lib/node_modules/request/request.js:185:22)
//     at Request.emit (node:events:394:28)
//     at Request.<anonymous> (/usr/lib/node_modules/request/request.js:1154:10)
//     at Request.emit (node:events:394:28)
//     at IncomingMessage.<anonymous> (/usr/lib/node_modules/request/request.js:1076:12)
//     at Object.onceWrapper (node:events:513:28)
//     at IncomingMessage.emit (node:events:406:35)
//     at endReadableNT (node:internal/streams/readable:1343:12)
//     at processTicksAndRejections (node:internal/process/task_queues:83:21)
// london@archlinux:~






// take into account terminal width

// $ tpb guardian galaxy
//  0   Guardian of the Galaxy S02E01 Stayin Alive 1080p WEB-DL 6CH x265      0     1
//                                    by nayhtut  03-17 2017  237.77 MiB
// /home/london/node/scripts/web_scraping/pirate_bay/tpb.js:139
//                         .filter( e => e.type == 'tag' && e.name == 'b' )[0].children[0].data;
//                          ^
// 
// TypeError: Cannot read property 'filter' of undefined
//     at Request._callback (/home/london/node/scripts/web_scraping/pirate_bay/tpb.js:139:26)
//     at Request.self.callback (/usr/lib/node_modules/request/request.js:185:22)
//     at Request.emit (node:events:394:28)
//     at Request.<anonymous> (/usr/lib/node_modules/request/request.js:1154:10)
//     at Request.emit (node:events:394:28)
//     at IncomingMessage.<anonymous> (/usr/lib/node_modules/request/request.js:1076:12)
//     at Object.onceWrapper (node:events:513:28)
//     at IncomingMessage.emit (node:events:406:35)
//     at endReadableNT (node:internal/streams/readable:1331:12)
//     at processTicksAndRejections (node:internal/process/task_queues:83:21)
// london@archlinux:~
// $

// $ tpb ant man 720
// /home/london/node/scripts/web_scraping/pirate_bay/tpb.js:125
//     const current_page = table_rows[table_rows.length-1].children[0].children
//                                                          ^
// 
// TypeError: Cannot read property 'children' of undefined

// clipboad
// copy
// paste


const l = console.log;
const cheerio = require("cheerio");
const request = require("request");
const readline = require("readline-sync");
const child_process = require("child_process");



// TERMINAL COLORS
const [reset, underscore, red, green, yellow, blue, bright, magenta, cyan]
= ["\x1b[0m","\x1b[4m","\x1b[31m","\x1b[32m","\x1b[33m","\x1b[34m","\x1b[1m","\x1b[35m","\x1b[36m"];

const color = {
    index:    yellow,
    title:    bright + blue,
    seeds:    bright + green,
    leechers: bright + blue,
//     size:     underscore + green,
    size:     underscore + red,
    uploader:     green,
    date:     green,
};

// CONFIGURATIONS
const piratebay_url = "https://knaben.ru";
const useragent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36";


function arraysSameLength(...arrays) {
    let len = arrays[0].length;
    for(i=1; i < arrays.length; i++) {
        if (len != arrays[i].length) {
            return false;
        }
    }
    return true;
}

function zip(array_a, array_b) {
    return array_a.map( (_,i) => {
        if (typeof array_a[i] == "object") {    // array_a[i] is an array
            return array_a[i].concat(array_b[i])
        }
        else {
            return [array_a[i], array_b[i]]     // array_a[i] is a "scalar"
        }
    })
}

function transpose(...arrays) {
    if(! arraysSameLength(...arrays)) {
        return undefined;
    }
    return arrays.reduce(zip)
}

function copy_clipboard(string) {
    const xsel = child_process.spawn("xsel"); 
    xsel.stdin.write(string); 
    xsel.stdin.end()
}

function range(slice) {

    const seen = {};

    return slice.replaceAll(" ","").split(",").flatMap( e => {

        if (e.includes("-")) {

            var [min, max] = e.split("-");
            min = Number(min);
            max = Number(max);

            if (min < max) {
                return [...Array(max-min+1).keys()].map( e => e + min)
            }
            else if (min == max) {
                return min
            }
            else {
                throw `range malformed ${min}-${max}`;
            }
        }
        else {
            return Number(e)
        }
    }).filter( e => {
        if (! (e in seen)) {
            seen[e] = 1;
            return 1;
        }
    })
}


// https://knaben.net/s/?q=harry+potter+soundtrack&category=0&page=0&orderby=99
// https://knaben.ru/s/?q=avengers+2012&category=0&page=0&orderby=99
// https://knaben.eu/s/?q=avengers&page=0&orderby=99

let url;
if (global.process.argv.length <= 2) {
    const search = readline.question(green + "Pirate Search : " + reset);
    url = piratebay_url
        + "/s/?q="
        + search.split(/\s+/).join("+")
        + "&category=0&page=0&orderby=99";
    url = encodeURI(url);
}
else {
    url = piratebay_url
        + "/s/?q="
        + global.process.argv.slice(2).join(" ").split(/\s+/).join("+")
        + "&category=0&page=0&orderby=99";
    url = encodeURI(url);
}


request(url, {headers: { 'User-Agent': useragent }}, (err, res, body) => {
    if (err) { return l(`error ${err} while fetching search results page`); }
 
//     const fs = require("fs");
//     const file = fs.readFileSync(global.process.argv[2], "utf8");
//     const $ = cheerio.load(file);

    const $ = cheerio.load(body);

    const title = $("tbody > tr > td > div.detName > a.detLink")
        .map( (_,e) => e.children[0].data ).toArray();

    const magnet = $("tbody > tr > td > a")
        .map((_,e) => e.attribs.href  ).toArray().filter( e => e.match(/^magnet/));

    const peers = $('tbody > tr > td[align="right"]')
        .map( (_,e) => e.children[0].data ).toArray();

    const seeds    = peers.filter( (_,i) => i % 2 == 0 );
    const leechers = peers.filter( (_,i) => i % 2 == 1 );

    const info = $("tbody > tr > td > font.detDesc").map( (_,e) => e.children[0].data ).toArray();

    const date = info.map( e => e.match(/^Uploaded (.*?),/)[1] );
    const size = info.map( e => e.match(/ Size (.*?),/)[1] );

    const uploader = $("tbody > tr > td > font.detDesc").map( (_,e) => e.children[1].children[0].data).toArray();

    const torrents = transpose(title, magnet, seeds, leechers, date, size, uploader);

    torrents.forEach( (e, i) => {
        l(color["index"]      + ` ${i}`.padEnd(5, " ") + reset
        + color["title"]      + `${e[0]}`.substring(0,65).padEnd(65, " ")
        + color["seeds"]      + `${e[2]}`.padStart(6, " ") + reset
        + color["leechers"]   + `${e[3]}`.padStart(6, " ") + reset
        );

        l(
              (color["uploader"] + `by ${e[6]}` + reset 
            +  color["date"] + "  " + e[4] + reset
            + "  " + (color["size"]  + e[5] + reset).padStart(15, " ")).padStart(100, " ")
         );

    });

    const table_rows = $("tbody > tr ");

    // fails if only one page ??
//     const current_page = table_rows[table_rows.length-1].children[0].children
//                         .filter( e => e.type == 'tag' && e.name == 'b' )[0].children[0].data;
//         
//     const rest_of_pages = table_rows[table_rows.length-1].children[0].children
//         .filter( e => e.type == 'tag' && e.name == 'a' )
//         .filter( e => e.children[0].type == 'text' )
//         .map( e => { return { number: e.children[0].data, link: e.attribs.href } });
// 
//     const pages = rest_of_pages.concat({number: current_page}).sort( (a,b) => a.number - b.number );
   
//     l(pages);

// 
//     process.exit();
    const choices = readline.question(green + "\nTorrent : " + reset);

//     l(choice);
//     l(torrents[choice][1]);
//     copy_clipboard(torrents[choice][1]);

    const magnet_links = range(choices).map( e => torrents[e][1] ).join("\n");

    l(choices);
    l(range(choices));
    l(magnet_links);
    copy_clipboard(magnet_links);

});






